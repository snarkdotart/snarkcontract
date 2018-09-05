pragma solidity ^0.4.22;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkCommonLib.sol";
import "./SnarkBaseLib.sol";


contract TestSnarkCommonLib is Ownable {

    //////////////////// THIS CONTRACT IS JUST FOR TEST ////////////////////

    using SnarkCommonLib for address;
    using SnarkBaseLib for address;

    address public storageAddress;

    constructor(address _storageAddress) public {
        storageAddress = _storageAddress;
    }

    function transferArtwork(uint256 _artworkId, address _from, address _to) external {
        storageAddress.transferArtwork(_artworkId, _from, _to);
    }

    //////////////////// JUST FOR WORKING TEST ////////////////////
    event ArtworkCreated(address _artworkOwner, uint256 _artworkId);
    
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
    
    function setOwnerOfArtwork(uint256 _artworkId, address _artworkOwner) external {
        storageAddress.setOwnerOfArtwork(_artworkId, _artworkOwner);
    }
    
    function setArtworkToOwner(address _owner, uint256 _artworkId) external {
        storageAddress.setArtworkToOwner(_owner, _artworkId);
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

}