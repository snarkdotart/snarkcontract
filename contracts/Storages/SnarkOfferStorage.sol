pragma solidity ^0.4.24;

import "./SnarkBaseStorage.sol";


contract SnarkOfferStorage is SnarkBaseStorage {

    /*** STORAGE ***/

    // List of all offers
    Offer[] private offers;
    // List of all bids
    Bid[] private bids;

    // Mapping of artwork to offers
    mapping (uint256 => uint256) private tokenToOfferMap;
    // Mapping of offers to owner
    mapping (uint256 => address) private offerToOwnerMap;
    // Mapping of owner to offers
    mapping (address => uint256[]) private ownerToOffersMap;
    // Mapping status to offers
    mapping (uint8 => uint256[]) private saleStatusToOffersMap;
    
    // Mapping of bids to owner
    mapping (uint256 => address) private bidToOwnerMap;
    // Mapping of owner to bids
    mapping (address => uint256[]) private ownerToBidsMap;
    // Mapping of artwork to bid
    mapping (uint256 => uint256[]) private tokenToBidsMap;

    modifier checkOfferId(uint256 _offerId) {
        require(offers.length > 0);
        require(_offerId < offers.length);
        _;
    }

    modifier checkBidId(uint256 _bidId) {
        require(bids.length > 0);
        require(_bidId < bids.length);
        _;
    }

    /*** offers ***/
    function get_offer(uint256 _offerId) external view onlyPlatform checkOfferId(_offerId) 
        returns (uint256 tokenId, uint256 price, SaleStatus status) 
    {
        return (offers[_offerId].tokenId, offers[_offerId].price, offers[_offerId].saleStatus);
    }

    function get_offers_count() external view onlyPlatform returns (uint256 offersCount) {
        return offers.length;
    }

    function add_offer(uint256 _price, uint256 _tokenId) external onlyPlatform returns (uint256 offerId) {
        return offers.push(Offer({
            tokenId: _tokenId,
            price: _price,
            saleStatus: SaleStatus.Active
        })) - 1;
    }

    function finish_offer(uint256 _offerId) external onlyPlatform checkOfferId(_offerId) {
        offers[_offerId].saleStatus = SaleStatus.Finished;
    }

    /*** bids ***/
    function get_bid(uint256 _bidId) external view onlyPlatform checkBidId(_bidId)
        returns (uint256 tokenId, uint256 price, SaleStatus saleStatus) 
    {
        return (bids[_bidId].tokenId, bids[_bidId].price, bids[_bidId].saleStatus);
    }

    function get_bids_count() external view onlyPlatform returns (uint256 bidsCount) {
        return bids.length;
    }

    function add_bid(uint256 _tokenId, uint256 _price) external onlyPlatform returns (uint256 bidId) {
        return bids.push(Bid({
            tokenId: _tokenId,
            price: _price,
            saleStatus: SaleStatus.Active
        })) - 1;
    }

    function finish_bid(uint256 _bidId) external onlyPlatform checkBidId(_bidId) {
        bids[_bidId].saleStatus = SaleStatus.Finished;
    }

    /*** tokenToOfferMap ***/
    function get_tokenToOfferMap(uint256 _tokenId) external view onlyPlatform checkTokenId(_tokenId) returns (uint256 offerId) {
        return tokenToOfferMap[_tokenId];
    }

    function set_tokenToOfferMap(uint256 _tokenId, uint256 _offerId) external onlyPlatform checkTokenId(_tokenId) {
        tokenToOfferMap[_tokenId] = _offerId;
    }

    function delete_tokenToOfferMap(uint256 _tokenId) external onlyPlatform {
        delete tokenToOfferMap[_tokenId];
    }

    /*** offerToOwnerMap ***/
    function get_offerToOwnerMap(uint256 _offerId) external view onlyPlatform checkOfferId(_offerId) returns (address offerOwner) {
        return offerToOwnerMap[_offerId];
    }

    function set_offerToOwnerMap(uint256 _offerId, address _newOwner) external onlyPlatform checkOfferId(_offerId) {
        offerToOwnerMap[_offerId] = _newOwner;
    }

    function delete_offerToOwnerMap(uint256 _offerId) external onlyPlatform checkOfferId(_offerId) {
        delete offerToOwnerMap[_offerId];
    }

    /*** ownerToOffersMap ***/
    function get_ownerToOffersMap_length(address _owner) external view onlyPlatform returns (uint256 offersCount) {
        return ownerToOffersMap[_owner].length;
    }

    function get_ownerToOffersMap(address _owner, uint256 _index) external view onlyPlatform returns (uint256 offerId) {
        require(_index < ownerToOffersMap[_owner].length && _index >= 0);
        return ownerToOffersMap[_owner][_index];
    }

    function add_ownerToOffersMap(address _owner, uint256 _offerId) external onlyPlatform returns (uint256 index) {
        return ownerToOffersMap[_owner].push(_offerId);
    }

    function delete_ownerToOffersMap(address _owner, uint256 _index) external onlyPlatform {
        require(_index < ownerToOffersMap[_owner].length && _index >= 0);
        ownerToOffersMap[_owner][_index] = ownerToOffersMap[_owner][ownerToOffersMap[_owner].length - 1];
        ownerToOffersMap[_owner].length--;
    }

    /*** saleStatusToOffersMap ***/
    function get_saleStatusToOffersMap_length(uint8 _saleStatus) external view onlyPlatform returns (uint256 offersCount) {
        return saleStatusToOffersMap[_saleStatus].length;
    }

    function get_saleStatusToOffersMap(uint8 _saleStatus, uint256 _index) external view onlyPlatform returns (uint256 offerId) {
        require(_index < saleStatusToOffersMap[_saleStatus].length && _index >= 0);
        return saleStatusToOffersMap[_saleStatus][_index];
    }

    function add_saleStatusToOffersMap(uint8 _saleStatus, uint256 _offerId) external onlyPlatform returns (uint256 index) {
        return saleStatusToOffersMap[_saleStatus].push(_offerId);
    }

    function delete_saleStatusToOffersMap(uint8 _saleStatus, uint256 _index) external onlyPlatform {
        require(_index < saleStatusToOffersMap[_saleStatus].length && _index >= 0);
        saleStatusToOffersMap[_saleStatus][_index] = saleStatusToOffersMap[_saleStatus][saleStatusToOffersMap[_saleStatus].length - 1];
        saleStatusToOffersMap[_saleStatus].length--;
    }

    /*** bidToOwnerMap ***/
    function get_bidToOwnerMap(uint256 _bidId) external view onlyPlatform checkBidId(_bidId) returns (address bidOwner) {
        return bidToOwnerMap[_bidId];
    }

    function set_bidToOwnerMap(uint256 _bidId, address _bidOwner) external onlyPlatform checkBidId(_bidId) {
        bidToOwnerMap[_bidId] = _bidOwner;
    }

    function delete_bidToOwnerMap(uint256 _bidId) external onlyPlatform checkBidId(_bidId) {
        delete bidToOwnerMap[_bidId];
    }

    /*** ownerToBidsMap ***/
    function get_ownerToBidsMap_length(address _bidOwner) external view onlyPlatform returns (uint256 bidsCount) {
        return ownerToBidsMap[_bidOwner].length;
    }

    function get_ownerToBidsMap(address _bidOwner, uint256 _index) external view onlyPlatform returns (uint256 bidId) {
        require(_index < ownerToBidsMap[_bidOwner].length && _index >= 0);
        return ownerToBidsMap[_bidOwner][_index];
    }

    function add_ownerToBidsMap(address _bidOwner, uint256 _bidId) external onlyPlatform returns (uint256 index) {
        return ownerToBidsMap[_bidOwner].push(_bidId);
    }

    function delete_ownerToBidsMap(address _bidOwner, uint256 _index) external onlyPlatform {
        require(_index < ownerToBidsMap[_bidOwner].length && _index >= 0);
        ownerToBidsMap[_bidOwner][_index] = ownerToBidsMap[_bidOwner][ownerToBidsMap[_bidOwner].length - 1];
        ownerToBidsMap[_bidOwner].length--;
    }

    /*** tokenToBidMap ***/
    function get_tokenToBidsMap_length(uint256 _tokenId) external view onlyPlatform returns (uint256 bidsCount) {
        return tokenToBidsMap[_tokenId].length;
    }

    function get_tokenToBidsMap(uint256 _tokenId, uint256 _index) external view onlyPlatform returns (uint256 bidId) {
        require(_index < tokenToBidsMap[_tokenId].length && _index >= 0);
        return tokenToBidsMap[_tokenId][_index];
    }

    function add_tokenToBidsMap(uint256 _tokenId, uint256 _bidId) external onlyPlatform returns (uint256 index) {
        return tokenToBidsMap[_tokenId].push(_bidId);
    }

    function delete_tokenToBidsMap(uint256 _tokenId, uint256 _index) external onlyPlatform {
        require(_index < tokenToBidsMap[_tokenId].length && _index >= 0);
        tokenToBidsMap[_tokenId][_index] = tokenToBidsMap[_tokenId][tokenToBidsMap[_tokenId].length - 1];
        tokenToBidsMap[_tokenId].length--;
    }

}