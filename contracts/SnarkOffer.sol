pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkOfferBidLib.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./openzeppelin/SafeMath.sol";


contract SnarkOffer is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkOfferBidLib for address;
    using SnarkLoanLib for address;
    using SafeMath for uint256;

    /*** STORAGE ***/

    address private _storage;
    address private _erc721;

    /*** EVENTS ***/

    event OfferAdded(address indexed _offerOwner, uint256 _offerId, uint _tokenId);
    event OfferDeleted(uint256 _offerId);

    modifier restrictedAccess() {
        if (SnarkBaseLib.isRestrictedAccess(address(uint160(_storage)))) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }

    /// @dev Modifier that checks that an owner has a specific token
    /// @param _tokenId Token ID
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(
            msg.sender == SnarkBaseLib.getOwnerOfToken(address(uint160(_storage)), _tokenId), 
            "it's not a token owner"
        );
        _;
    }

    /// @dev Modifier that allows only the owner of the offer
    /// @param _offerId Id of offer
    modifier onlyOfferOwner(uint256 _offerId) {
        require(
            msg.sender == SnarkOfferBidLib.getOwnerOfOffer(address(uint160(_storage)), _offerId), 
            "it's not an offer owner"
        );
        _;
    }
    
    modifier correctOffer(uint256 _offerId) {
        require(_offerId > 0 && _offerId <= getTotalNumberOfOffers(), "Offer id is wrong");
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

    /// @dev Function returns a count of offers which belong to a specific owner
    /// @param _owner Owner address
    function getOwnerOffersCount(address _owner) public view returns (uint256 offersCount) {
        return SnarkOfferBidLib.getTotalNumberOfOwnerOffers(address(uint160(_storage)), _owner);
    }

    function getOwnerOfferByIndex(address _owner, uint256 _index) public view returns (uint256 offerId) {
        return SnarkOfferBidLib.getOfferOfOwnerByIndex(address(uint160(_storage)), _owner, _index);
    }

    /// @dev Function to create an offer for the secondary sale.
    /// @param _tokenId Token IDs included in the offer
    /// @param _price The price for all tokens included in the offer
    function addOffer(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        require(_price > 0, "Price has to be more than zero");
        require(
            SnarkBaseLib.getSaleTypeToToken(address(uint160(_storage)), _tokenId) == uint256(SaleType.None),
            "Token should not be involved in sales"
        );

        uint256 bidsCount = SnarkOfferBidLib.getNumberBidsOfToken(address(uint160(_storage)), _tokenId);
        if (bidsCount > 0) {
            require(
                SnarkOfferBidLib.getMaxBidPriceForToken(address(uint160(_storage)), _tokenId) < _price, 
                "Offer amount must be higher than the bid price");
        }
        // delete all loans if they exist
        SnarkLoanLib.cancelTokenFromAllLoans(address(uint160(_storage)), _tokenId);
        // Offer creation and return of the offer ID
        uint256 offerId = SnarkOfferBidLib.addOffer(address(uint160(_storage)), msg.sender, _tokenId, _price);
        // Emit an event that returns token id and offer id as well
        emit OfferAdded(msg.sender, offerId, _tokenId);
    }

    /// @dev cancel offer. This is also done during the sale of the last token in the offer. 
    /// All bids we need to leave.
    /// @param _offerId Offer ID
    function cancelOffer(uint256 _offerId) public correctOffer(_offerId) onlyOfferOwner(_offerId) {
        require(
            SnarkOfferBidLib.getSaleStatusForOffer(address(uint160(_storage)), _offerId) == uint256(SaleStatus.Active),
            "It's not impossible delete when the offer status is 'finished'");
        SnarkOfferBidLib.cancelOffer(address(uint160(_storage)), _offerId);
        // emit event that the offer has been deleted        
        emit OfferDeleted(_offerId);
    }

    /// @dev Accept the artist's offer
    /// @param _offerIdArray Array of Offers ID
    function buyOffer(uint256[] memory _offerIdArray) public payable {
        uint256 sumPrice;
        for (uint256 i = 0; i < _offerIdArray.length; i++) { 
            sumPrice += SnarkOfferBidLib.getOfferPrice(address(uint160(_storage)), _offerIdArray[i]); 
            uint256 tokenId = SnarkOfferBidLib.getTokenByOffer(address(uint160(_storage)), _offerIdArray[i]);
            address tokenOwner = SnarkBaseLib.getOwnerOfToken(address(uint160(_storage)), tokenId);
            uint256 saleStatus = SnarkOfferBidLib.getSaleStatusForOffer(address(uint160(_storage)), _offerIdArray[i]);
            require(msg.sender != tokenOwner, "Token owner can't buy their own token");
            require(saleStatus == uint256(SaleStatus.Active), "Offer status must be active");
        }
        require(msg.value >= sumPrice, "Payment doesn't match summary price of all offers");
        
        uint256 refunds = msg.value.sub(sumPrice);
        address(uint160(_storage)).transfer(msg.value);

        for (uint256 i = 0; i < _offerIdArray.length; i++) {
            uint256 tokenId = SnarkOfferBidLib.getTokenByOffer(address(uint160(_storage)), _offerIdArray[i]);
            address tokenOwner = SnarkBaseLib.getOwnerOfToken(address(uint160(_storage)), tokenId);
            uint256 price = _storage.getOfferPrice(_offerIdArray[i]);
            SnarkCommonLib.buy(address(uint160(_storage)), tokenId, price, tokenOwner, msg.sender);
            SnarkERC721(address(uint160(_erc721))).echoTransfer(tokenOwner, msg.sender, tokenId);
            // delete own's bid for the token if it exists
            uint256 bidId = SnarkOfferBidLib.getBidForTokenAndBidOwner(address(uint160(_storage)), msg.sender, tokenId);
            if (bidId > 0) {
                SnarkOfferBidLib.deleteBid(address(uint160(_storage)), bidId);
                if (SnarkOfferBidLib.getMaxBidForToken(address(uint160(_storage)), tokenId) == bidId) {
                    SnarkOfferBidLib.updateMaxBidPriceForToken(address(uint160(_storage)), tokenId);
                }
            }
            SnarkOfferBidLib.cancelOffer(address(uint160(_storage)), _offerIdArray[i]);
        }
        if (refunds > 0) {
            SnarkStorage(address(uint160(_storage))).transferFunds(address(uint160(msg.sender)), refunds);
        }
    }

    function setLinkDropPrice(uint256 tokenId, uint256 price) public onlyOwner {
        SnarkBaseLib.setTokenLastPrice(address(uint160(_storage)), tokenId, price);
    }

    function toGiftToken(uint256 tokenId, address to) public onlyOwnerOf(tokenId) {
        require(to != address(0), "Receiver's  address can't be equal zero");
        SnarkOfferBidLib.prepareTokenToGift(address(uint160(_storage)), to, tokenId);
        SnarkCommonLib.transferToken(address(uint160(_storage)), tokenId, msg.sender, to);
        SnarkERC721(address(uint160(_erc721))).echoTransfer(msg.sender, to, tokenId);
    }

    function getSaleStatusForOffer(uint256 _offerId) public view returns (uint256) {
        return SnarkOfferBidLib.getSaleStatusForOffer(address(uint160(_storage)), _offerId);
    }

    function getTotalNumberOfOffers() public view returns (uint256) {
        return SnarkOfferBidLib.getTotalNumberOfOffers(address(uint160(_storage)));
    }

    function getTokenByOffer(uint256 _offerId) public view returns (uint256) {
        return SnarkOfferBidLib.getTokenByOffer(address(uint160(_storage)), _offerId);
    }

    function getOfferByToken(uint256 _tokenId) public view returns (uint256) {
        return SnarkOfferBidLib.getOfferByToken(address(uint160(_storage)), _tokenId);
    }

    function getOfferDetail(uint256 _offerId) public view returns (
        uint256 offerId,
        uint256 offerPrice,
        uint256 offerStatus,
        uint256 tokenId,
        address tokenOwner)
    {
        offerId = _offerId;
        offerPrice = SnarkOfferBidLib.getOfferPrice(address(uint160(_storage)), _offerId);
        offerStatus = SnarkOfferBidLib.getSaleStatusForOffer(address(uint160(_storage)), _offerId);
        tokenId = SnarkOfferBidLib.getTokenByOffer(address(uint160(_storage)), _offerId);
        tokenOwner = SnarkBaseLib.getOwnerOfToken(address(uint160(_storage)), tokenId);
    }

    function getListOfOffersForOwner(address _offerOwner) public view returns (uint256[] memory) {
        return SnarkOfferBidLib.getListOfOffersForOwner(address(uint160(_storage)), _offerOwner);
    }

}
