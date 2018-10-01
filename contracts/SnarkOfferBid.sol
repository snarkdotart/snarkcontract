pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./SnarkBaseLib.sol";
import "./SnarkCommonLib.sol";
import "./SnarkOfferBidLib.sol";


contract SnarkOfferBid is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkOfferBidLib for address;

    /*** STORAGE ***/

    address private _storage;

    /*** EVENTS ***/

    // New offer event
    event OfferAdded(address _offerOwner, uint256 _offerId, uint _tokenId);
    // Offer deleted event
    event OfferDeleted(uint256 _offerId);
    // New bid event
    event BidAdded(address indexed _bidder, uint256 _bidId, uint256 _value);
    // Canceled bid event
    event BidCanceled(uint256 _tokenId, uint256 _bidId);

    /// @dev Modifier that checks that an owner has a specific token
    /// @param _tokenId Token ID
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == _storage.getOwnerOfToken(_tokenId), "it's not a token owner");
        _;
    }

    /// @dev Modifier that allows only the owner of the offer
    /// @param _offerId Id of offer
    modifier onlyOfferOwner(uint256 _offerId) {
        require(msg.sender == _storage.getOwnerOfOffer(_offerId), "it's not an offer owner");
        _;
    }
    
    /// @dev Modifier that permits only the owner of the Bid 
    /// @param _bidId Bid ID
    modifier onlyBidOwner(uint256 _bidId) {
        require(msg.sender == _storage.getOwnerOfBid(_bidId), "it's not a bid owner");
        _;
    }

    constructor(address _storageAddress) public {
        _storage = _storageAddress;
    }

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    // /// @dev Function returns the offer count with a specific status 
    // /// @param _status Sale status
    // function getOffersCount(uint256 _status) public view returns (uint256) {        
    //     require(_status <= uint256(SaleStatus.Finished));
    //     return _storage.get_saleStatusToOffersMap_length(_status);
    // }
    /// @dev Function returns a count of offers which belong to a specific owner
    /// @param _owner Owner address
    function getOwnerOffersCount(address _owner) public view returns (uint256 offersCount) {
        return _storage.getTotalNumberOfOwnerOffers(_owner);
    }

    function getOwnerOfferByIndex(address _owner, uint256 _index) public view returns (uint256 offerId) {
        return _storage.getOfferIdOfOwner(_owner, _index);
    }

    /// @dev Function to create an offer for the secondary sale.
    /// @param _tokenId Token IDs included in the offer
    /// @param _price The price for all tokens included in the offer
    function addOffer(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        bool isStatusNone = true;
        // bool isSecondSale = true;
        isStatusNone = (isStatusNone && (_storage.getSaleTypeToToken(_tokenId) == uint256(SaleType.None)));
        // uint256 lastPrice = _storage.getTokenLastPrice(_tokenId);
        // isSecondSale = (isSecondSale && (lastPrice > 0));
        // require(isStatusNone && isSecondSale);
        require(isStatusNone, "the token should not be involved in sales");

        // Offer creation and return of the offer ID
        uint256 offerId = _storage.addOffer(msg.sender, _tokenId, _price);
        // move token to Snark
        _lockOffersToken(offerId, _tokenId);
        // Emit an event that returns token id and offer id as well
        emit OfferAdded(msg.sender, offerId, _tokenId);
    }

    /// @dev Delete offer. This is also done during the sale of the last token in the offer.  
    /// @param _offerId Offer ID
    function deleteOffer(uint256 _offerId) public onlyOfferOwner(_offerId) {
        // clear all data in the token
        uint256 tokenId = _storage.getTokenIdByOfferId(_offerId);
        _storage.deleteOffer(_offerId);
        // unlock token
        _unlockOffersToken(_offerId, tokenId);
        // emit event that the offer has been deleted
        emit OfferDeleted(_offerId);
    }

    /// @dev Function to set bid for an token
    /// @param _tokenId Token token ID
    function addBid(uint256 _tokenId) public payable {
        // it does not matter if the token is available for sale
        // it is possible to accept a bid unless
        // the token is part of an auction or a loan
        SaleType currentSaleType = SaleType(_storage.getSaleTypeToToken(_tokenId));
        require(
            currentSaleType == SaleType.Offer || 
            currentSaleType == SaleType.None, 
            "the token should either be in sale by offer or not involved in sales at all"
        );
        address currentOwner;
        uint256 offerId;
        uint256 price;
        if (currentSaleType == SaleType.Offer) {
            offerId = _storage.getOfferIdByTokenId(_tokenId);
            currentOwner = _storage.getOwnerOfOffer(offerId);
            price = _storage.getOfferPrice(offerId);
            // If an OFFER exists for an token, ANY collector can BID for the token at a price LOWER 
            // than the OFFER price.  If a BID is made at the OFFER price or HIGHER, than the platform should 
            // notify the bidder that they must BUY the token at an OFFER price or revise the BID to something 
            // lower than the OFFER price.
            require(msg.value < price, "bid amount have to be less than a price of offer");
        } else {
            currentOwner = _storage.getOwnerOfToken(_tokenId);
        }
        require(
            currentOwner != msg.sender, 
            "The token token cannot belong to the bidder"
        );
        uint256 bidId = _storage.addBid(msg.sender, _tokenId, msg.value);
        // adding an amount of this bid to a contract balance
        _storage.addPendingWithdrawals(_storage, msg.value);
        // emit the bid creation event
        emit BidAdded(msg.sender, bidId, msg.value);
    }

    /// @dev Function to accept bid
    /// @param _bidId Id of bid
    function acceptBid(uint256 _bidId) public {
        // To persuade if this function called a token owner
        uint256 tokenId = _storage.getTokenIdByBidId(_bidId);
        uint256 price = _storage.getBidPrice(_bidId);
        SaleType saleType = SaleType(_storage.getSaleTypeToToken(tokenId));
        require(
            saleType == SaleType.Offer || 
            saleType == SaleType.None,
            "it's forbidden to accept the Bid when it has a Loan Status"
        );
        address tokenOwner;
        address mediator;
        uint256 offerId;
        if (saleType == SaleType.Offer) {
            // in this case the token is blocked and we can get a real address via an offer
            offerId = _storage.getOfferIdByTokenId(tokenId);
            tokenOwner = _storage.getOwnerOfOffer(offerId);
            mediator = _storage.getOwnerOfToken(tokenId);
        } else {
            tokenOwner = _storage.getOwnerOfToken(tokenId);
            mediator = tokenOwner;
        }

        require(msg.sender == tokenOwner, "Only token's owner can accept the bid");

        address bidOwner = _storage.getOwnerOfBid(_bidId);
        _storage.subPendingWithdrawals(_storage, price);
        uint256 profit;
        (profit, price) = _storage.calculatePlatformProfitShare(price);
        _storage.takePlatformProfitShare(price);

        _storage.buy(tokenId, price, tokenOwner, bidOwner, mediator);
        _storage.deleteBid(_bidId);

        // deleting all bids relating with the token
        // but we have to take back bid amounts to their owners as well
        _takeBackBidAmountsAndDeleteAllTokenBids(tokenId);
    }
    
    /// @dev Function to allow the bidder to cancel their own bid
    /// @param _bidId Bid ID
    function cancelBid(uint256 _bidId) public onlyBidOwner(_bidId) {
        address bidder = _storage.getOwnerOfBid(_bidId);
        uint256 tokenId = _storage.getTokenIdByBidId(_bidId);
        uint256 price = _storage.getBidPrice(_bidId);
        _storage.subPendingWithdrawals(_storage, price);
        _storage.deleteBid(_bidId);
        bidder.transfer(price);
        emit BidCanceled(tokenId, _bidId);
    }

    /// @dev Accepting the artist's offer
    /// @param _offerId Offer ID
    function buyOffer(uint256 _offerId) public payable {
        uint256 tokenId = _storage.getTokenIdByOfferId(_offerId);
        uint256 price = _storage.getOfferPrice(_offerId);
        uint256 saleStatus = _storage.getSaleStatusForOffer(_offerId);

        require(saleStatus == uint256(SaleStatus.Active), "Offer status must by an active");
        require(msg.value >= price, "Amount of money should be not less then the offer price");

        address tokenOwner = _storage.getOwnerOfOffer(_offerId);
        address mediator = _storage.getOwnerOfToken(tokenId);

        require(msg.sender != tokenOwner, "Owner of token can't buy his token");

        _storage.takePlatformProfitShare(price);
        _storage.buy(tokenId, price, tokenOwner, msg.sender, mediator);
        _storage.setSaleStatusForOffer(_offerId, uint256(SaleStatus.Finished));

        // If there are bids for the offer than we takes back an amount to their owners. 
        // After that we can delete bids.
        _takeBackBidAmountsAndDeleteAllTokenBids(tokenId);
    }

    function getTotalNumberOfBids() public view returns (uint256) {
        return _storage.getTotalNumberOfBids();
    }

    function getNumberOfTokenBids(uint256 _tokenId) public view returns (uint256) {
        return _storage.getNumberOfTokenBids(_tokenId);
    }

    function getNumberBidsOfOwner(address _bidOwner) public view returns (uint256) {
        return _storage.getNumberBidsOfOwner(_bidOwner);
    }

    function _takeBackBidAmountsAndDeleteAllTokenBids(uint256 _tokenId) internal {
        uint256 bidsCount = _storage.getNumberOfTokenBids(_tokenId);
        uint256 bidId;
        address bidder;
        uint256 bidPrice;
        for (uint256 i = 0; i < bidsCount; i++) {
            bidId = _storage.getBidIdForToken(_tokenId, 0);
            bidder = _storage.getOwnerOfBid(bidId);
            bidPrice = _storage.getBidPrice(bidId);
            // Moving these amount from contract's balance to the bid's one
            _storage.subPendingWithdrawals(_storage, bidPrice);
            _storage.addPendingWithdrawals(bidder, bidPrice);
            // Delete the bid
            _storage.deleteBid(bidId);
            // _deleteBid(bidId, _tokenId, bidder);
        }
    }

    /// @dev Lock Token
    /// @param _offerId Offer Id
    /// @param _tokenId Token Id
    function _lockOffersToken(uint256 _offerId, uint256 _tokenId) private {
        address realOwner = _storage.getOwnerOfOffer(_offerId);
        _storage.transferToken(_tokenId, realOwner, owner);
    }

    /// @dev Unlock Token
    /// @param _offerId Offer Id
    /// @param _tokenId Token Id
    function _unlockOffersToken(uint256 _offerId, uint256 _tokenId) private {
        address realOwner = _storage.getOwnerOfOffer(_offerId);
        _storage.transferToken(_tokenId, owner, realOwner);
    }

}
