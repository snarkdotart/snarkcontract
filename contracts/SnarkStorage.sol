pragma solidity ^0.4.24;

import "./OpenZeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";


contract SnarkStorage is Ownable, SnarkDefinitions {

    /*** STORAGE ***/

    // An array containing the Artwork struct for all artworks.
    Artwork[] private artworks;
    // An array containing the structures of profit share schemes
    ProfitShareScheme[] private profitShareSchemes;

    // Mapping from a contract address to access indicator
    mapping (address => bool) private accessAllowed;
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
    // Mapping from address of owner to profit share schemes
    mapping (address => uint256[]) private addressToProfitShareSchemesMap;
    // Mapping token of revenue participant to their approval confirmation
    mapping (uint256 => mapping (address => bool)) private tokenToParticipantApprovingMap;

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

    /*** Artwork ***/
    function getArtworksAmount() external view onlyPlatform returns (uint256) {
        return artworks.length;
    }

    function getArtworkDescription(uint256 _tokenId) external view onlyPlatform checkTokenId(_tokenId) returns (
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

    function getArtworkDetails(uint256 _tokenId) external view onlyPlatform checkTokenId(_tokenId) returns (
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

    function addArtwork(
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
        returns(uint256) 
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

    function updateArtworkLastPrice(uint256 _tokenId, uint8 _lastPrice) 
        external 
        onlyPlatform 
        checkTokenId(_tokenId) 
    {
        artworks[_tokenId].lastPrice = _lastPrice;
    }

    function updateArtworkProfitShareSchemaId(uint256 _tokenId, uint256 _profitShareSchemaId) 
        external 
        onlyPlatform 
        checkTokenId(_tokenId) 
    {
        artworks[_tokenId].profitShareSchemaId = _profitShareSchemaId;
    }

    function updateArtworkProfitShareFromSecondarySale(uint256 _tokenId, uint8 _profitShareForSecondarySale) 
        external 
        onlyPlatform 
        checkTokenId(_tokenId) 
    {
        artworks[_tokenId].profitShareFromSecondarySale = _profitShareForSecondarySale;
    }

    /*** ProfitShareScheme ***/

    function addProfitShareScheme(address[] _participants, uint8[] _profits) external onlyPlatform returns (uint256) {
        uint256 _schemeId = profitShareSchemes.push(ProfitShareScheme({
            participants: _participants,
            profits: _profits
        })) - 1;
        return _schemeId;
    }

    function getProfitShareSchemesTotalAmount() external view onlyPlatform returns (uint256) {
        return profitShareSchemes.length;
    }

    function getProfitShareSchemeParticipantsAmount(uint256 _schemeId) 
        external 
        view 
        onlyPlatform
        checkSchemeId(_schemeId)
        returns (uint256) 
    {
        return profitShareSchemes[_schemeId].participants.length;
    }

    function getProfitShareSchemeForParticipant(
        uint256 _schemeId, 
        uint256 _participantIndex
    ) 
        external 
        view 
        onlyPlatform 
        checkSchemeId(_schemeId)
        returns (address _participant, uint8 _profit) 
    {
        require(_participantIndex < profitShareSchemes[_schemeId].participants.length);
        
        return (
            profitShareSchemes[_schemeId].participants[_participantIndex], 
            profitShareSchemes[_schemeId].profits[_participantIndex]
        );
    }

    /*** addressToProfitShareSchemesMap ***/
    function addProfitShareSchemeToAddress(address _owner, uint256 _schemeId) external onlyPlatform {
        addressToProfitShareSchemesMap[_owner].push(_schemeId);
    }

    function getProfitShareSchemesAmountByAddress(address _owner) external view onlyPlatform returns (uint256) {
        return addressToProfitShareSchemesMap[_owner].length;
    }

    function getProfitShareSchemeIdByIndex(address _owner, uint256 _index) external view onlyPlatform returns (uint256) {
        return addressToProfitShareSchemesMap[_owner][_index];
    }

    /*** tokenToOwnerMap ***/
    function getOwnerByToken(uint256 _tokenId) external view onlyPlatform returns (address) {
        return tokenToOwnerMap[_tokenId];
    }

    function setOwnerForToken(uint256 _tokenId, address _owner) external onlyPlatform {
        tokenToOwnerMap[_tokenId] = _owner;
    }

    /*** ownerToTokensMap ***/
    function getTokensAmountByOwner(address _owner) external view onlyPlatform returns (uint256) {
        return ownerToTokensMap[_owner].length;
    }

    function getTokenIdForOwnerByIndex(address _owner, uint256 _index) external view onlyPlatform returns (uint256) {
        require(_index < ownerToTokensMap[_owner].length);
        return ownerToTokensMap[_owner][_index];
    }

    function addTokenToOwner(address _owner, uint256 _tokenId) external onlyPlatform {
        ownerToTokensMap[_owner].push(_tokenId);
    }

    function deleteOwnerTokenByIndex(address _owner, uint256 _index) external onlyPlatform {
        ownerToTokensMap[_owner][_index] = ownerToTokensMap[_owner][ownerToTokensMap[_owner].length - 1];
        ownerToTokensMap[_owner].length--;
    }
    
    /*** hashToUsedMap ***/
    function getHashToUsed(bytes32 _hash) external view onlyPlatform returns (bool) {
        return hashToUsedMap[_hash];
    }

    function setHashToUsed(bytes32 _hash, bool _isUsed) external onlyPlatform {
        hashToUsedMap[_hash] = _isUsed;
    }

    /*** operatorToApprovalsMap ***/
    
    /*** tokenToApprovalsMap ***/

    /*** tokenToParticipantApprovingMap ***/
    function getParticipantApproving(uint256 _tokenId, address _participant) external view onlyPlatform returns (bool) {
        return tokenToParticipantApprovingMap[_tokenId][_participant];
    }

    function setParticipantApproving(uint256 _tokenId, address _participant, bool _consent) external onlyPlatform {
        tokenToParticipantApprovingMap[_tokenId][_participant] = _consent;
    }

    /*** artistToTokensMap ***/
    function getTokensAmountByArtist(address _artist) external view onlyPlatform returns (uint256) {
        return artistToTokensMap[_artist].length;
    }

    function getTokenIdForArtistByIndex(address _artist, uint256 _index) external view onlyPlatform returns (uint256) {
        require(_index < artistToTokensMap[_artist].length);
        return artistToTokensMap[_artist][_index];
    }

    function addTokenToArtist(address _artist, uint256 _tokenId) external onlyPlatform {
        artistToTokensMap[_artist].push(_tokenId);
    }
}