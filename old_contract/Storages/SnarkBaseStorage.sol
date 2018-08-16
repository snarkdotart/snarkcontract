pragma solidity ^0.4.24;

import "../OpenZeppelin/Ownable.sol";
import "../OpenZeppelin/SafeMath.sol";
import "./SnarkDefinitions.sol";


contract SnarkBaseStorage is Ownable, SnarkDefinitions {

    /*** CONSTANTS ***/

    // Snark profit share %, default = 5%
    uint8 private platformProfitShare = 5;

    // Snark's wallet address
    address private snarkWalletAddress;

    /*** STORAGE ***/

    // An array containing the Artwork struct for all artworks.
    Artwork[] private artworks;
    // An array containing the structures of profit share schemes
    ProfitShareScheme[] private profitShareSchemes;

    // Mapping from a contract address to access indicator
    mapping (address => bool) private accessAllowed;
    // Mapping from address of owner to profit share schemes (PSS)
    mapping (address => uint256[]) private addressToPSSMap;
    // Mapping from token ID to owner
    mapping (uint256 => address) private tokenToOwnerMap;
    // Mapping from owner to their Token IDs
    mapping (address => uint256[]) private ownerToTokensMap;
    // Mapping from artist to their Token IDs
    mapping (address => uint256[]) private artistToTokensMap;
    // Mapping from hash to previously used indicator
    mapping (bytes32 => bool) private hashToUsedMap;
    // Mapping from owner to approved operator
    mapping (address => mapping (address => bool)) private operatorToApprovalsMap;
    // Mapping from token ID to approved address
    mapping (uint256 => address) private tokenToApprovalsMap;
    // Mapping token of revenue participant to their approval confirmation
    mapping (uint256 => mapping (address => bool)) private tokenToParticipantApprovingMap;
    // Mapping of an address with its balance
    mapping (address => uint256) private pendingWithdrawals;
    // Artwork can only be in one of four states:
    // 1. Not being sold
    // 2. Offered for sale at an offer price
    // 3. Auction sale
    // 4. Art loan
    // Must avoid any possibility of a double sale
    mapping (uint256 => SaleType) internal tokenToSaleTypeMap;

    /*** MODIFIERS ***/
    modifier onlyPlatform() {
        require(accessAllowed[msg.sender] == true || msg.sender == owner);
        _;
    }

    modifier checkTokenId(uint256 _tokenId) {
        require(artworks.length > 0);
        require(_tokenId < artworks.length);
        _;
    }

    modifier checkSchemeId(uint256 _schemeId) {
        require(profitShareSchemes.length > 0);
        require(_schemeId < profitShareSchemes.length);
        _;
    }

    /*** ACCESS ***/
    function allowAccess(address _address) external onlyOwner {
        accessAllowed[_address] = true;
    }

    function denyAccess(address _address) external onlyOwner {
        accessAllowed[_address] = false;
    }

    /*** SNARK's DATA ***/
    function set_platformProfitShare(uint8 _platformProfitShare) external onlyOwner {
        platformProfitShare = _platformProfitShare;
    }

    function set_snarkWalletAddress(address _snarkWalletAddrss) external onlyOwner {
        snarkWalletAddress = _snarkWalletAddrss;
    }

    function get_platformProfitShare() external view onlyPlatform returns (uint8 platformProfit) {
        return platformProfitShare;
    }

    function get_snarkWalletAddress() external view onlyPlatform returns (address snarkAddress) {
        return snarkWalletAddress;
    }

    /*** Artwork ***/
    function get_artworks_length() external view onlyPlatform returns (uint256 artworksCount) {
        return artworks.length;
    }

    function get_artwork_description(uint256 _tokenId) external view onlyPlatform checkTokenId(_tokenId) returns (
        address artist,
        uint16 limitedEdition,
        uint16 editionNumber,
        uint256 lastPrice) 
    {
        return (
            artworks[_tokenId].artist,
            artworks[_tokenId].limitedEdition,
            artworks[_tokenId].editionNumber,
            artworks[_tokenId].lastPrice
        );
    }

    function get_artwork_details(uint256 _tokenId) external view onlyPlatform checkTokenId(_tokenId) returns (
        bytes32 hastOfArtwork,
        uint256 profitShareSchemaId,
        uint8 profitShareFromSecondarySale,
        string artworkUrl)
    {
        return (
            artworks[_tokenId].hashOfArtwork, 
            artworks[_tokenId].profitShareSchemaId,
            artworks[_tokenId].profitShareFromSecondarySale,
            artworks[_tokenId].artworkUrl
        );
    }

    function add_artwork(
        address _artist,
        bytes32 _hashOfArtwork,
        uint16 _limitedEdition,
        uint16 _editionNumber,
        uint256 _lastPrice,
        uint256 _profitShareSchemaId,
        uint8 _profitShareFromSecondarySale,
        string _artworkUrl
    ) 
        external 
        onlyPlatform
        returns(uint256 artworkId) 
    {
        uint256 tokenId = artworks.push(Artwork({
            artist: _artist,
            hashOfArtwork: _hashOfArtwork,
            limitedEdition: _limitedEdition,
            editionNumber: _editionNumber,
            lastPrice: _lastPrice,
            profitShareSchemaId: _profitShareSchemaId,
            profitShareFromSecondarySale: _profitShareFromSecondarySale,
            artworkUrl: _artworkUrl
        })) - 1;
        return tokenId;
    }

    function update_artworks_lastPrice(uint256 _tokenId, uint256 _lastPrice) 
        external 
        onlyPlatform 
        checkTokenId(_tokenId) 
    {
        artworks[_tokenId].lastPrice = _lastPrice;
    }

    function update_artworks_profitShareSchemaId(uint256 _tokenId, uint256 _profitShareSchemaId) 
        external 
        onlyPlatform 
        checkTokenId(_tokenId) 
    {
        artworks[_tokenId].profitShareSchemaId = _profitShareSchemaId;
    }

    function update_artworks_profitShareFromSecondarySale(uint256 _tokenId, uint8 _profitShareForSecondarySale) 
        external 
        onlyPlatform 
        checkTokenId(_tokenId) 
    {
        artworks[_tokenId].profitShareFromSecondarySale = _profitShareForSecondarySale;
    }

    /*** profitShareSchemes ***/
    function add_profitShareSchemes(address[] _participants, uint8[] _profits) external onlyPlatform returns (uint256 profitShareSchemeId) {
        uint256 _schemeId = profitShareSchemes.push(ProfitShareScheme({
            participants: _participants,
            profits: _profits
        })) - 1;
        return _schemeId;
    }

    function get_profitShareSchemes_length() external view onlyPlatform returns (uint256 PSSCount) {
        return profitShareSchemes.length;
    }

    function get_profitShareSchemes_participants_length(uint256 _schemeId) 
        external 
        view 
        onlyPlatform
        checkSchemeId(_schemeId)
        returns (uint256 participantsCount) 
    {
        return profitShareSchemes[_schemeId].participants.length;
    }

    function get_profitShareSchemes(
        uint256 _schemeId, 
        uint256 _participantIndex
    ) 
        external 
        view 
        onlyPlatform 
        checkSchemeId(_schemeId)
        returns (address participant, uint8 profit) 
    {
        require(_participantIndex < profitShareSchemes[_schemeId].participants.length && _participantIndex >= 0);
        return (
            profitShareSchemes[_schemeId].participants[_participantIndex], 
            profitShareSchemes[_schemeId].profits[_participantIndex]
        );
    }

    /*** addressToProfitShareSchemesMap ***/
    function get_addressToProfitShareSchemesMap_length(address _owner) external view onlyPlatform returns (uint256 schemesCount) {
        return addressToPSSMap[_owner].length;
    }

    function get_addressToProfitShareSchemesMap(address _owner, uint256 _index) external view onlyPlatform returns (uint256 schemeId) {
        require(_index < addressToPSSMap[_owner].length && _index >= 0);
        return addressToPSSMap[_owner][_index];
    }

    function add_addressToProfitShareSchemesMap(address _owner, uint256 _schemeId) external onlyPlatform {
        addressToPSSMap[_owner].push(_schemeId);
    }

    function delete_addressToProfitShareSchemesMap(address _owner, uint256 _index) external onlyPlatform {
        require(_index < addressToPSSMap[_owner].length && _index >= 0);
        addressToPSSMap[_owner][_index] = addressToPSSMap[_owner][addressToPSSMap[_owner].length - 1];
        addressToPSSMap[_owner].length--;
    }

    /*** tokenToOwnerMap ***/
    function get_tokenToOwnerMap(uint256 _tokenId) external view onlyPlatform returns (address tokenOwner) {
        return tokenToOwnerMap[_tokenId];
    }

    function set_tokenToOwnerMap(uint256 _tokenId, address _owner) external onlyPlatform {
        tokenToOwnerMap[_tokenId] = _owner;
    }

    function delete_tokenToOwnerMap(uint256 _tokenId) external onlyPlatform {
        delete tokenToOwnerMap[_tokenId];
    }

    /*** ownerToTokensMap ***/
    function get_ownerToTokensMap_length(address _owner) external view onlyPlatform returns (uint256 tokensCount) {
        return ownerToTokensMap[_owner].length;
    }

    function get_ownerToTokensMap(address _owner, uint256 _index) external view onlyPlatform returns (uint256 tokenId) {
        require(_index < ownerToTokensMap[_owner].length && _index >= 0);
        return ownerToTokensMap[_owner][_index];
    }

    function add_ownerToTokensMap(address _owner, uint256 _tokenId) external onlyPlatform {
        ownerToTokensMap[_owner].push(_tokenId);
    }

    function delete_ownerToTokensMap(address _owner, uint256 _index) external onlyPlatform {
        require(_index < ownerToTokensMap[_owner].length && _index >= 0);
        ownerToTokensMap[_owner][_index] = ownerToTokensMap[_owner][ownerToTokensMap[_owner].length - 1];
        ownerToTokensMap[_owner].length--;
    }
    
    /*** artistToTokensMap ***/
    function get_artistToTokensMap_length(address _artist) external view onlyPlatform returns (uint256 tokensCount) {
        return artistToTokensMap[_artist].length;
    }

    function get_artistToTokensMap(address _artist, uint256 _index) external view onlyPlatform 
        returns (uint256 tokenId) 
    {
        require(_index < artistToTokensMap[_artist].length && _index >= 0);
        return artistToTokensMap[_artist][_index];
    }

    function add_artistToTokensMap(address _artist, uint256 _tokenId) external onlyPlatform {
        artistToTokensMap[_artist].push(_tokenId);
    }

    function delete_artistToTokensMap(address _artist, uint256 _index) external onlyPlatform {
        require(_index < artistToTokensMap[_artist].length && _index >= 0);
        artistToTokensMap[_artist][_index] = artistToTokensMap[_artist][artistToTokensMap[_artist].length - 1];
        artistToTokensMap[_artist].length--;
    }

    /*** hashToUsedMap ***/
    function get_hashToUsedMap(bytes32 _hash) external view onlyPlatform returns (bool isUsed) {
        return hashToUsedMap[_hash];
    }

    function set_hashToUsedMap(bytes32 _hash, bool _isUsed) external onlyPlatform {
        hashToUsedMap[_hash] = _isUsed;
    }

    function delete_hashToUsedMap(bytes32 _hash) external onlyPlatform {
        delete hashToUsedMap[_hash];
    }

    /*** operatorToApprovalsMap ***/
    function get_operatorToApprovalsMap(address _owner, address _approvalAddress) external view onlyPlatform returns (bool isApprovalAddress) {
        return operatorToApprovalsMap[_owner][_approvalAddress];
    }

    function set_operatorToApprovalsMap(address _owner, address _approvalAddress, bool _isApproved) external onlyPlatform {
        operatorToApprovalsMap[_owner][_approvalAddress] = _isApproved;
    }

    function delete_operatorToApprovalsMap(address _owner, address _approvalAddress) external onlyPlatform {
        delete operatorToApprovalsMap[_owner][_approvalAddress];
    }
    
    /*** tokenToApprovalsMap ***/
    function get_tokenToApprovalsMap(uint256 _tokenId) external view onlyPlatform returns (address approvalAddress) {
        return tokenToApprovalsMap[_tokenId];
    }

    function set_tokenToApprovalsMap(uint256 _tokenId, address _approvalAddress) external onlyPlatform {
        tokenToApprovalsMap[_tokenId] = _approvalAddress;
    }

    function delete_tokenToApprovalsMap(uint256 _tokenId) external onlyPlatform {
        delete tokenToApprovalsMap[_tokenId];
    }

    /*** tokenToParticipantApprovingMap ***/
    function get_tokenToParticipantApprovingMap(uint256 _tokenId, address _participant) external view onlyPlatform
        returns (bool isParticipantApproved)
    {
        return tokenToParticipantApprovingMap[_tokenId][_participant];
    }

    function set_tokenToParticipantApprovingMap(uint256 _tokenId, address _participant, bool _consent) external onlyPlatform {
        tokenToParticipantApprovingMap[_tokenId][_participant] = _consent;
    }

    function delete_tokenToParticipantApprovingMap(uint256 _tokenId, address _participant) external onlyPlatform {
        delete tokenToParticipantApprovingMap[_tokenId][_participant];
    }

    /*** pendingWithdrawals ***/
    function get_pendingWithdrawals(address _owner) external view onlyPlatform returns (uint256 ownersBalance) {
        return pendingWithdrawals[_owner];
    }

    function set_pendingWithdrawals(address _owner, uint256 _balance) external onlyPlatform {
        pendingWithdrawals[_owner] = _balance;
    }

    function add_pendingWithdrawals(address _owner, uint256 _addSum) external onlyPlatform {
        pendingWithdrawals[_owner] = SafeMath.add(pendingWithdrawals[_owner], _addSum);
    }

    function sub_pendingWithdrawals(address _owner, uint256 _subSum) external onlyPlatform {
        pendingWithdrawals[_owner] = SafeMath.sub(pendingWithdrawals[_owner], _subSum);
    }

    /*** tokenToSaleTypeMap ***/
    function get_tokenToSaleTypeMap(uint256 _tokenId) external view onlyPlatform checkTokenId(_tokenId) returns (uint8 saleType) {
        return uint8(tokenToSaleTypeMap[_tokenId]);
    }

    function set_tokenToSaleTypeMap(uint256 _tokenId, uint8 _saleType) external onlyPlatform checkTokenId(_tokenId) {
        tokenToSaleTypeMap[_tokenId] = SaleType(_saleType);
    }

    function delete_tokenToSaleTypeMap(uint256 _tokenId) external onlyPlatform checkTokenId(_tokenId) {
        delete tokenToSaleTypeMap[_tokenId];
    }

}