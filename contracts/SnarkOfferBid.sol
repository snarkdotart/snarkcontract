pragma solidity ^0.4.24;

import "./openzeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkOfferBidLib.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./openzeppelin/SafeMath.sol";


contract SnarkOfferBid is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkOfferBidLib for address;
    using SnarkLoanLib for address;
    using SafeMath for uint256;

    /*** STORAGE ***/

    address private _storage;

    /*** EVENTS ***/

    event OfferAdded(address _offerOwner, uint256 _offerId, uint _tokenId);
    event OfferDeleted(uint256 _offerId);
    event BidAdded(address indexed _bidder, uint256 _bidId, uint256 _value);
    event BidAccepted(uint256 _bidId, uint256 _bidPrice);
    event BidCanceled(uint256 _tokenId, uint256 _bidId);

    modifier restrictedAccess() {
        if (_storage.isRestrictedAccess()) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }

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

    modifier correctOffer(uint256 _offerId) {
        require(_offerId > 0 && _offerId <= getTotalNumberOfOffers(), "Offer id is wrong");
        _;
    }

    modifier correctBid(uint256 _bidId) {
        require(_bidId > 0 && _bidId <= getTotalNumberOfBids(), "Bid id is wrong");
        _;
    }

    constructor(address _storageAddress) public {
        _storage = _storageAddress;
    }

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    /// @dev Function returns a count of offers which belong to a specific owner
    /// @param _owner Owner address
    function getOwnerOffersCount(address _owner) public view returns (uint256 offersCount) {
        return _storage.getTotalNumberOfOwnerOffers(_owner);
    }

    function getOwnerOfferByIndex(address _owner, uint256 _index) public view returns (uint256 offerId) {
        return _storage.getOfferOfOwnerByIndex(_owner, _index);
    }

    /// @dev Function to create an offer for the secondary sale.
    /// @param _tokenId Token IDs included in the offer
    /// @param _price The price for all tokens included in the offer
    function addOffer(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        require(
            _storage.getSaleTypeToToken(_tokenId) == uint256(SaleType.None),
            "Token should not be involved in sales"
        );

        uint256 bidsCount = _storage.getNumberBidsOfToken(_tokenId);
        if (bidsCount > 0) {
            require(_storage.getMaxBidPriceForToken(_tokenId) < _price, 
                "Offer amount must be higher than the bid price");
        }
        // delete all loans if they exist
        _storage.cancelTokenInLoan(_tokenId);
        // Offer creation and return of the offer ID
        uint256 offerId = _storage.addOffer(msg.sender, _tokenId, _price);
        // Emit an event that returns token id and offer id as well
        emit OfferAdded(msg.sender, offerId, _tokenId);
    }

    /// @dev cancel offer. This is also done during the sale of the last token in the offer.  
    /// @param _offerId Offer ID
    function cancelOffer(uint256 _offerId) public correctOffer(_offerId) onlyOfferOwner(_offerId) {
        require(_storage.getSaleStatusForOffer(_offerId) != uint256(SaleStatus.Finished), 
            "It's not impossible delete when the offer status is 'finished'");
        // clear all data in the token
        uint256 tokenId = _storage.getTokenByOffer(_offerId);
        // deleting all bids related to the token
        // return bid amounts to bidders
        _takeBackBidAmountsAndDeleteAllTokenBids(tokenId);

        _storage.cancelOffer(_offerId);
        // emit event that the offer has been deleted        
        emit OfferDeleted(_offerId);
    }

    /// @dev Function to set bid for an token
    /// @param _tokenId Token token ID
    function addBid(uint256 _tokenId) public payable {
        // token has to be exist
        require(_tokenId > 0 && _tokenId <= _storage.getTotalNumberOfTokens());
        // it does not matter if the token is available for sale
        // it is possible to accept a bid unless
        // the token is part of a loan
        SaleType currentSaleType = SaleType(_storage.getSaleTypeToToken(_tokenId));
        require(
            currentSaleType == SaleType.Offer || 
            currentSaleType == SaleType.None, 
            "Bids are not allowed while the token is in Loan status"
        );
        address currentOwner;
        uint256 offerId;
        uint256 price;
        if (currentSaleType == SaleType.Offer) {
            offerId = _storage.getOfferByToken(_tokenId);
            currentOwner = _storage.getOwnerOfOffer(offerId);
            price = _storage.getOfferPrice(offerId);
            // If an OFFER exists for an token, ANY collector can BID for the token at a price LOWER 
            // than the OFFER price.  If a BID is made at the OFFER price or HIGHER, than the platform should 
            // notify the bidder that they must BUY the token at an OFFER price or revise the BID to something 
            // lower than the OFFER price.
            require(msg.value < price, "Bid amount must be less than the offer price");
        } else {
            currentOwner = _storage.getOwnerOfToken(_tokenId);
        }
        require(
            currentOwner != msg.sender, 
            "The token cannot belongs to the bidder"
        );

        uint256 maxBidPrice = _storage.getMaxBidPriceForToken(_tokenId);
        require(msg.value > maxBidPrice, "Price of new bid has to be bigger than previous one");

        uint256 bidId = _storage.addBid(msg.sender, _tokenId, msg.value);
        // adding an amount of this bid to a contract balance
        _storage.addPendingWithdrawals(_storage, msg.value);
        // emit the bid creation event
        emit BidAdded(msg.sender, bidId, msg.value);
    }

    /// @dev Function to accept bid
    /// @param _bidId Id of bid
    function acceptBid(uint256 _bidId) public correctBid(_bidId) {
        require(_storage.getBidSaleStatus(_bidId) == uint256(SaleStatus.Active), "Bid is already finished");
        // Check if the function is called by the token owner
        uint256 tokenId = _storage.getTokenByBid(_bidId);
        uint256 price = _storage.getBidPrice(_bidId);
        uint256 maxBidPrice = _storage.getMaxBidPriceForToken(tokenId);
        require(price == maxBidPrice, "User has to accept the highest bid only");

        SaleType saleType = SaleType(_storage.getSaleTypeToToken(tokenId));
        require(
            saleType == SaleType.Offer || 
            saleType == SaleType.None,
            "Bids are not allowed while the token is in Loan status"
        );
        address tokenOwner = _storage.getOwnerOfToken(tokenId);
        require(msg.sender == tokenOwner, "Only owner can accept a bid for their token");

        _storage.cancelTokenInLoan(tokenId);

        address bidOwner = _storage.getOwnerOfBid(_bidId);
        _storage.subPendingWithdrawals(_storage, price);
        uint256 profit;
        (profit, price) = _storage.calculatePlatformProfitShare(price);
        _storage.takePlatformProfitShare(profit);

        _storage.buy(tokenId, price, tokenOwner, bidOwner);
        _storage.deleteBid(_bidId);

        // deleting all bids related to the token
        _takeBackBidAmountsAndDeleteAllTokenBids(tokenId);

        // check if there is an offer for the token and delete it
        uint256 offerId = _storage.getOfferByToken(tokenId);
        if (offerId > 0 && 
            offerId <= _storage.getTotalNumberOfOffers() &&
            tokenOwner == _storage.getOwnerOfOffer(offerId)) {
            _storage.cancelOffer(offerId);
        }
    }
    
    // У пользователя будет 2 списка - активных и пассивыных
    /// @dev Function to allow the bidder to cancel their own bid
    /// @param _bidId Bid ID
    function cancelBid(uint256 _bidId) public correctBid(_bidId) onlyBidOwner(_bidId) {
        require(_storage.getBidSaleStatus(_bidId) == uint256(SaleStatus.Active), "Bid is already finished");
        address bidder = _storage.getOwnerOfBid(_bidId);
        uint256 tokenId = _storage.getTokenByBid(_bidId);
        uint256 price = _storage.getBidPrice(_bidId);
        _storage.subPendingWithdrawals(_storage, price);
        _storage.deleteBid(_bidId);
        bidder.transfer(price);
        emit BidCanceled(tokenId, _bidId);
    }

    /// @dev Accept the artist's offer
    /// @param _offerId Offer ID
    function buyOffer(uint256 _offerId) public payable {
        uint256 tokenId = _storage.getTokenByOffer(_offerId);
        uint256 price = _storage.getOfferPrice(_offerId);
        uint256 saleStatus = _storage.getSaleStatusForOffer(_offerId);

        require(saleStatus == uint256(SaleStatus.Active), "Offer status must be active");
        require(msg.value >= price, "Amount should not be less than the offer price");
        
        uint256 refunds = msg.value.sub(price);
        address tokenOwner = _storage.getOwnerOfToken(tokenId);

        require(msg.sender != tokenOwner, "Token owner can't buy their own token");

        uint256 profit;
        (profit, price) = _storage.calculatePlatformProfitShare(price);
        _storage.takePlatformProfitShare(profit);
        _storage.buy(tokenId, price, tokenOwner, msg.sender);
        if (refunds > 0) msg.sender.transfer(refunds);
        
        // Outstanding bids are returned to bidders
        // And then bids are deleted
        _takeBackBidAmountsAndDeleteAllTokenBids(tokenId);

        // check if there is an offer for the token and delete it
        _storage.cancelOffer(_offerId);
    }

    function getSaleStatusForOffer(uint256 _offerId) public view returns (uint256) {
        return _storage.getSaleStatusForOffer(_offerId);
    }

    function getTotalNumberOfOffers() public view returns (uint256) {
        return _storage.getTotalNumberOfOffers();
    }

    function getTokenByOffer(uint256 _offerId) public view returns (uint256) {
        return _storage.getTokenByOffer(_offerId);
    }

    function getOfferByToken(uint256 _tokenId) public view returns (uint256) {
        return _storage.getOfferByToken(_tokenId);
    }

    function getOfferDetail(uint256 _offerId) public view returns (
        uint256 offerId,
        uint256 offerPrice,
        uint256 offerStatus,
        uint256 tokenId,
        address tokenOwner)
    {
        offerId = _offerId;
        offerPrice = _storage.getOfferPrice(_offerId);
        offerStatus = _storage.getSaleStatusForOffer(_offerId);
        tokenId = _storage.getTokenByOffer(_offerId);
        tokenOwner = _storage.getOwnerOfToken(tokenId);
    }

    function getListOfOffersForOwner(address _offerOwner) public view returns (uint256[]) {
        return _storage.getListOfOffersForOwner(_offerOwner);
    }

    function getTotalNumberOfBids() public view returns (uint256) {
        return _storage.getTotalNumberOfBids();
    }

    function getNumberBidsOfToken(uint256 _tokenId) public view returns (uint256) {
        return _storage.getNumberBidsOfToken(_tokenId);
    }

    function getNumberBidsOfOwner(address _bidOwner) public view returns (uint256) {
        return _storage.getNumberBidsOfOwner(_bidOwner);
    }

    function getBidDetail(uint256 _bidId) public view returns (
        uint256 bidId, 
        address bidOwner, 
        uint256 bidPrice,
        uint256 bidStatus,
        uint256 tokenId) 
    {
        bidId = _bidId;
        bidOwner = _storage.getOwnerOfBid(_bidId);
        bidPrice = _storage.getBidPrice(_bidId);
        bidStatus = _storage.getBidSaleStatus(_bidId);
        tokenId = _storage.getTokenByBid(_bidId);
    }

    function getBidIdMaxPrice(uint256 _tokenId) public view returns (uint256 bidId, uint256 bidPrice) {
        bidId = _storage.getMaxBidForToken(_tokenId);
        bidPrice = _storage.getMaxBidPriceForToken(_tokenId);
    }

    function getListOfBidsForToken(uint256 _tokenId) public view returns (uint256[]) {
        return _storage.getListOfBidsForToken(_tokenId);
    }

    function getListOfBidsForOwner(address _bidOwner) public view returns (uint256[]) {
        return _storage.getListOfBidsForOwner(_bidOwner);
    }

    function _takeBackBidAmountsAndDeleteAllTokenBids(uint256 _tokenId) internal {
        uint256 bidsCount = _storage.getNumberBidsOfToken(_tokenId);
        uint256 bidId;
        address bidder;
        uint256 bidPrice;
        for (uint256 i = 0; i < bidsCount; i++) {
            bidId = _storage.getBidOfTokenByIndex(_tokenId, 0);
            bidder = _storage.getOwnerOfBid(bidId);
            bidPrice = _storage.getBidPrice(bidId);
            // Move bid amount from contract to the bidder
            _storage.subPendingWithdrawals(_storage, bidPrice);
            _storage.addPendingWithdrawals(bidder, bidPrice);
            // Delete the bid
            _storage.deleteBid(bidId);
        }
    }

}
