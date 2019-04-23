pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkOfferBidLib.sol";
import "./snarklibs/SnarkLoanLib.sol";


contract SnarkBid is Ownable, SnarkDefinitions {

    using SnarkCommonLib for address;
    using SnarkOfferBidLib for address;
    using SnarkLoanLib for address;

    /*** STORAGE ***/

    address private _storage;
    address private _erc721;

    /*** EVENTS ***/

    event BidAdded(address indexed _bidder, uint256 _bidId, uint256 _value);
    event BidAccepted(uint256 _bidId, uint256 _bidPrice);
    event BidCanceled(uint256 _tokenId, uint256 _bidId);

    modifier restrictedAccess() {
        if (SnarkBaseLib.isRestrictedAccess(_storage)) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }

    /// @dev Modifier that checks that an owner has a specific token
    /// @param _tokenId Token ID
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(
            msg.sender == SnarkBaseLib.getOwnerOfToken(_storage, _tokenId), 
            "it's not a token owner"
        );
        _;
    }

    /// @dev Modifier that permits only the owner of the Bid 
    /// @param _bidId Bid ID
    modifier onlyBidOwner(uint256 _bidId) {
        require(
            msg.sender == SnarkOfferBidLib.getOwnerOfBid(_storage, _bidId), 
            "it's not a bid owner"
        );
        _;
    }

    modifier correctBid(uint256 _bidId) {
        require(_bidId > 0 && _bidId <= getTotalNumberOfBids(), "Bid id is wrong");
        _;
    }

    /// @dev Constructor of contract
    /// @param storageAddress Address of a storage contract
    /// @param erc721Address Address of a ERC721 contract
    constructor(address storageAddress, address erc721Address) public {
        _storage = storageAddress;
        _erc721 = erc721Address;
    }

    /// @notice Will receive any eth sent to the contract
    function() external payable {} // solhint-disable-line

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    /// @dev Function to set bid for an token
    /// @param _tokenId Token token ID
    function addBid(uint256 _tokenId) public payable {
        require(_tokenId > 0 && _tokenId <= SnarkBaseLib.getTotalNumberOfTokens(_storage));
        uint256 amountOfBids = SnarkOfferBidLib.getNumberBidsOfToken(_storage, _tokenId);
        require(amountOfBids < 10, "Token can't have more than 10 bids");
        require(
            SnarkOfferBidLib.getBidForTokenAndBidOwner(_storage, msg.sender, _tokenId) == 0, 
            "You already have a bid for this token. Please cancel it before add a new one."
        );
        // it does not matter if the token is available for sale
        // it is possible to accept a bid unless
        // the token is part of a loan
        SaleType currentSaleType = SaleType(SnarkBaseLib.getSaleTypeToToken(_storage, _tokenId));
        require(
            currentSaleType == SaleType.Offer || 
            currentSaleType == SaleType.None, 
            "Bids are not allowed while the token is in Loan status"
        );
        address currentOwner;
        uint256 offerId;
        uint256 price;
        if (currentSaleType == SaleType.Offer) {
            offerId = SnarkOfferBidLib.getOfferByToken(_storage, _tokenId);
            currentOwner = SnarkOfferBidLib.getOwnerOfOffer(_storage, offerId);
            price = SnarkOfferBidLib.getOfferPrice(_storage, offerId);
            require(msg.value < price && msg.value > 0, 
                "Bid amount must be less than the offer price but bigger than zero");
        } else {
            currentOwner = SnarkBaseLib.getOwnerOfToken(_storage, _tokenId);
        }
        require(
            currentOwner != msg.sender, 
            "The token cannot belongs to the bidder"
        );

        uint256 maxBidPrice = SnarkOfferBidLib.getMaxBidPriceForToken(_storage, _tokenId);
        require(msg.value > maxBidPrice, "Price of new bid has to be bigger than previous one");
        
        address(uint160(_storage)).transfer(msg.value);
        
        uint256 bidId = SnarkOfferBidLib.addBid(_storage, msg.sender, _tokenId, msg.value);
        // adding an amount of this bid to a contract balance
        SnarkBaseLib.addPendingWithdrawals(_storage, _storage, msg.value);
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

        SaleType saleType = SaleType(SnarkBaseLib.getSaleTypeToToken(_storage, tokenId));
        require(
            saleType == SaleType.Offer || 
            saleType == SaleType.None,
            "Bids are not allowed while the token is in Loan status"
        );
        address tokenOwner = SnarkBaseLib.getOwnerOfToken(_storage, tokenId);
        require(msg.sender == tokenOwner, "Only owner can accept a bid for their token");

        // SnarkLoanLib.cancelTokenFromAllLoans(_storage, tokenId);

        address bidOwner = SnarkOfferBidLib.getOwnerOfBid(_storage, _bidId);
        SnarkBaseLib.subPendingWithdrawals(_storage, _storage, price);
        SnarkCommonLib.buy(_storage, tokenId, price, tokenOwner, bidOwner);
        SnarkERC721(address(uint160(_erc721))).echoTransfer(tokenOwner, bidOwner, tokenId);
        SnarkOfferBidLib.deleteBid(_storage, _bidId);

        // deleting all bids related to the token
        _takeBackBidAmountsAndDeleteAllTokenBids(tokenId);

        // check if there is an offer for the token and delete it
        uint256 offerId = SnarkOfferBidLib.getOfferByToken(_storage, tokenId);
        if (offerId > 0 && 
            offerId <= SnarkOfferBidLib.getTotalNumberOfOffers(_storage) &&
            tokenOwner == SnarkOfferBidLib.getOwnerOfOffer(_storage, offerId)) {
            SnarkOfferBidLib.cancelOffer(_storage, offerId);
        }
    }
    
    // User will have 2 lists - active and passive
    /// @dev Function to allow the bidder to cancel their own bid
    /// @param _bidId Bid ID
    function cancelBid(uint256 _bidId) public correctBid(_bidId) onlyBidOwner(_bidId) {
        require(
            SnarkOfferBidLib.getBidSaleStatus(_storage, _bidId) == uint256(SaleStatus.Active), 
            "Bid is already finished"
        );
        address bidder = SnarkOfferBidLib.getOwnerOfBid(_storage, _bidId);
        uint256 tokenId = SnarkOfferBidLib.getTokenByBid(_storage, _bidId);
        uint256 price = SnarkOfferBidLib.getBidPrice(_storage, _bidId);
        SnarkBaseLib.subPendingWithdrawals(_storage, _storage, price);
        SnarkOfferBidLib.deleteBid(_storage, _bidId);
        if (SnarkOfferBidLib.getMaxBidForToken(_storage, tokenId) == _bidId) {
            SnarkOfferBidLib.updateMaxBidPriceForToken(_storage, tokenId);
        }
        SnarkStorage(address(uint160(_storage))).transferFunds(address(uint160(bidder)), price);
        emit BidCanceled(tokenId, _bidId);
    }

    function getTotalNumberOfBids() public view returns (uint256) {
        return SnarkOfferBidLib.getTotalNumberOfBids(_storage);
    }

    function getNumberBidsOfToken(uint256 _tokenId) public view returns (uint256) {
        return SnarkOfferBidLib.getNumberBidsOfToken(_storage, _tokenId);
    }

    function getNumberBidsOfOwner(address _bidOwner) public view returns (uint256) {
        return SnarkOfferBidLib.getNumberBidsOfOwner(_storage, _bidOwner);
    }

    function getBidOfOwnerForToken(uint256 _tokenId) public view returns (uint256) {
        uint256 bidId = 0;
        uint256[] memory bidsList = getListOfBidsForOwner(msg.sender);
        for (uint256 i = 0; i < bidsList.length; i++) {
            if (SnarkOfferBidLib.getTokenByBid(_storage, bidsList[i]) == _tokenId) {
                bidId = bidsList[i];
                break;
            }
        }
        return bidId;
    }

    function getBidDetail(uint256 _bidId) public view returns (
        uint256 bidId, 
        address bidOwner, 
        uint256 bidPrice,
        uint256 bidStatus,
        uint256 tokenId) 
    {
        bidId = _bidId;
        bidOwner = SnarkOfferBidLib.getOwnerOfBid(_storage, _bidId);
        bidPrice = SnarkOfferBidLib.getBidPrice(_storage, _bidId);
        bidStatus = SnarkOfferBidLib.getBidSaleStatus(_storage, _bidId);
        tokenId = SnarkOfferBidLib.getTokenByBid(_storage, _bidId);
    }

    function getBidIdMaxPrice(uint256 _tokenId) public view returns (uint256 bidId, uint256 bidPrice) {
        bidId = SnarkOfferBidLib.getMaxBidForToken(_storage, _tokenId);
        bidPrice = SnarkOfferBidLib.getMaxBidPriceForToken(_storage, _tokenId);
    }

    function getListOfBidsForToken(uint256 _tokenId) public view returns (uint256[] memory) {
        return SnarkOfferBidLib.getListOfBidsForToken(_storage, _tokenId);
    }

    function getListOfBidsForOwner(address _bidOwner) public view returns (uint256[] memory) {
        return SnarkOfferBidLib.getListOfBidsForOwner(_storage, _bidOwner);
    }

    function _takeBackBidAmountsAndDeleteAllTokenBids(uint256 _tokenId) internal {
        uint256[] memory bidsList = _storage.getListOfBidsForToken(_tokenId);
        address bidder;
        uint256 bidPrice;
        for (uint256 i = 0; i < bidsList.length; i++) {
            bidder = SnarkOfferBidLib.getOwnerOfBid(_storage, bidsList[i]);
            bidPrice = SnarkOfferBidLib.getBidPrice(_storage, bidsList[i]);
            // Move bid amount from contract to the bidder
            SnarkBaseLib.subPendingWithdrawals(_storage, _storage, bidPrice);
            // _storage.addPendingWithdrawals(bidder, bidPrice);
            SnarkStorage(address(uint160(_storage))).transferFunds(address(uint160(bidder)), bidPrice);
            // Delete the bid
            SnarkOfferBidLib.deleteBid(_storage, bidsList[i]);
        }
        // there aren't any max bid for the token now
        SnarkOfferBidLib.setMaxBidPriceForToken(_storage, _tokenId, 0);
        SnarkOfferBidLib.setMaxBidForToken(_storage, _tokenId, 0);
    }

}
