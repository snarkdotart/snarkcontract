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

    function setArtworkArtist(address _storageAddress, uint256 _artworkId, address _artistAddress) external {
        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("artwork", "artist", _artworkId)), 
            _artistAddress
        );
    }

    function setArtworkLimitedEdition(address _storageAddress, uint256 _artworkId, uint256 _limitedEdition) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "limitedEdition", _artworkId)), 
            _limitedEdition
        );
    }

    function setArtworkEditionNumber(address _storageAddress, uint256 _artworkId, uint256 _editionNumber) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "editionNumber", _artworkId)),
            _editionNumber
        );
    }

    function setArtworkLastPrice(address _storageAddress, uint256 _artworkId, uint256 _lastPrice) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "lastPrice", _artworkId)), 
            _lastPrice
        );
    }

    function setArtworkHash(address _storageAddress, uint256 _artworkId, bytes32 _artworkHash) external {
        SnarkStorage(_storageAddress).setBytes(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", _artworkId)),
            _artworkHash
        );
    }

    function setArtworkProfitShareSchemeId(address _storageAddress, uint256 _artworkId, uint256 _schemeId) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareSchemeId", _artworkId)),
            _schemeId
        );
    }

    function setArtworkProfitShareFromSecondarySale(address _storageAddress, uint256 _artworkId, uint256 _profitShare) 
        external 
    {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", _artworkId)),
            _profitShare
        );
    }

    function setArtworkURL(address _storageAddress, uint256 _artworkId, string _url) external {
        SnarkStorage(_storageAddress).setString(
            keccak256(abi.encodePacked("artwork", "url", _artworkId)),
            _url
        );
    }

    function setArtworkToOwner(address _storageAddress, address _artworkOwner, uint256 _artworkId) external {
        uint256 index = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _artworkOwner))
        ); 

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artworkOfOwner", _artworkOwner, index)),
            _artworkId
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _artworkOwner)),
            index + 1
        );
    }

    function setOwnerOfArtwork(address _storageAddress, uint256 _artworkId, address _artworkOwner) external {
        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("ownerOfArtwork", _artworkId)),
            _artworkOwner
        );
    }

    function setArtworkHashAsInUse(address _storageAddress, bytes32 _artworkHash, bool _isUsed) external {
        SnarkStorage(_storageAddress).setBool(
            keccak256(abi.encodePacked("hashIsUsed", _artworkHash)),
            _isUsed
        );
    }

    function setApprovalsToOperator(
        address _storageAddress, 
        address _owner, 
        address _operator, 
        bool _isApproved
    ) 
        external 
    {
        SnarkStorage(_storageAddress).setBool(
            keccak256(abi.encodePacked("approvedOperator", _owner, _operator)),
            _isApproved
        );
    }

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

    /*** DELETE ***/
    function deleteArtworkFromOwner(address _storageAddress, address _artworkOwner, uint256 _index) external {
        uint256 maxIndex = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _artworkOwner))
        ) - 1;

        if (maxIndex != _index) {
            uint256 artworkId = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("artworkOfOwner", _artworkOwner, maxIndex))
            );

            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("artworkOfOwner", _artworkOwner, _index)),
                artworkId
            );
        }

        SnarkStorage(_storageAddress).deleteUint(
            keccak256(abi.encodePacked("artworkOfOwner", _artworkOwner, maxIndex))
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _artworkOwner)),
            maxIndex
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
        uint256 _profitShareSchemeId,
        uint256 _profitShareFromSecondarySale,
        string _artworkUrl
    ) 
        external returns (uint256 artworkId) 
    {
        artworkId = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfArtworks")) + 1;
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfArtworks"), artworkId);

        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("artwork", "artist", artworkId)), 
            _artistAddress
        );

        SnarkStorage(_storageAddress).setBytes(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", artworkId)),
            _artworkHash
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "limitedEdition", artworkId)), 
            _limitedEdition
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "editionNumber", artworkId)),
            _editionNumber
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "lastPrice", artworkId)), 
            _lastPrice
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareSchemeId", artworkId)),
            _profitShareSchemeId
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", artworkId)),
            _profitShareFromSecondarySale
        );

        SnarkStorage(_storageAddress).setString(
            keccak256(abi.encodePacked("artwork", "url", artworkId)), 
            _artworkUrl
        );

        return artworkId;
    }

    function addProfitShareScheme(
        address _storageAddress,
        address _schemeOwner,
        address[] _participants,
        uint256[] _profits
    )
        external
        returns (uint256 schemeId) 
    {
        schemeId = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfProfitShareSchemes")) + 1;
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfProfitShareSchemes"), schemeId);

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfParticipantsForProfitShareScheme", schemeId)), 
            _participants.length
        );

        for (uint256 i = 0; i < _participants.length; i++) {

            SnarkStorage(_storageAddress).setAddress(
                keccak256(abi.encodePacked("participantAddressForProfitShareScheme", schemeId, i)), 
                _participants[i]
            );

            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("participantProfitForProfitShareScheme", schemeId, i)), 
                _profits[i]
            );
        }

        uint256 numberOfSchemesForOwner = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", _schemeOwner)));

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", _schemeOwner)), 
            numberOfSchemesForOwner + 1
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("profitShareSchemeIdsForOwner", _schemeOwner, numberOfSchemesForOwner)),
            schemeId
        );
    }

    function addArtworkToArtistList(address _storageAddress, uint256 _artworkId, address _artistAddress) external {
        uint256 numberOfArtworks = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "numberOfArtworks", _artistAddress))
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artist", "artworkList", _artistAddress, numberOfArtworks)),
            _artworkId
        );

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artist", "numberOfArtworks", _artistAddress)),
            numberOfArtworks + 1
        );
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

    function getArtworkArtist(address _storageAddress, uint256 _artworkId) 
        external view returns (address artistAddress) 
    {
        return SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("artwork", "artist", _artworkId))
        );
    }

    function getArtworkLimitedEdition(address _storageAddress, uint256 _artworkId) external view 
        returns (uint256 limitedEdition) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "limitedEdition", _artworkId))
        );
    }

    function getArtworkEditionNumber(address _storageAddress, uint256 _artworkId) external view 
        returns (uint256 editionNumber) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "editionNumber", _artworkId))
        );
    }

    function getArtworkLastPrice(address _storageAddress, uint256 _artworkId) external view
        returns (uint256 lastPrice)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "lastPrice", _artworkId))
        );
    }

    function getArtworkHash(address _storageAddress, uint256 _artworkId) external view 
        returns (bytes32 artworkHash)
    {
        return SnarkStorage(_storageAddress).bytesStorage(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", _artworkId))
        );
    }

    function getArtworkProfitShareSchemeId(address _storageAddress, uint256 _artworkId) external view
        returns (uint256 profitShareSchemeId)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareSchemeId", _artworkId))
        );
    }

    function getArtworkProfitShareFromSecondarySale(address _storageAddress, uint256 _artworkId) external view
        returns (uint256 profitShare)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", _artworkId))
        );
    }

    function getArtworkURL(address _storageAddress, uint256 _artworkId) external view returns (string artworkUrl) {
        return SnarkStorage(_storageAddress).stringStorage(
            keccak256(abi.encodePacked("artwork", "url", _artworkId))
        );
    }

    function getArtwork(address _storageAddress, uint256 _artworkId) external view returns (
        address artistAddress, 
        bytes32 artworkHash,
        uint256 limitedEdition,
        uint256 editionNumber,
        uint256 lastPrice,
        uint256 profitShareSchemeId,
        uint256 profitShareFromSecondarySale,
        string artworkUrl) 
    {
        artistAddress = SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("artwork", "artist", _artworkId))
        );

        artworkHash = SnarkStorage(_storageAddress).bytesStorage(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", _artworkId))
        );

        limitedEdition = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "limitedEdition", _artworkId))
        );

        editionNumber = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "editionNumber", _artworkId))
        );

        lastPrice = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "lastPrice", _artworkId))
        );

        profitShareSchemeId = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareSchemeId", _artworkId))
        );

        profitShareFromSecondarySale = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", _artworkId))
        );

        artworkUrl = SnarkStorage(_storageAddress).stringStorage(
            keccak256(abi.encodePacked("artwork", "url", _artworkId))
        );
    }

    function getTotalNumberOfProfitShareSchemes(address _storageAddress) external view returns (uint256 number) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfProfitShareSchemes"));
    }

    function getNumberOfParticipantsForProfitShareScheme(address _storageAddress, uint256 _schemeId) external view 
        returns (uint256 number) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfParticipantsForProfitShareScheme", _schemeId))
        );
    }

    function getParticipantOfProfitShareScheme(address _storageAddress, uint256 _schemeId, uint256 _index) 
        external
        view
        returns (address participant, uint256 profit)
    {
        participant = SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("participantAddressForProfitShareScheme", _schemeId, _index)) 
        );

        profit = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("participantProfitForProfitShareScheme", _schemeId, _index))
        );
    }

    function getNumberOfProfitShareSchemesForOwner(address _storageAddress, address _schemeOwner) 
        external 
        view 
        returns (uint256 number)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", _schemeOwner)));
    }

    function getProfitShareSchemeIdForOwner(address _storageAddress, address _schemeOwner, uint256 _index)
        external
        view
        returns (uint256 schemeId)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("profitShareSchemeIdsForOwner", _schemeOwner, _index))
        );
    }

    function getNumberOfOwnerArtworks(address _storageAddress, address _artworkOwner) 
        external 
        view 
        returns (uint256 number) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _artworkOwner))
        );
    }

    function getArtworkIdOfOwner(address _storageAddress, address _artworkOwner, uint256 _index) 
        external 
        view
        returns (uint256 artworkId)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkOfOwner", _artworkOwner, _index))
        );
    }

    function getOwnerOfArtwork(address _storageAddress, uint256 _artworkId) 
        external 
        view 
        returns (address artworkOwner) 
    {
        return SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("ownerOfArtwork", _artworkId))
        );
    }

    function getNumberOfArtistArtworks(address _storageAddress, address _artistAddress)
        external
        view
        returns (uint256 number)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "numberOfArtworks", _artistAddress))
        );
    }

    function getArtworkIdForArtist(address _storageAddress, address _artistAddress, uint256 _index)
        external
        view
        returns (uint256 artworkId) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "artworkList", _artistAddress, _index))
        );
    }

    function getArtworkHashAsInUse(address _storageAddress, bytes32 _artworkHash) external view returns (bool isUsed) {
        return SnarkStorage(_storageAddress).boolStorage(keccak256(abi.encodePacked("hashIsUsed", _artworkHash)));
    }

    function getApprovalsToOperator(address _storageAddress, address _owner, address _operator) external view 
        returns (bool)
    {
        return SnarkStorage(_storageAddress).boolStorage(
            keccak256(abi.encodePacked("approvedOperator", _owner, _operator))
        );
    }
}