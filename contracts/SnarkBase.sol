pragma solidity ^0.4.22;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkLib.sol";


contract SnarkBase is Ownable {

    //////////////////// THIS CONTRACT IS JUST FOR TEST ////////////////////

    using SnarkLib for address;
    address public storageAddress;

    constructor(address _storageAddress) public {
        storageAddress = _storageAddress;
    }

    /*** ADD ***/
    event ArtworkCreated(address _tokenOwner, uint256 _tokenId);
    event ProfitShareSchemeCreated(address _schemeCreator, uint256 _profitShareSchemeId);
    
    function addArtwork(
        address _artistAddress, 
        bytes32 _artworkHash,
        uint256 _limitedEdition,
        uint256 _editionNumber,
        uint256 _lastPrice,
        uint256 _profitShareSchemeId,
        uint256 _profitShareFromSecondarySale,
        string _artworkUrl
    ) 
        external 
    {
        uint256 tokenId = storageAddress.addArtwork(
            _artistAddress,
            _artworkHash,
            _limitedEdition,
            _editionNumber,
            _lastPrice,
            _profitShareSchemeId,
            _profitShareFromSecondarySale,
            _artworkUrl
        );
        emit ArtworkCreated(msg.sender, tokenId);
    }

    function addProfitShareScheme(address[] _participants, uint256[] _profits) external {
        uint256 schemeId = storageAddress.addProfitShareScheme(msg.sender, _participants, _profits);
        emit ProfitShareSchemeCreated(msg.sender, schemeId);
    }

    /*** SET ***/
    function setSnarkWalletAddress(address _val) external {
        storageAddress.setSnarkWalletAddress(_val);
    }

    function setPlatformProfitShare(uint256 _val) external {
        storageAddress.setPlatformProfitShare(_val);
    }

    function setArtworkArtist(uint256 _tokenId, address _val) external {
        storageAddress.setArtworkArtist(_tokenId, _val);
    }

    function setArtworkLimitedEdition(uint256 _tokenId, uint256 _val) external {
        storageAddress.setArtworkLimitedEdition(_tokenId, _val);
    }

    function setArtworkEditionNumber(uint256 _tokenId, uint256 _editionNumber) external {
        storageAddress.setArtworkEditionNumber(_tokenId, _editionNumber);
    }

    function setArtworkLastPrice(uint256 _tokenId, uint256 _lastPrice) external {
        storageAddress.setArtworkLastPrice(_tokenId, _lastPrice);
    }

    function setArtworkHash(uint256 _tokenId, bytes32 _artworkHash) external {
        storageAddress.setArtworkHash(_tokenId, _artworkHash);
    }

    function setArtworkProfitShareSchemeId(uint256 _tokenId, uint256 _schemeId) external {
        storageAddress.setArtworkProfitShareSchemeId(_tokenId, _schemeId);
    }

    function setArtworkProfitShareFromSecondarySale(uint256 _tokenId, uint256 _profitShare) external {
        storageAddress.setArtworkProfitShareFromSecondarySale(_tokenId, _profitShare);
    }

    function setArtworkURL(uint256 _tokenId, string _url) external {
        storageAddress.setArtworkURL(_tokenId, _url);
    }

    /*** GET ***/
    function getSnarkWalletAddress() external view returns (address) {
        return storageAddress.getSnarkWalletAddress();
    }

    function getPlatformProfitShare() external view returns (uint256) {
        return storageAddress.getPlatformProfitShare();
    }

    function getTotalNumberOfArtworks() external view returns (uint256) {
        return storageAddress.getTotalNumberOfArtworks();
    }

    function getArtworkArtist(uint256 _tokenId) external view returns (address) {
        return storageAddress.getArtworkArtist(_tokenId);
    }

    function getArtworkLimitedEdition(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getArtworkLimitedEdition(_tokenId);
    }

    function getArtworkEditionNumber(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getArtworkEditionNumber(_tokenId);
    }

    function getArtworkLastPrice(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getArtworkLastPrice(_tokenId);
    }

    function getArtworkHash(uint256 _tokenId) external view returns (bytes32) {
        return storageAddress.getArtworkHash(_tokenId);
    }

    function getArtworkProfitShareSchemeId(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getArtworkProfitShareSchemeId(_tokenId);
    }

    function getArtworkProfitShareFromSecondarySale(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getArtworkProfitShareFromSecondarySale(_tokenId);
    }

    function getArtworkURL(uint256 _tokenId) external view returns (string) {
        return storageAddress.getArtworkURL(_tokenId);
    }

    function getArtwork(uint256 _tokenId) external view returns (
        address artistAddress, 
        bytes32 artworkHash,
        uint256 limitedEdition,
        uint256 editionNumber,
        uint256 lastPrice,
        uint256 profitShareSchemeId,
        uint256 profitShareFromSecondarySale,
        string artworkUrl) 
    {
        return storageAddress.getArtwork(_tokenId);
    }

    function getTotalNumberOfProfitShareSchemes() external view returns (uint256) {
        return storageAddress.getTotalNumberOfProfitShareSchemes();
    }

    function getNumberOfParticipantsForProfitShareScheme(uint256 _schemeId) external view returns (uint256) {
        return storageAddress.getNumberOfParticipantsForProfitShareScheme(_schemeId);
    }

    function getParticipantOfProfitShareScheme(uint256 _schemeId, uint256 _index) 
        external
        view
        returns (address, uint256)
    {
        return storageAddress.getParticipantOfProfitShareScheme(_schemeId, _index);
    }

    function getNumberOfProfitShareSchemesForOwner() external view returns (uint256) {
        return storageAddress.getNumberOfProfitShareSchemesForOwner(msg.sender);
    }

    function getProfitShareSchemeIdForOwner(uint256 _index) external view returns (uint256) {
        return storageAddress.getProfitShareSchemeIdForOwner(msg.sender, _index);
    }
}