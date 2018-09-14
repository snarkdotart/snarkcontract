pragma solidity ^0.4.22;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkOfferBidLib.sol";
import "./SnarkBaseLib.sol";


contract TestSnarkOfferBidLib is Ownable {

    //////////////////// THIS CONTRACT IS JUST FOR TEST ////////////////////

    using SnarkOfferBidLib for address;
    using SnarkBaseLib for address;

    address public storageAddress;

    event OfferAdded(address _offerOwner, uint256 _offerId, uint256 _artworkId);
    event OfferDeleted(uint256 _offerId);
    event BidAdded(address _bidOwner, uint256 _bidId);
    event BidDeleted(uint256 _bidId);

    constructor(address _storageAddress) public {
        storageAddress = _storageAddress;
    }

    /*** SET ***/
    function setPriceForOffer(uint256 _offerId, uint256 _price) external {
        storageAddress.setPriceForOffer(_offerId, _price);
    }

    function setArtworkIdForOffer(uint256 _offerId, uint256 _artworkId) external {
        storageAddress.setArtworkIdForOffer(_offerId, _artworkId);
    }

    function setOfferIdForArtworkId(uint256 _artworkId, uint256 _offerId) external {
        storageAddress.setOfferIdForArtworkId(_artworkId, _offerId);
    }

    function setSaleStatusForOffer(uint256 _offerId, uint256 _saleStatus) external {
        storageAddress.setSaleStatusForOffer(_offerId, _saleStatus);
    }

    function setOwnerForOffer(uint256 _offerId, address _offerOwner) external {
        storageAddress.setOwnerForOffer(_offerId, _offerOwner);
    }

    function setOwnerOfBid(uint256 _bidId, address _bidOwner) external {
        storageAddress.setOwnerOfBid(_bidId, _bidOwner);
    }

    function setArtworkToBid(uint256 _bidId, uint256 _artworkId) external {
        storageAddress.setArtworkToBid(_bidId, _artworkId);
    }

    function setPriceToBid(uint256 _bidId, uint256 _price) external {
        storageAddress.setPriceToBid(_bidId, _price);
    }

    function setSaleStatusForBid(uint256 _bidId, uint256 _saleStatus) external {
        storageAddress.setSaleStatusForBid(_bidId, _saleStatus);
    }

    /*** DELETE ***/
    function deleteOffer(uint256 _offerId) external {
        storageAddress.deleteOffer(_offerId);
        emit OfferDeleted(_offerId);
    }

    function deleteBid(uint256 _bidId) external {
        storageAddress.deleteBid(_bidId);
        emit BidDeleted(_bidId);
    }

    /*** ADD ***/
    function addOffer(address _offerOwner, uint256 _artworkId, uint256 _price) external {
        uint256 offerId = storageAddress.addOffer(_offerOwner, _artworkId, _price);
        emit OfferAdded(_offerOwner, offerId, _artworkId);
    }

    function addBid(address _bidOwner, uint256 _artworkId, uint256 _price) external {
        uint256 bidId = storageAddress.addBid(_bidOwner, _artworkId, _price);
        emit BidAdded(_bidOwner, bidId);
    }

    function addBidToArtworkBidsList(uint256 _artworkId, uint256 _bidId) external {
        storageAddress.addBidToArtworkBidsList(_artworkId, _bidId);
    }

    function increaseTotalNumberOfOffers() external {
        storageAddress.increaseTotalNumberOfOffers();
    }

    function decreaseTotalNumberOfOffers() external {
        storageAddress.decreaseTotalNumberOfOffers();
    }

    function increaseTotalNumberOfOwnerOffers(address _offerOwner) external {
        storageAddress.increaseTotalNumberOfOwnerOffers(_offerOwner);
    }

    function decreaseTotalNumberOfOwnerOffers(address _offerOwner) external {
        storageAddress.decreaseTotalNumberOfOwnerOffers(_offerOwner);
    }

    function increaseTotalNumberOfBids() external {
        storageAddress.increaseTotalNumberOfBids();
    }

    function decreaseTotalNumberOfBids() external {
        storageAddress.decreaseTotalNumberOfBids();
    }

    function increaseNumberOfArtworkBids(uint256 _artworkId) external {
        storageAddress.increaseNumberOfArtworkBids(_artworkId);
    }

    function decreaseNumberOfArtworkBids(uint256 _artworkId) external {
        storageAddress.decreaseNumberOfArtworkBids(_artworkId);
    }

    function increaseNumberOfOwnerBids(address _bidOwner) 
        external 
    {
        storageAddress.increaseNumberOfOwnerBids(_bidOwner);
    }

    function decreaseNumberOfOwnerBids(address _bidOwner)
        external
    {
        storageAddress.decreaseNumberOfOwnerBids(_bidOwner);
    }

    function addOfferToOwnerOffersList(address _offerOwner, uint256 _offerId) external {
        storageAddress.addOfferToOwnerOffersList(_offerOwner, _offerId);
    }

    function addBidToOwnerBidsList(address _bidOwner, uint256 _bidId) external {
        storageAddress.addBidToOwnerBidsList(_bidOwner, _bidId);
    }

    /*** GET ***/
    function getTotalNumberOfOffers() external view returns (uint256 numberOfOffers) {
        return storageAddress.getTotalNumberOfOffers();
    }

    function getOfferPrice(uint256 _offerId) external view returns (uint256 price) {
        return storageAddress.getOfferPrice(_offerId);
    }

    function getArtworkIdByOfferId(uint256 _offerId) external view returns (uint256 artworkId) {
        return storageAddress.getArtworkIdByOfferId(_offerId);
    }

    function getOfferIdByArtworkId(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getOfferIdByArtworkId(_artworkId);
    }

    function getSaleStatusForOffer(uint256 _offerId) external view returns (uint256) {
        return storageAddress.getSaleStatusForOffer(_offerId);
    }

    // function getNumberOfOffersBySaleStatus(uint256 _saleStatus) external view returns (uint256) {
    //     return storageAddress.getNumberOfOffersBySaleStatus(_saleStatus);
    // }
    // function getOfferBySaleStatus(uint256 _saleStatus, uint256 _index) external view returns (uint256) {
    //     return storageAddress.getOfferBySaleStatus(_saleStatus, _index);
    // }
    function getTotalNumberOfOwnerOffers(address _offerOwner) external view returns (uint256) {
        return storageAddress.getTotalNumberOfOwnerOffers(_offerOwner);
    }

    function getOfferIdOfOwner(address _offerOwner, uint256 _index) external view returns (uint256) {
        return storageAddress.getOfferIdOfOwner(_offerOwner, _index);
    }

    function getSaleTypeToArtwork(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getSaleTypeToArtwork(_artworkId);
    }

    function getSaleStatusToArtwork(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getSaleStatusToArtwork(_artworkId);
    }

    function getOwnerOfOffer(uint256 _offerId) external view returns (address) {
        return storageAddress.getOwnerOfOffer(_offerId);
    }

    function getTotalNumberOfBids() external view returns (uint256) {
        return storageAddress.getTotalNumberOfBids();
    }

    function getOwnerOfBid(uint256 _bidId) external view returns (address) {
        return storageAddress.getOwnerOfBid(_bidId);
    }

    function getNumberOfArtworkBids(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getNumberOfArtworkBids(_artworkId);
    }

    function getNumberBidsOfOwner(address _bidOwner) external view returns (uint256) {
        return storageAddress.getNumberBidsOfOwner(_bidOwner);
    }

    function getBidOfOwner(address _bidOwner, uint256 _index) external view returns (uint256) {
        return storageAddress.getBidOfOwner(_bidOwner, _index);
    }

    function getBidIdForArtwork(uint256 _artworkId, uint256 _index) external view returns (uint256) {
        return storageAddress.getBidIdForArtwork(_artworkId, _index);
    }

    function getArtworkIdByBidId(uint256 _bidId) external view returns (uint256) {
        return storageAddress.getArtworkIdByBidId(_bidId);
    }

    function getBidPrice(uint256 _bidId) external view returns (uint256) {
        return storageAddress.getBidPrice(_bidId);
    }

    function getBidSaleStatus(uint256 _bidId) external view returns (uint256) {
        return storageAddress.getBidSaleStatus(_bidId);
    }

}