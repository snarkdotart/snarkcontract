pragma solidity ^0.4.22;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkBaseLib.sol";


contract TestSnarkBaseLib is Ownable {

    //////////////////// THIS CONTRACT IS JUST FOR TEST ////////////////////

    using SnarkBaseLib for address;
    address public storageAddress;

    constructor(address _storageAddress) public {
        storageAddress = _storageAddress;
    }

    /*** ADD ***/
    event ArtworkCreated(address _artworkOwner, uint256 _artworkId);
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
        uint256 artworkId = storageAddress.addArtwork(
            _artistAddress,
            _artworkHash,
            _limitedEdition,
            _editionNumber,
            _lastPrice,
            _profitShareSchemeId,
            _profitShareFromSecondarySale,
            _artworkUrl
        );
        emit ArtworkCreated(msg.sender, artworkId);
    }

    function addProfitShareScheme(address[] _participants, uint256[] _profits) external {
        uint256 schemeId = storageAddress.addProfitShareScheme(msg.sender, _participants, _profits);
        emit ProfitShareSchemeCreated(msg.sender, schemeId);
    }

    function addArtworkToArtistList(uint256 _artworkId, address _artistAddress) external {
        storageAddress.addArtworkToArtistList(_artworkId, _artistAddress);
    }

    function addPendingWithdrawals(uint256 _owner, uint256 _balance) external {
        storageAddress.addPendingWithdrawals(_owner, _balance);
    }

    function subPendingWithdrawals(uint256 _owner, uint256 _balance) external {
        storageAddress.subPendingWithdrawals(_owner, _balance);
    }

    /*** SET ***/
    function setSnarkWalletAddress(address _val) external {
        storageAddress.setSnarkWalletAddress(_val);
    }

    function setPlatformProfitShare(uint256 _val) external {
        storageAddress.setPlatformProfitShare(_val);
    }

    function setArtworkArtist(uint256 _artworkId, address _val) external {
        storageAddress.setArtworkArtist(_artworkId, _val);
    }

    function setArtworkLimitedEdition(uint256 _artworkId, uint256 _val) external {
        storageAddress.setArtworkLimitedEdition(_artworkId, _val);
    }

    function setArtworkEditionNumber(uint256 _artworkId, uint256 _editionNumber) external {
        storageAddress.setArtworkEditionNumber(_artworkId, _editionNumber);
    }

    function setArtworkLastPrice(uint256 _artworkId, uint256 _lastPrice) external {
        storageAddress.setArtworkLastPrice(_artworkId, _lastPrice);
    }

    function setArtworkHash(uint256 _artworkId, bytes32 _artworkHash) external {
        storageAddress.setArtworkHash(_artworkId, _artworkHash);
    }

    function setArtworkProfitShareSchemeId(uint256 _artworkId, uint256 _schemeId) external {
        storageAddress.setArtworkProfitShareSchemeId(_artworkId, _schemeId);
    }

    function setArtworkProfitShareFromSecondarySale(uint256 _artworkId, uint256 _profitShare) external {
        storageAddress.setArtworkProfitShareFromSecondarySale(_artworkId, _profitShare);
    }

    function setArtworkURL(uint256 _artworkId, string _url) external {
        storageAddress.setArtworkURL(_artworkId, _url);
    }

    function setArtworkToOwner(address _owner, uint256 _artworkId) external {
        storageAddress.setArtworkToOwner(_owner, _artworkId);
    }

    function setOwnerOfArtwork(uint256 _artworkId, address _artworkOwner) external {
        storageAddress.setOwnerOfArtwork(_artworkId, _artworkOwner);
    }

    function setArtworkHashAsInUse(bytes32 _artworkHash, bool _isUsed) external {
        storageAddress.setArtworkHashAsInUse(_artworkHash, _isUsed);
    }

    function setApprovalsToOperator(address _owner, address _operator, bool _isApproved) external {
        storageAddress.setApprovalsToOperator(_owner, _operator, _isApproved);
    }

    function setApprovalsToArtwork(address _owner, uint256 _artworkId, bool _isApproved) external {
        storageAddress.setApprovalsToArtwork(_owner, _artworkId, _isApproved);
    }

    function setArtworkToParticipantApproving(uint256 _artworkId, address _participant, bool _consent) external {
        storageAddress.setArtworkToParticipantApproving(_artworkId, _participant, _consent);
    }

    function setArtworkToSaleType(uint256 _artworkId, uint256 _saleType) external {
        storageAddress.setArtworkToSaleType(_artworkId, _saleType);
    }

    // function transferArtwork(uint256 _artworkId, address _from, address _to) external {
    //     storageAddress.transferArtwork(_artworkId, _from, _to);
    // }
    /*** DELETE ***/
    function deleteArtworkFromOwner(uint256 _index) external {
        storageAddress.deleteArtworkFromOwner(msg.sender, _index);
    }

    // function deleteApprovalsToOperator(address _owner, address _operator) external {
    //     storageAddress.deleteApprovalsToOperator(_owner, _operator);
    // }
    // function deleteApprovalsToArtwork(address _owner, uint256 _artworkId) external {
    //     storageAddress.deleteApprovalsToArtwork(_owner, _artworkId);
    // }
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

    function getArtworkArtist(uint256 _artworkId) external view returns (address) {
        return storageAddress.getArtworkArtist(_artworkId);
    }

    function getArtworkLimitedEdition(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getArtworkLimitedEdition(_artworkId);
    }

    function getArtworkEditionNumber(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getArtworkEditionNumber(_artworkId);
    }

    function getArtworkLastPrice(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getArtworkLastPrice(_artworkId);
    }

    function getArtworkHash(uint256 _artworkId) external view returns (bytes32) {
        return storageAddress.getArtworkHash(_artworkId);
    }

    function getArtworkProfitShareSchemeId(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getArtworkProfitShareSchemeId(_artworkId);
    }

    function getArtworkProfitShareFromSecondarySale(uint256 _artworkId) external view returns (uint256) {
        return storageAddress.getArtworkProfitShareFromSecondarySale(_artworkId);
    }

    function getArtworkURL(uint256 _artworkId) external view returns (string) {
        return storageAddress.getArtworkURL(_artworkId);
    }

    function getArtwork(uint256 _artworkId) external view returns (
        address artistAddress, 
        bytes32 artworkHash,
        uint256 limitedEdition,
        uint256 editionNumber,
        uint256 lastPrice,
        uint256 profitShareSchemeId,
        uint256 profitShareFromSecondarySale,
        string artworkUrl) 
    {
        return storageAddress.getArtwork(_artworkId);
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

    function getNumberOfOwnerArtworks(address _sender) external view returns (uint256 number) {
        return storageAddress.getNumberOfOwnerArtworks(_sender);
    }

    function getArtworkIdOfOwner(address _owner, uint256 _index) external view returns (uint256 artworkId) {
        return storageAddress.getArtworkIdOfOwner(_owner, _index);
    }

    function getOwnerOfArtwork(uint256 _artworkId) external view returns (address artworkOwner) 
    {
        return storageAddress.getOwnerOfArtwork(_artworkId);
    }

    function getNumberOfArtistArtworks(address _artistAddress) external view returns (uint256 number) {
        return storageAddress.getNumberOfArtistArtworks(_artistAddress);
    }

    function getArtworkIdForArtist(address _artistAddress, uint256 _index) external view returns (uint256 artworkId) {
        return storageAddress.getArtworkIdForArtist(_artistAddress, _index);
    }

    function getArtworkHashAsInUse(bytes32 _artworkHash) external view returns (bool isUsed) {
        return storageAddress.getArtworkHashAsInUse(_artworkHash);
    }

    function getApprovalsToOperator(address _owner, address _operator) external view returns (bool) {
        return storageAddress.getApprovalsToOperator(_owner, _operator);
    }

    function getApprovalsToArtwork(address _owner, uint256 _artworkId) external view returns (bool) {
        return storageAddress.getApprovalsToArtwork(_owner, _artworkId);
    }

    function getArtworkToParticipantApproving(uint256 _artworkId, address _participant) external view returns (bool) {
        return storageAddress.getArtworkToParticipantApproving(_artworkId, _participant);
    }

    function getPendingWithdrawals(uint256 _owner) external view returns (uint256 balance) {
        return storageAddress.getPendingWithdrawals(_owner);
    }

    function getArtworkToSaleType(uint256 _artworkId) external view returns (uint256 saleType) {
        return storageAddress.getArtworkToSaleType(_artworkId);
    }
}