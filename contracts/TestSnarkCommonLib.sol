pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkCommonLib.sol";
import "./SnarkBaseLib.sol";


contract TestSnarkCommonLib is Ownable {

    //////////////////// THIS CONTRACT IS JUST FOR TEST ////////////////////

    using SnarkCommonLib for address;
    using SnarkBaseLib for address;

    address public storageAddress;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event TokenCreated(address _tokenOwner, uint256 _tokenId);

    constructor(address _storageAddress) public {
        storageAddress = _storageAddress;
    }

    function transferToken(uint256 _tokenId, address _from, address _to) external {
        storageAddress.transferToken(_tokenId, _from, _to);
    }

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
    
    function setOwnerOfToken(uint256 _tokenId, address _tokenOwner) external {
        storageAddress.setOwnerOfToken(_tokenId, _tokenOwner);
    }
    
    function setTokenToOwner(address _owner, uint256 _tokenId) external {
        storageAddress.setTokenToOwner(_owner, _tokenId);
    }

    function incomeDistribution(uint256 _price, uint256 _tokenId, address _from) external {
        storageAddress.incomeDistribution(_price, _tokenId, _from);
    }

    function setPlatformProfitShare(uint256 _platformProfitShare) external {
        storageAddress.setPlatformProfitShare(_platformProfitShare);
    }

    function changeProfitShareSchemeForToken(uint256 _tokenId, uint256 _newProfitShareSchemeId) external {
        storageAddress.setTokenProfitShareSchemeId(_tokenId, _newProfitShareSchemeId);
    }

    function createProfitShareScheme(address[] _participants, uint256[] _percentAmount) external returns (uint256) {
        require(_participants.length == _percentAmount.length, "length of two arrays must be match");
        return storageAddress.addProfitShareScheme(msg.sender, _participants, _percentAmount);
    }

    function getTotalNumberOfTokens() external view returns (uint256) {
        return storageAddress.getTotalNumberOfTokens();
    }

    function getOwnedTokensCount(address _sender) external view returns (uint256 number) {
        return storageAddress.getOwnedTokensCount(_sender);
    }

    function getTokenIdOfOwner(address _owner, uint256 _index) external view returns (uint256 tokenId) {
        return storageAddress.getTokenIdOfOwner(_owner, _index);
    }

    function getTokenProfitShareSchemeId(uint256 _tokenId) external view
        returns (uint256 profitShareSchemeId)
    {
        return storageAddress.getTokenProfitShareSchemeId(_tokenId);
    }

    function getWithdrawBalance(address _owner) external view returns (uint256) {
        return storageAddress.getPendingWithdrawals(_owner);
    }

    function getNumberOfParticipantsForProfitShareScheme(uint256 _schemeId) external view returns (uint256) {
        return storageAddress.getNumberOfParticipantsForProfitShareScheme(_schemeId);
    }

    function getProfitShareSchemesTotalCount() external view returns (uint256) {
        return storageAddress.getTotalNumberOfProfitShareSchemes();
    }

    function getParticipantOfProfitShareScheme(uint256 _schemeId, uint256 _index) 
        external 
        view 
        returns (address, uint256) 
    {
        return storageAddress.getParticipantOfProfitShareScheme(_schemeId, _index);
    }

    function calculatePlatformProfitShare(uint256 _income) external view returns (uint256 profit, uint256 residue) {
        return storageAddress.calculatePlatformProfitShare(_income);
    }

}