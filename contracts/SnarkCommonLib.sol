pragma solidity ^0.4.24;

import "./SnarkStorage.sol";


library SnarkCommonLib {
    
    function transferArtwork(address _storageAddress, uint256 _artworkId, address _from, address _to) external {
        if (_artworkId <= SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfArtworks")) &&
            _from == SnarkStorage(_storageAddress).addressStorage(
                keccak256(abi.encodePacked("ownerOfArtwork", _artworkId)))
        ) {
            // deleteArtworkFromOwner
            uint256 numberOfArtworks = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _from)));
            for (uint256 i = 0; i < numberOfArtworks; i++) {
                if (_artworkId == SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("artworkOfOwner", _from, i))
                )) {
                    uint256 _index = i;
                    break;
                }
            }
            uint256 maxIndex = numberOfArtworks - 1;
            if (maxIndex != _index) {
                uint256 artworkId = SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("artworkOfOwner", _from, maxIndex)));
                SnarkStorage(_storageAddress).setUint(
                    keccak256(abi.encodePacked("artworkOfOwner", _from, _index)), 
                    artworkId);
            }
            SnarkStorage(_storageAddress).deleteUint(
                keccak256(abi.encodePacked("artworkOfOwner", _from, maxIndex)));
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _from)),
                maxIndex);
            // setOwnerOfArtwork
            SnarkStorage(_storageAddress).setAddress(
                keccak256(abi.encodePacked("ownerOfArtwork", _artworkId)),
                _to);
            // setArtworkToOwner
            _index = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _to))); 
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("artworkOfOwner", _to, _index)),
                _artworkId);
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _to)),
                _index + 1);
        }
    }

}