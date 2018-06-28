pragma solidity ^0.4.24;

import "./OpenZeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";


contract SnarkStorage is Ownable, SnarkDefinitions {

    /// @dev An array containing the Artwork struct for all artworks.
    Artwork[] artworks;

    function getArtworksAmount() public view onlyPlatform returns (uint256) {
        return artworks.length;
    }

    function getArtwork(uint256 _tokenId) public view onlyPlatform returns (        
        bytes32 _hashOfArtwork,
        uint16 _limitedEdition,
        uint16 _editionNumber,
        uint256 _lastPrice,
        uint256 _profitShareSchemaId,
        uint8 _profitShareFromSecondarySale,
        string _artworkUrl) 
    {
        require(artworks.length > 0);
        require(_tokenId > 0);
        require(_tokenId <= artworks.length);
        
        return (artworks[_tokenId - 1].hashOfArtwork, 
            artworks[_tokenId - 1].limitedEdition,
            artworks[_tokenId - 1].editionNumber,
            artworks[_tokenId - 1].lastPrice,
            artworks[_tokenId - 1].profitShareSchemaId,
            artworks[_tokenId - 1].profitShareFromSecondarySale,
            artworks[_tokenId - 1].artworkUrl);
    }

    function addArtwork(
        bytes32 _hashOfArtwork,
        uint16 _limitedEdition,
        uint16 _editionNumber,
        uint256 _lastPrice,
        uint256 _profitShareSchemaId,
        uint8 _profitShareFromSecondarySale,
        string _artworkUrl
    ) 
        public 
        onlyPlatform
        returns(uint256) 
    {
        return artworks.push(Artwork({
            hashOfArtwork: _hashOfArtwork,
            limitedEdition: _limitedEdition,
            editionNumber: _editionNumber,
            lastPrice: _lastPrice,
            profitShareSchemaId: _profitShareSchemaId,
            profitShareFromSecondarySale: _profitShareFromSecondarySale,
            artworkUrl: _artworkUrl
        }));
    }

    function updateArtworkLastPrice(uint256 _tokenId, uint8 _lastPrice) public onlyPlatform {
        artworks[_tokenId - 1].lastPrice = _lastPrice;
    }

    function updateArtworkProfitShareSchemaId(uint256 _tokenId, uint256 _profitShareSchemaId) public onlyPlatform {
        artworks[_tokenId - 1].profitShareSchemaId = _profitShareSchemaId;
    }

    function updateArtworkProfitShareFromSecondarySale(uint256 _tokenId, uint8 _profitShareForSecondarySale) public onlyPlatform {
        artworks[_tokenId - 1].profitShareFromSecondarySale = _profitShareForSecondarySale;
    }

    /// @dev An array containing the structures of profit share schemes
    ProfitShareScheme[] profitShareSchemes;

    function addProfitShareScheme(address[] _participants, uint8[] _percentAmounts) public onlyPlatform returns (uint256) {
        return profitShareSchemes.push(ProfitShareScheme({
            participants: _participants,
            profits: _percentAmounts
        })) - 1;
    }

    // Mapping from a contract address to access indicator
    mapping (address => bool) public accessAllowed; 

    modifier onlyPlatform() {
        require(accessAllowed[msg.sender] == true || msg.sender == owner);
        _;
    }

    function allowAccess(address _address) public onlyOwner {
        accessAllowed[_address] = true;
    }

    function denyAccess(address _address) onlyOwner public {
        accessAllowed[_address] = false;
    }

    // Mapping from token ID to owner
    mapping (uint256 => address) tokenToOwnerMap;

    function getOwnerByToken(uint256 _tokenId) public view onlyPlatform returns (address) {
        return tokenToOwnerMap[_tokenId];
    }

    function setOwnerForToken(uint256 _tokenId, address _owner) public onlyPlatform {
        tokenToOwnerMap[_tokenId] = _owner;
    }

    // Mapping from owner to their Token IDs
    mapping (address => uint256[]) ownerToTokensMap;

    function getTokensByOwner(address _owner) public view onlyPlatform returns (uint256[]) {
        return ownerToTokensMap[_owner];
    }

    function addTokenToOwner(address _owner, uint256 _tokenId) public onlyPlatform {
        ownerToTokensMap[_owner].push(_tokenId);
    }

    function deleteOwnerTokenByIndex(address _owner, uint256 _index) public onlyPlatform {
        ownerToTokensMap[_owner][_index] = ownerToTokensMap[_owner][ownerToTokensMap[_owner].length - 1];
        ownerToTokensMap[_owner].length--;
    }
    
    // Mapping from hash to previously used indicator
    mapping (bytes32 => bool) hashToUsedMap;

    function getHashToUsed(bytes32 _hash) public view onlyPlatform returns (bool) {
        return hashToUsedMap[_hash];
    }

    function setHashToUsed(bytes32 _hash, bool _isUsed) public onlyPlatform {
        hashToUsedMap[_hash] = _isUsed;
    }

    mapping (address => mapping (address => bool)) operatorToApprovalsMap; // Mapping from owner to approved operator
    mapping (uint256 => address) tokenToApprovalsMap;                      // Mapping from token ID to approved address
    
    // Mapping from address of owner to profit share schemes
    mapping (address => uint256[]) addressToProfitShareSchemesMap;

    function addProfitShareSchemeToAddress(address _owner, uint256 _schemeId) public onlyPlatform {
        addressToProfitShareSchemesMap[_owner].push(_schemeId);
    }

    function getProfitShareSchemeByAddress(address _owner) public view onlyPlatform returns (uint256[]) {
        return addressToProfitShareSchemesMap[_owner];
    }
}