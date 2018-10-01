pragma solidity ^0.4.24;

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
    event TokenCreated(address indexed _owner, uint256 _tokenId);
    event ProfitShareSchemeCreated(address _schemeCreator, uint256 _profitShareSchemeId);
    
    function addToken(
        address _artistAddress, 
        bytes32 _hashOfToken,
        uint256 _limitedEdition,
        uint256 _lastPrice,
        uint256 _profitShareSchemeId,
        uint256 _profitShareForSecondarySale,
        string _tokenUrl,
        bool isAcceptLoanRequestFromSnark,
        bool isAcceptLoanRequestFromOthers
    ) 
        external 
    {
        for (uint8 i = 0; i < _limitedEdition; i++) {
            uint256 _tokenId = storageAddress.addToken(
                _artistAddress,
                _hashOfToken,
                _limitedEdition,
                i + 1,
                _lastPrice,
                _profitShareSchemeId,
                _profitShareForSecondarySale,
                _tokenUrl,
                isAcceptLoanRequestFromSnark,
                isAcceptLoanRequestFromOthers
            );
            // memoraze that a digital work with this hash already loaded
            storageAddress.setTokenHashAsInUse(_hashOfToken, true);
            // Enter the new owner
            storageAddress.setOwnerOfToken(_tokenId, msg.sender);
            // Add new token to new owner's token list
            storageAddress.setTokenToOwner(msg.sender, _tokenId);
            // Add new token to new artist's token list
            storageAddress.addTokenToArtistList(_tokenId, msg.sender);
            // Emit token event
            emit TokenCreated(msg.sender, _tokenId);
        }
    }

    function addProfitShareScheme(address[] _participants, uint256[] _profits) external {
        uint256 schemeId = storageAddress.addProfitShareScheme(msg.sender, _participants, _profits);
        emit ProfitShareSchemeCreated(msg.sender, schemeId);
    }

    function addTokenToArtistList(uint256 _tokenId, address _artistAddress) external {
        storageAddress.addTokenToArtistList(_tokenId, _artistAddress);
    }

    function addPendingWithdrawals(address _owner, uint256 _balance) external {
        storageAddress.addPendingWithdrawals(_owner, _balance);
    }

    function subPendingWithdrawals(address _owner, uint256 _balance) external {
        storageAddress.subPendingWithdrawals(_owner, _balance);
    }

    /*** SET ***/
    function setSnarkWalletAddress(address _val) external {
        storageAddress.setSnarkWalletAddress(_val);
    }

    function setPlatformProfitShare(uint256 _val) external {
        storageAddress.setPlatformProfitShare(_val);
    }

    function setTokenArtist(uint256 _tokenId, address _val) external {
        storageAddress.setTokenArtist(_tokenId, _val);
    }

    function setTokenLimitedEdition(uint256 _tokenId, uint256 _val) external {
        storageAddress.setTokenLimitedEdition(_tokenId, _val);
    }

    function setTokenEditionNumber(uint256 _tokenId, uint256 _editionNumber) external {
        storageAddress.setTokenEditionNumber(_tokenId, _editionNumber);
    }

    function setTokenLastPrice(uint256 _tokenId, uint256 _lastPrice) external {
        storageAddress.setTokenLastPrice(_tokenId, _lastPrice);
    }

    function setTokenHash(uint256 _tokenId, bytes32 _tokenHash) external {
        storageAddress.setTokenHash(_tokenId, _tokenHash);
    }

    function setTokenProfitShareSchemeId(uint256 _tokenId, uint256 _schemeId) external {
        storageAddress.setTokenProfitShareSchemeId(_tokenId, _schemeId);
    }

    function setTokenProfitShareFromSecondarySale(uint256 _tokenId, uint256 _profitShare) external {
        storageAddress.setTokenProfitShareFromSecondarySale(_tokenId, _profitShare);
    }

    function setTokenURL(uint256 _tokenId, string _url) external {
        storageAddress.setTokenURL(_tokenId, _url);
    }

    function setTokenToOwner(address _owner, uint256 _tokenId) external {
        storageAddress.setTokenToOwner(_owner, _tokenId);
    }

    function setOwnerOfToken(uint256 _tokenId, address _tokenOwner) external {
        storageAddress.setOwnerOfToken(_tokenId, _tokenOwner);
    }

    function setTokenHashAsInUse(bytes32 _tokenHash, bool _isUsed) external {
        storageAddress.setTokenHashAsInUse(_tokenHash, _isUsed);
    }

    function setApprovalsToOperator(address _owner, address _operator, bool _isApproved) external {
        storageAddress.setApprovalsToOperator(_owner, _operator, _isApproved);
    }

    function setApprovalsToToken(address _owner, uint256 _tokenId, address _operator) external {
        storageAddress.setApprovalsToToken(_owner, _tokenId, _operator);
    }

    function setTokenToParticipantApproving(uint256 _tokenId, address _participant, bool _consent) external {
        storageAddress.setTokenToParticipantApproving(_tokenId, _participant, _consent);
    }

    function setSaleTypeToToken(uint256 _tokenId, uint256 _saleType) external {
        storageAddress.setSaleTypeToToken(_tokenId, _saleType);
    }

    function setSaleStatusToToken(uint256 _tokenId, uint _saleStatus) external {
        storageAddress.setSaleStatusToToken(_tokenId, _saleStatus);
    }

    /*** DELETE ***/
    function deleteTokenFromOwner(uint256 _index) external {
        storageAddress.deleteTokenFromOwner(msg.sender, _index);
    }

    /*** GET ***/
    function getSnarkWalletAddress() external view returns (address) {
        return storageAddress.getSnarkWalletAddress();
    }

    function getPlatformProfitShare() external view returns (uint256) {
        return storageAddress.getPlatformProfitShare();
    }

    function getTotalNumberOfTokens() external view returns (uint256) {
        return storageAddress.getTotalNumberOfTokens();
    }

    function getTokenArtist(uint256 _tokenId) external view returns (address) {
        return storageAddress.getTokenArtist(_tokenId);
    }

    function getTokenLimitedEdition(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getTokenLimitedEdition(_tokenId);
    }

    function getTokenEditionNumber(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getTokenEditionNumber(_tokenId);
    }

    function getTokenLastPrice(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getTokenLastPrice(_tokenId);
    }

    function getTokenHash(uint256 _tokenId) external view returns (bytes32) {
        return storageAddress.getTokenHash(_tokenId);
    }

    function getTokenProfitShareSchemeId(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getTokenProfitShareSchemeId(_tokenId);
    }

    function getTokenProfitShareFromSecondarySale(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getTokenProfitShareFromSecondarySale(_tokenId);
    }

    function getTokenURL(uint256 _tokenId) external view returns (string) {
        return storageAddress.getTokenURL(_tokenId);
    }

    function getTokenDetails(uint256 _tokenId) external view returns (
        address artistAddress, 
        bytes32 tokenHash,
        uint256 limitedEdition,
        uint256 editionNumber,
        uint256 lastPrice,
        uint256 profitShareSchemeId,
        uint256 profitShareFromSecondarySale,
        string tokenUrl,
        bool isAcceptOfLoanRequestFromSnark,
        bool isAcceptOfLoanRequestFromOthers) 
    {
        return storageAddress.getTokenDetails(_tokenId);
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

    function getOwnedTokensCount(address _sender) external view returns (uint256 number) {
        return storageAddress.getOwnedTokensCount(_sender);
    }

    function getTokenIdOfOwner(address _owner, uint256 _index) external view returns (uint256 tokenId) {
        return storageAddress.getTokenIdOfOwner(_owner, _index);
    }

    function getOwnerOfToken(uint256 _tokenId) external view returns (address tokenOwner) 
    {
        return storageAddress.getOwnerOfToken(_tokenId);
    }

    function getNumberOfArtistTokens(address _artistAddress) external view returns (uint256) {
        return storageAddress.getNumberOfArtistTokens(_artistAddress);
    }

    function getTokenIdForArtist(address _artistAddress, uint256 _index) external view returns (uint256 tokenId) {
        return storageAddress.getTokenIdForArtist(_artistAddress, _index);
    }

    function getTokenHashAsInUse(bytes32 _tokenHash) external view returns (bool isUsed) {
        return storageAddress.getTokenHashAsInUse(_tokenHash);
    }

    function getApprovalsToOperator(address _owner, address _operator) external view returns (bool) {
        return storageAddress.getApprovalsToOperator(_owner, _operator);
    }

    function getApprovalsToToken(address _owner, uint256 _tokenId) external view returns (address) {
        return storageAddress.getApprovalsToToken(_owner, _tokenId);
    }

    function getTokenToParticipantApproving(uint256 _tokenId, address _participant) external view returns (bool) {
        return storageAddress.getTokenToParticipantApproving(_tokenId, _participant);
    }

    function getPendingWithdrawals(address _owner) external view returns (uint256) {
        return storageAddress.getPendingWithdrawals(_owner);
    }

    function getSaleTypeToToken(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getSaleTypeToToken(_tokenId);
    }

    function getSaleStatusToToken(uint256 _tokenId) external view returns (uint256) {
        return storageAddress.getSaleStatusToToken(_tokenId);
    }
}