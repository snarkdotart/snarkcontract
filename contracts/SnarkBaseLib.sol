pragma solidity ^0.4.24;

import "./SnarkStorage.sol";


library SnarkBaseLib {

    /*** SET ***/
    function setSnarkWalletAddress(address storageAddress, address walletAddress) public {
        SnarkStorage(storageAddress).setAddress(keccak256("snarkWalletAddress"), walletAddress);
    }

    function setPlatformProfitShare(address storageAddress, uint256 platformProfitShare) public {
        SnarkStorage(storageAddress).setUint(keccak256("platformProfitShare"), platformProfitShare);
    }

    function setArtworkArtist(address storageAddress, uint256 artworkId, address artistAddress) public {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("artwork", "artist", artworkId)), 
            artistAddress
        );
    }

    function setArtworkLimitedEdition(address storageAddress, uint256 artworkId, uint256 limitedEdition) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "limitedEdition", artworkId)), 
            limitedEdition
        );
    }

    function setArtworkEditionNumber(address storageAddress, uint256 artworkId, uint256 editionNumber) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "editionNumber", artworkId)),
            editionNumber
        );
    }

    function setArtworkLastPrice(address storageAddress, uint256 artworkId, uint256 lastPrice) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "lastPrice", artworkId)), 
            lastPrice
        );
    }

    function setArtworkHash(address storageAddress, uint256 artworkId, bytes32 artworkHash) public {
        SnarkStorage(storageAddress).setBytes(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", artworkId)),
            artworkHash
        );
    }

    function setArtworkProfitShareSchemeId(address storageAddress, uint256 artworkId, uint256 schemeId) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareSchemeId", artworkId)),
            schemeId
        );
    }

    function setArtworkProfitShareFromSecondarySale(address storageAddress, uint256 artworkId, uint256 profitShare) 
        public 
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", artworkId)),
            profitShare
        );
    }

    function setArtworkURL(address storageAddress, uint256 artworkId, string url) public {
        SnarkStorage(storageAddress).setString(
            keccak256(abi.encodePacked("artwork", "url", artworkId)),
            url
        );
    }

    function setArtworkToOwner(address storageAddress, address artworkOwner, uint256 artworkId) public {
        uint256 _index = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", artworkOwner))
        ); 

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artworkOfOwner", artworkOwner, _index)),
            artworkId
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", artworkOwner)),
            _index + 1
        );
    }

    function setOwnerOfArtwork(address storageAddress, uint256 artworkId, address artworkOwner) public {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("ownerOfArtwork", artworkId)),
            artworkOwner
        );
    }

    function setArtworkHashAsInUse(address storageAddress, bytes32 artworkHash, bool isUsed) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("hashIsUsed", artworkHash)),
            isUsed
        );
    }

    function setApprovalsToOperator(
        address storageAddress, 
        address owner, 
        address operator, 
        bool isApproved
    ) 
        public 
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("approvedOperator", owner, operator)),
            isApproved
        );
    }

    function setApprovalsToArtwork(
        address storageAddress, 
        address owner, 
        uint256 artworkId, 
        bool isApproved
    ) 
        public 
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("approvalsToArtwork", owner, artworkId)),
            isApproved
        );
    }

    function setArtworkToParticipantApproving(
        address storageAddress, 
        uint256 artworkId, 
        address participant, 
        bool consent
    ) 
        public
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("artworkToParticipantApproving", artworkId, participant)),
            consent
        );
    }

    function setArtworkAcceptOfLoanRequestFromSnark(address storageAddress, uint256 artworkId, bool isAccept) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("artwork", "isArtworkAcceptOfLoanRequestFromSnark", artworkId)), isAccept);
    }

    function setArtworkAcceptOfLoanRequestFromOthers(address storageAddress, uint256 artworkId, bool isAccept) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("artwork", "isArtworkAcceptOfLoanRequestFromOthers", artworkId)), isAccept);
    }

    /*** DELETE ***/
    function deleteArtworkFromOwner(address storageAddress, address artworkOwner, uint256 index) public {
        uint256 maxIndex = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", artworkOwner))
        ) - 1;

        if (maxIndex != index) {
            uint256 artworkId = SnarkStorage(storageAddress).uintStorage(
                keccak256(abi.encodePacked("artworkOfOwner", artworkOwner, maxIndex))
            );

            SnarkStorage(storageAddress).setUint(
                keccak256(abi.encodePacked("artworkOfOwner", artworkOwner, index)),
                artworkId
            );
        }

        SnarkStorage(storageAddress).deleteUint(
            keccak256(abi.encodePacked("artworkOfOwner", artworkOwner, maxIndex))
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", artworkOwner)),
            maxIndex
        );
    }

    /*** ADD ***/
    function addArtwork(
        address storageAddress, 
        address artistAddress, 
        bytes32 artworkHash,
        uint256 limitedEdition,
        uint256 editionNumber,
        uint256 lastPrice,
        uint256 profitShareSchemeId,
        uint256 profitShareFromSecondarySale,
        string artworkUrl,
        bool isAcceptLoanRequestFromSnark,
        bool isAcceptLoanRequestFromOthers
    ) 
        public
        returns (uint256 artworkId)
    {
        artworkId = SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfArtworks")) + 1;
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfArtworks"), artworkId);
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("artwork", "artist", artworkId)), artistAddress);
        SnarkStorage(storageAddress).setBytes(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", artworkId)), artworkHash);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "limitedEdition", artworkId)), limitedEdition);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "editionNumber", artworkId)), editionNumber);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "lastPrice", artworkId)), lastPrice);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareSchemeId", artworkId)), profitShareSchemeId);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", artworkId)), 
            profitShareFromSecondarySale);
        SnarkStorage(storageAddress).setString(
            keccak256(abi.encodePacked("artwork", "url", artworkId)), artworkUrl);
        setArtworkAcceptOfLoanRequestFromSnark(storageAddress, artworkId, isAcceptLoanRequestFromSnark);
        setArtworkAcceptOfLoanRequestFromOthers(storageAddress, artworkId, isAcceptLoanRequestFromOthers);
    }

    function addProfitShareScheme(
        address storageAddress,
        address schemeOwner,
        address[] participants,
        uint256[] profits
    )
        public
        returns (uint256 schemeId) 
    {
        schemeId = SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfProfitShareSchemes")) + 1;
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfProfitShareSchemes"), schemeId);

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfParticipantsForProfitShareScheme", schemeId)), 
            participants.length
        );

        for (uint256 i = 0; i < participants.length; i++) {

            SnarkStorage(storageAddress).setAddress(
                keccak256(abi.encodePacked("participantAddressForProfitShareScheme", schemeId, i)), 
                participants[i]
            );

            SnarkStorage(storageAddress).setUint(
                keccak256(abi.encodePacked("participantProfitForProfitShareScheme", schemeId, i)), 
                profits[i]
            );
        }

        uint256 numberOfSchemesForOwner = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", schemeOwner)));

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", schemeOwner)), 
            numberOfSchemesForOwner + 1
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("profitShareSchemeIdsForOwner", schemeOwner, numberOfSchemesForOwner)),
            schemeId
        );
    }

    function addArtworkToArtistList(address storageAddress, uint256 artworkId, address artistAddress) public {
        uint256 numberOfArtworks = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "numberOfArtworks", artistAddress))
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artist", "artworkList", artistAddress, numberOfArtworks)),
            artworkId
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artist", "numberOfArtworks", artistAddress)),
            numberOfArtworks + 1
        );
    }

    function addPendingWithdrawals(address storageAddress, address owner, uint256 balance) public {
        uint256 currentBalance = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("pendingWithdrawals", owner)));

        uint256 sum = currentBalance + balance;
        assert(sum >= currentBalance);

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("pendingWithdrawals", owner)),
            sum
        );
    }

    function subPendingWithdrawals(address storageAddress, address owner, uint256 balance) public {
        uint256 currentBalance = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("pendingWithdrawals", owner)));

        assert(balance <= currentBalance);

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("pendingWithdrawals", owner)),
            currentBalance - balance
        );
    }

    function setSaleTypeToArtwork(address storageAddress, uint256 artworkId, uint256 saleType) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("saleTypeToArtwork", artworkId)),
            saleType
        );
    }

    function setSaleStatusToArtwork(address storageAddress, uint256 artworkId, uint256 saleStatus) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToArtwork", artworkId)),
            saleStatus
        );
    }

    /*** GET ***/
    function getSnarkWalletAddress(address storageAddress) public view returns (address walletAddress) {
        return SnarkStorage(storageAddress).addressStorage(keccak256("snarkWalletAddress"));
    }

    function getPlatformProfitShare(address storageAddress) public view returns (uint256 platformProfit) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("platformProfitShare"));
    }

    function getTotalNumberOfArtworks(address storageAddress) public view returns (uint256 numberOfArtworks) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfArtworks"));
    }

    function getArtworkArtist(address storageAddress, uint256 artworkId) 
        public view returns (address artistAddress) 
    {
        return SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("artwork", "artist", artworkId))
        );
    }

    function getArtworkLimitedEdition(address storageAddress, uint256 artworkId) public view 
        returns (uint256 limitedEdition) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "limitedEdition", artworkId))
        );
    }

    function getArtworkEditionNumber(address storageAddress, uint256 artworkId) public view 
        returns (uint256 editionNumber) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "editionNumber", artworkId))
        );
    }

    function getArtworkLastPrice(address storageAddress, uint256 artworkId) public view
        returns (uint256 lastPrice)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "lastPrice", artworkId))
        );
    }

    function getArtworkHash(address storageAddress, uint256 artworkId) public view 
        returns (bytes32 artworkHash)
    {
        return SnarkStorage(storageAddress).bytesStorage(
            keccak256(abi.encodePacked("artwork", "hashOfArtwork", artworkId))
        );
    }

    function getArtworkProfitShareSchemeId(address storageAddress, uint256 artworkId) public view
        returns (uint256 profitShareSchemeId)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareSchemeId", artworkId))
        );
    }

    function getArtworkProfitShareFromSecondarySale(address storageAddress, uint256 artworkId) public view
        returns (uint256 profitShare)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", artworkId))
        );
    }

    function getArtworkURL(address storageAddress, uint256 artworkId) public view returns (string artworkUrl) {
        return SnarkStorage(storageAddress).stringStorage(
            keccak256(abi.encodePacked("artwork", "url", artworkId))
        );
    }

    function isArtworkAcceptOfLoanRequestFromSnark(address storageAddress, uint256 artworkId) public view 
        returns (bool) 
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("artwork", "isArtworkAcceptOfLoanRequestFromSnark", artworkId)));
    }

    function isArtworkAcceptOfLoanRequestFromOthers(address storageAddress, uint256 artworkId) 
        public 
        view 
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("artwork", "isArtworkAcceptOfLoanRequestFromOthers", artworkId)));
    }

    function getArtworkDetails(address storageAddress, uint256 artworkId) 
        public 
        view 
        returns (
            address artistAddress, 
            bytes32 artworkHash,
            uint256 limitedEdition,
            uint256 editionNumber,
            uint256 lastPrice,
            uint256 profitShareSchemeId,
            uint256 profitShareFromSecondarySale,
            string artworkUrl,
            bool isAcceptOfLoanRequestFromSnark,
            bool isAcceptOfLoanRequestFromOthers
        )
    {
        artistAddress = getArtworkArtist(storageAddress, artworkId);
        artworkHash = getArtworkHash(storageAddress, artworkId);
        limitedEdition = getArtworkLimitedEdition(storageAddress, artworkId);
        editionNumber = getArtworkEditionNumber(storageAddress, artworkId);
        lastPrice = getArtworkLastPrice(storageAddress, artworkId);
        profitShareSchemeId = getArtworkProfitShareSchemeId(storageAddress, artworkId);
        profitShareFromSecondarySale = getArtworkProfitShareFromSecondarySale(storageAddress, artworkId);
        artworkUrl = getArtworkURL(storageAddress, artworkId);
        isAcceptOfLoanRequestFromSnark = isArtworkAcceptOfLoanRequestFromSnark(storageAddress, artworkId);
        isAcceptOfLoanRequestFromOthers = isArtworkAcceptOfLoanRequestFromOthers(storageAddress, artworkId);
    }

    function getTotalNumberOfProfitShareSchemes(address storageAddress) public view returns (uint256 number) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfProfitShareSchemes"));
    }

    function getNumberOfParticipantsForProfitShareScheme(address storageAddress, uint256 schemeId) 
        public 
        view 
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfParticipantsForProfitShareScheme", schemeId)));
    }

    function getParticipantOfProfitShareScheme(address storageAddress, uint256 schemeId, uint256 index) 
        public
        view
        returns (
            address participant, 
            uint256 profit
        )
    {
        participant = SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("participantAddressForProfitShareScheme", schemeId, index)) 
        );

        profit = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("participantProfitForProfitShareScheme", schemeId, index))
        );
    }

    function getNumberOfProfitShareSchemesForOwner(address storageAddress, address schemeOwner) 
        public 
        view 
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfProfitShareSchemesForOwner", schemeOwner)));
    }

    function getProfitShareSchemeIdForOwner(address storageAddress, address schemeOwner, uint256 index)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("profitShareSchemeIdsForOwner", schemeOwner, index)));
    }

    function getNumberOfOwnerArtworks(address storageAddress, address artworkOwner) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", artworkOwner)));
    }

    function getArtworkIdOfOwner(address storageAddress, address artworkOwner, uint256 index) 
        public 
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkOfOwner", artworkOwner, index)));
    }

    function getOwnerOfArtwork(address storageAddress, uint256 artworkId) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("ownerOfArtwork", artworkId)));
    }

    function getNumberOfArtistArtworks(address storageAddress, address artistAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "numberOfArtworks", artistAddress)));
    }

    function getArtworkIdForArtist(address storageAddress, address artistAddress, uint256 index)
        public
        view
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "artworkList", artistAddress, index)));
    }

    function getArtworkHashAsInUse(address storageAddress, bytes32 artworkHash) public view returns (bool) {
        return SnarkStorage(storageAddress).boolStorage(keccak256(abi.encodePacked("hashIsUsed", artworkHash)));
    }

    function getApprovalsToOperator(address storageAddress, address owner, address operator) 
        public 
        view 
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("approvedOperator", owner, operator)));
    }

    function getApprovalsToArtwork(address storageAddress, address owner, uint256 artworkId) 
        public 
        view
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("approvalsToArtwork", owner, artworkId)));
    }

    function getArtworkToParticipantApproving(address storageAddress, uint256 artworkId, address participant)
        public 
        view 
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("artworkToParticipantApproving", artworkId, participant)));
    }

    function getPendingWithdrawals(address storageAddress, address owner) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("pendingWithdrawals", owner)));
    }

    function getSaleTypeToArtwork(address storageAddress, uint256 artworkId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("saleTypeToArtwork", artworkId)));
    }

    function getSaleStatusToArtwork(address storageAddress, uint256 artworkId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("saleStatusToArtwork", artworkId)));
    }

}