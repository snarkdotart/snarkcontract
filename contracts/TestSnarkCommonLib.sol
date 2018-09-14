pragma solidity ^0.4.22;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkCommonLib.sol";
import "./SnarkBaseLib.sol";


contract TestSnarkCommonLib is Ownable {

    //////////////////// THIS CONTRACT IS JUST FOR TEST ////////////////////

    using SnarkCommonLib for address;
    using SnarkBaseLib for address;

    address public storageAddress;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event TokenCreated(address _artworkOwner, uint256 _artworkId);

    constructor(address _storageAddress) public {
        storageAddress = _storageAddress;
    }

    function transferArtwork(uint256 _artworkId, address _from, address _to) external {
        storageAddress.transferArtwork(_artworkId, _from, _to);
    }

    function addArtwork(
        address _artistAddress, 
        bytes32 _hashOfArtwork,
        uint256 _limitedEdition,
        uint256 _lastPrice,
        uint256 _profitShareSchemeId,
        uint256 _profitShareForSecondarySale,
        string _artworkUrl
    ) 
        external 
    {
        for (uint8 i = 0; i < _limitedEdition; i++) {
            uint256 _tokenId = storageAddress.addArtwork(
                _artistAddress,
                _hashOfArtwork,
                _limitedEdition,
                i + 1,
                _lastPrice,
                _profitShareSchemeId,
                _profitShareForSecondarySale,
                _artworkUrl
            );
            // memoraze that a digital work with this hash already loaded
            storageAddress.setArtworkHashAsInUse(_hashOfArtwork, true);
            // Enter the new owner
            storageAddress.setOwnerOfArtwork(_tokenId, msg.sender);
            // Add new token to new owner's token list
            storageAddress.setArtworkToOwner(msg.sender, _tokenId);
            // Add new token to new artist's token list
            storageAddress.addArtworkToArtistList(_tokenId, msg.sender);
            // Emit token event
            emit TokenCreated(msg.sender, _tokenId);
        }
    }
    
    function setOwnerOfArtwork(uint256 _artworkId, address _artworkOwner) external {
        storageAddress.setOwnerOfArtwork(_artworkId, _artworkOwner);
    }
    
    function setArtworkToOwner(address _owner, uint256 _artworkId) external {
        storageAddress.setArtworkToOwner(_owner, _artworkId);
    }

    function incomeDistribution(uint256 _price, uint256 _tokenId, address _from) external {
        storageAddress.incomeDistribution(_price, _tokenId, _from);
    }

    function setPlatformProfitShare(uint256 _platformProfitShare) external {
        storageAddress.setPlatformProfitShare(_platformProfitShare);
    }

    function changeProfitShareSchemeForToken(uint256 _tokenId, uint256 _newProfitShareSchemeId) external {
        storageAddress.setArtworkProfitShareSchemeId(_tokenId, _newProfitShareSchemeId);
    }

    function createProfitShareScheme(address[] _participants, uint256[] _percentAmount) external returns (uint256) {
        require(_participants.length == _percentAmount.length);
        return storageAddress.addProfitShareScheme(msg.sender, _participants, _percentAmount);
    }

    function getTotalNumberOfArtworks() external view returns (uint256) {
        return storageAddress.getTotalNumberOfArtworks();
    }

    function getNumberOfOwnerArtworks(address _sender) external view returns (uint256 number) {
        return storageAddress.getNumberOfOwnerArtworks(_sender);
    }

    function getArtworkIdOfOwner(address _owner, uint256 _index) external view returns (uint256 artworkId) {
        return storageAddress.getArtworkIdOfOwner(_owner, _index);
    }

    function getArtworkProfitShareSchemeId(uint256 _artworkId) external view
        returns (uint256 profitShareSchemeId)
    {
        return storageAddress.getArtworkProfitShareSchemeId(_artworkId);
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