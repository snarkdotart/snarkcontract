pragma solidity ^0.4.24;

import "./SnarkStorage.sol";


library SnarkLib {
    
    /*** SET ***/
    function setSnarkWalletAddress(address _storageAddress, address _walletAddress) external {
        SnarkStorage(_storageAddress).setAddress(keccak256("snarkWalletAddress"), _walletAddress);
    }

    function setPlatformProfitShare(address _storageAddress, uint256 _platformProfitShare) external {
        SnarkStorage(_storageAddress).setUint(keccak256("platformProfitShare"), _platformProfitShare);
    }

    function setArtworkArtist(address _storageAddress, uint256 _tokenId, address _artistAddress) external {
        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("artwork", "artist", _tokenId)), 
            _artistAddress
        );
    }

    function setArtworkLimitedEdition(address _storageAddress, uint256 _tokenId, uint256 _limitedEdition) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "limitedEdition", _tokenId)), 
            _limitedEdition
        );
    }

    function setArtworkEditionNumber(address _storageAddress, uint256 _tokenId, uint256 _editionNumber) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "editionNumber", _tokenId)),
            _editionNumber
        );
    }

    function setArtworkLastPrice(address _storageAddress, uint256 _tokenId, uint256 _lastPrice) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "lastPrice", _tokenId)), 
            _lastPrice
        );
    }

    function setArtworkHash(address _storageAddress, uint256 _tokenId, bytes32 _artworkHash) external {
        SnarkStorage(_storageAddress).setBytes(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", _tokenId)),
            _artworkHash
        );
    }

    function setArtworkProfitShareSchemaId(address _storageAddress, uint256 _tokenId, uint256 _schemaId) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareSchemaId", _tokenId)),
            _schemaId
        );
    }

    function setArtworkProfitShareFromSecondarySale(address _storageAddress, uint256 _tokenId, uint256 _profitShare) 
        external 
    {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", _tokenId)),
            _profitShare
        );
    }

    function setArtworkURL(address _storageAddress, uint256 _tokenId, string _url) external {
        SnarkStorage(_storageAddress).setString(
            keccak256(abi.encodePacked("artwork", "url", _tokenId)),
            _url
        );
    }

    /*** ADD ***/
    function addArtwork(
        address _storageAddress, 
        address _artistAddress, 
        bytes32 _artworkHash,
        uint256 _limitedEdition,
        uint256 _editionNumber,
        uint256 _lastPrice,
        uint256 _profitShareSchemaId,
        uint256 _profitShareFromSecondarySale,
        string _artworkUrl
    ) 
        external returns (uint256 tokenId) 
    {
        tokenId = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfArtworks")) + 1;
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfArtworks"), tokenId);

        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("artwork", "artist", tokenId)), 
            _artistAddress
        );

        SnarkStorage(_storageAddress).setBytes(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", tokenId)),
            _artworkHash
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "limitedEdition", tokenId)), 
            _limitedEdition
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "editionNumber", tokenId)),
            _editionNumber
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "lastPrice", tokenId)), 
            _lastPrice
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareSchemaId", tokenId)),
            _profitShareSchemaId
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", tokenId)),
            _profitShareFromSecondarySale
        );

        SnarkStorage(_storageAddress).setString(
            keccak256(abi.encodePacked("artwork", "url", tokenId)), 
            _artworkUrl
        );

        return tokenId;
    }

    /*** GET ***/
    function getSnarkWalletAddress(address _storageAddress) external view returns (address walletAddress) {
        return SnarkStorage(_storageAddress).addressStorage(keccak256("snarkWalletAddress"));
    }

    function getPlatformProfitShare(address _storageAddress) external view returns (uint256 platformProfit) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256("platformProfitShare"));
    }

    function getTotalNumberOfArtworks(address _storageAddress) external view returns (uint256 numberOfArtworks) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfArtworks"));
    }

    function getArtworkArtist(address _storageAddress, uint256 _tokenId) 
        external view returns (address artistAddress) 
    {
        return SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("artwork", "artist", _tokenId))
        );
    }

    function getArtworkLimitedEdition(address _storageAddress, uint256 _tokenId) external view 
        returns (uint256 limitedEdition) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "limitedEdition", _tokenId))
        );
    }

    function getArtworkEditionNumber(address _storageAddress, uint256 _tokenId) external view 
        returns (uint256 editionNumber) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "editionNumber", _tokenId))
        );
    }

    function getArtworkLastPrice(address _storageAddress, uint256 _tokenId) external view
        returns (uint256 lastPrice)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "lastPrice", _tokenId))
        );
    }

    function getArtworkHash(address _storageAddress, uint256 _tokenId) external view 
        returns (bytes32 artworkHash)
    {
        return SnarkStorage(_storageAddress).bytesStorage(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", _tokenId))
        );
    }

    function getArtworkProfitShareSchemaId(address _storageAddress, uint256 _tokenId) external view
        returns (uint256 profitShareSchemaId)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareSchemaId", _tokenId))
        );
    }

    function getArtworkProfitShareFromSecondarySale(address _storageAddress, uint256 _tokenId) external view
        returns (uint256 profitShare)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", _tokenId))
        );
    }

    function getArtworkURL(address _storageAddress, uint256 _tokenId) external view returns (string artworkUrl) {
        return SnarkStorage(_storageAddress).stringStorage(
            keccak256(abi.encodePacked("artwork", "url", _tokenId))
        );
    }

    function getArtwork(address _storageAddress, uint256 _tokenId) external view returns (
        address artistAddress, 
        bytes32 artworkHash,
        uint256 limitedEdition,
        uint256 editionNumber,
        uint256 lastPrice,
        uint256 profitShareSchemaId,
        uint256 profitShareFromSecondarySale,
        string artworkUrl) 
    {
        artistAddress = SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("artwork", "artist", _tokenId))
        );
        
        artworkHash = SnarkStorage(_storageAddress).bytesStorage(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", _tokenId))
        );

        limitedEdition = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "limitedEdition", _tokenId))
        );

        editionNumber = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "editionNumber", _tokenId))
        );

        lastPrice = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "lastPrice", _tokenId))
        );

        profitShareSchemaId = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareSchemaId", _tokenId))
        );

        profitShareFromSecondarySale = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", _tokenId))
        );

        artworkUrl = SnarkStorage(_storageAddress).stringStorage(
            keccak256(abi.encodePacked("artwork", "url", _tokenId))
        );
    }

}