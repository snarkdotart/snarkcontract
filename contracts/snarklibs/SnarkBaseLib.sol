pragma solidity ^0.4.24;

import "../SnarkStorage.sol";
import "../openzeppelin/SafeMath.sol";
import "../snarklibs/SnarkBaseExtraLib.sol";


library SnarkBaseLib {
    using SafeMath for uint256;
    using SnarkBaseExtraLib for address;

    /*** SET ***/
    function setSnarkWalletAddress(address storageAddress, address walletAddress) public {
        SnarkStorage(storageAddress).setAddress(keccak256("snarkWalletAddress"), walletAddress);
    }

    function setPlatformProfitShare(address storageAddress, uint256 platformProfitShare) public {
        SnarkStorage(storageAddress).setUint(keccak256("platformProfitShare"), platformProfitShare);
    }

    function setRestrictAccess(address storageAddress, bool isRestrict) public {
        SnarkStorage(storageAddress).setBool(keccak256("restrictedAccess"), isRestrict);
    }

    function setTokenName(address storageAddress, string tokenName) public {
        SnarkStorage(storageAddress).setString(keccak256("tokenName"), tokenName);
    }

    function setTokenSymbol(address storageAddress, string tokenSymbol) public {
        SnarkStorage(storageAddress).setString(keccak256("tokenSymbol"), tokenSymbol);
    }

    function setTokenArtist(address storageAddress, uint256 tokenId, address artistAddress) public {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("token", "artist", tokenId)), 
            artistAddress
        );
    }

    function setTokenLimitedEdition(address storageAddress, uint256 tokenId, uint256 limitedEdition) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "limitedEdition", tokenId)), 
            limitedEdition
        );
    }

    function setTokenEditionNumber(address storageAddress, uint256 tokenId, uint256 editionNumber) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "editionNumber", tokenId)),
            editionNumber
        );
    }

    function setTokenLastPrice(address storageAddress, uint256 tokenId, uint256 lastPrice) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "lastPrice", tokenId)), 
            lastPrice
        );
    }

    function setTokenHash(address storageAddress, uint256 tokenId, string tokenHash) public {
        SnarkStorage(storageAddress).setString(
            keccak256(abi.encodePacked("token", "hashOfToken", tokenId)),
            tokenHash
        );
    }

    function setTokenProfitShareSchemeId(address storageAddress, uint256 tokenId, uint256 schemeId) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "profitShareSchemeId", tokenId)),
            schemeId
        );
    }

    function setTokenProfitShareFromSecondarySale(address storageAddress, uint256 tokenId, uint256 profitShare) 
        public 
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "profitShareFromSecondarySale", tokenId)),
            profitShare
        );
    }

    function setTokenURL(address storageAddress, uint256 tokenId, string url) public {
        SnarkStorage(storageAddress).setString(
            keccak256(abi.encodePacked("token", "url", tokenId)),
            url
        );
    }

    function addTokenToOwner(address storageAddress, address tokenOwner, uint256 tokenId) public {
        uint256 _index = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenOfOwner", "numberOfOwnerTokens", tokenOwner))
        ); 

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenOfOwner", tokenOwner, _index)),
            tokenId
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenIndexOfOwner", tokenOwner, tokenId)),
            _index
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenOfOwner", "numberOfOwnerTokens", tokenOwner)),
            _index.add(1)
        );
    }

    function setOwnerOfToken(address storageAddress, uint256 tokenId, address tokenOwner) public {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("ownerOfToken", tokenId)),
            tokenOwner
        );
    }

    function setTokenHashAsInUse(address storageAddress, string tokenHash, bool isUsed) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("hashIsUsed", tokenHash)),
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

    function setApprovalsToToken(
        address storageAddress, 
        address owner, 
        uint256 tokenId, 
        address operator
    ) 
        public 
    {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("approvalsToToken", owner, tokenId)),
            operator
        );
    }

    function setTokenAcceptOfLoanRequestFromSnark(address storageAddress, uint256 tokenId, bool isAccept) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("token", "isTokenAcceptOfLoanRequestFromSnark", tokenId)), isAccept);
    }

    function setTokenAcceptOfLoanRequestFromOthers(address storageAddress, uint256 tokenId, bool isAccept) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("token", "isTokenAcceptOfLoanRequestFromOthers", tokenId)), isAccept);
    }

    /*** DELETE ***/
    function deleteTokenFromOwner(address storageAddress, address tokenOwner, uint256 index) public {
        uint256 oldTokenId = getTokenIdOfOwner(storageAddress, tokenOwner, index);
        uint256 maxIndex = getOwnedTokensCount(storageAddress, tokenOwner).sub(1);
        if (maxIndex != index) {
            uint256 tokenId = getTokenIdOfOwner(storageAddress, tokenOwner, maxIndex);
            SnarkStorage(storageAddress).setUint(
                keccak256(abi.encodePacked("tokenOfOwner", tokenOwner, index)),
                tokenId
            );
            SnarkStorage(storageAddress).setUint(
                keccak256(abi.encodePacked("tokenIndexOfOwner", tokenOwner, tokenId)),
                index
            );
        }
        SnarkStorage(storageAddress).deleteUint(
            keccak256(abi.encodePacked("tokenOfOwner", tokenOwner, maxIndex))
        );
        SnarkStorage(storageAddress).deleteUint(
            keccak256(abi.encodePacked("tokenIndexOfOwner", tokenOwner, oldTokenId))
        );
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenOfOwner", "numberOfOwnerTokens", tokenOwner)),
            maxIndex
        );
    }

    /*** ADD ***/
    function addToken(
        address storageAddress, 
        address artistAddress, 
        string tokenHash,
        uint256 limitedEdition,
        uint256 editionNumber,
        uint256 lastPrice,
        uint256 profitShareSchemeId,
        uint256 profitShareFromSecondarySale,
        string tokenUrl,
        bool isAcceptLoanRequestFromSnark,
        bool isAcceptLoanRequestFromOthers
    ) 
        public
        returns (uint256 tokenId)
    {
        tokenId = SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfTokens")) + 1;
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfTokens"), tokenId);
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("token", "artist", tokenId)), artistAddress);
        SnarkStorage(storageAddress).setString(
            keccak256(abi.encodePacked("token", "hashOfToken", tokenId)), tokenHash);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "limitedEdition", tokenId)), limitedEdition);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "editionNumber", tokenId)), editionNumber);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "lastPrice", tokenId)), lastPrice);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "profitShareSchemeId", tokenId)), profitShareSchemeId);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("token", "profitShareFromSecondarySale", tokenId)), 
            profitShareFromSecondarySale);
        SnarkStorage(storageAddress).setString(
            keccak256(abi.encodePacked("token", "url", tokenId)), tokenUrl);
        addArtistToList(storageAddress, artistAddress);
        setTokenAcceptOfLoanRequestFromSnark(storageAddress, tokenId, isAcceptLoanRequestFromSnark);
        setTokenAcceptOfLoanRequestFromOthers(storageAddress, tokenId, isAcceptLoanRequestFromOthers);
    }

    function addTokenToArtistList(address storageAddress, uint256 tokenId, address artistAddress) public {
        uint256 numberOfTokens = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "numberOfTokens", artistAddress))
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artist", "tokenList", artistAddress, numberOfTokens)),
            tokenId
        );

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artist", "numberOfTokens", artistAddress)),
            numberOfTokens.add(1)
        );
    }

    function addPendingWithdrawals(address storageAddress, address owner, uint256 balance) public {
        uint256 currentBalance = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("pendingWithdrawals", owner)));

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("pendingWithdrawals", owner)),
            currentBalance.add(balance)
        );
    }

    function subPendingWithdrawals(address storageAddress, address owner, uint256 balance) public {
        uint256 currentBalance = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("pendingWithdrawals", owner)));

        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("pendingWithdrawals", owner)),
            currentBalance.sub(balance)
        );
    }

    function setSaleTypeToToken(address storageAddress, uint256 tokenId, uint256 saleType) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("saleTypeToToken", tokenId)),
            saleType
        );
    }

    function setSaleStatusToToken(address storageAddress, uint256 tokenId, uint256 saleStatus) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToToken", tokenId)),
            saleStatus
        );
    }

    function setTokenDecryptionKey(address storageAddress, uint256 tokenId, string decryptionKey) public {
        SnarkStorage(storageAddress).setString(
            keccak256(abi.encodePacked("token", "decryptionKey", tokenId)),
            decryptionKey
        );
    }

    function addArtistToList(address storageAddress, address artist) public {
        if (!isArtistInList(storageAddress, artist)) {
            uint256 index = getNumberOfArtistsInList(storageAddress);
            setArtistToListByIndex(storageAddress, index, artist);
            increaseNumberOfArtistsInList(storageAddress);
            markArtistAsInList(storageAddress, artist);
        }
    }

    function markArtistAsInList(address storageAddress, address artist) public {
        SnarkStorage(storageAddress).setBool(keccak256(abi.encodePacked("isArtistInList", artist)), true);
    }

    function increaseNumberOfArtistsInList(address storageAddress) public {
        uint256 count = getNumberOfArtistsInList(storageAddress);
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("numberOfArtistsInList")), count.add(1));
    }

    function setArtistToListByIndex(address storageAddress, uint256 index, address artist) public {
        SnarkStorage(storageAddress).setAddress(keccak256(abi.encodePacked("listOfArtists", index)), artist);
    }

    /*** GET ***/
    function getSnarkWalletAddress(address storageAddress) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256("snarkWalletAddress"));
    }

    function getPlatformProfitShare(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("platformProfitShare"));
    }

    function isRestrictedAccess(address storageAddress) public view returns (bool) {
        return SnarkStorage(storageAddress).boolStorage(keccak256("restrictedAccess"));
    }

    function getTokenName(address storageAddress) public view returns (string) {
        return SnarkStorage(storageAddress).stringStorage(keccak256("tokenName"));
    }

    function getTokenSymbol(address storageAddress) public view returns (string) {
        return SnarkStorage(storageAddress).stringStorage(keccak256("tokenSymbol"));
    }

    function getTotalNumberOfTokens(address storageAddress) public view returns (uint256 numberOfTokens) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfTokens"));
    }

    function getTokenArtist(address storageAddress, uint256 tokenId) 
        public view returns (address artistAddress) 
    {
        return SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("token", "artist", tokenId))
        );
    }

    function getTokenLimitedEdition(address storageAddress, uint256 tokenId) public view 
        returns (uint256 limitedEdition) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("token", "limitedEdition", tokenId))
        );
    }

    function getTokenEditionNumber(address storageAddress, uint256 tokenId) public view 
        returns (uint256 editionNumber) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("token", "editionNumber", tokenId))
        );
    }

    function getTokenLastPrice(address storageAddress, uint256 tokenId) public view
        returns (uint256 lastPrice)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("token", "lastPrice", tokenId))
        );
    }

    function getTokenHash(address storageAddress, uint256 tokenId) public view 
        returns (string tokenHash)
    {
        return SnarkStorage(storageAddress).stringStorage(
            keccak256(abi.encodePacked("token", "hashOfToken", tokenId))
        );
    }

    function getTokenProfitShareFromSecondarySale(address storageAddress, uint256 tokenId)
        public
        view
        returns (uint256 profitShare)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("token", "profitShareFromSecondarySale", tokenId))
        );
    }

    function getTokenURL(address storageAddress, uint256 tokenId) public view returns (string tokenUrl) {
        return SnarkStorage(storageAddress).stringStorage(
            keccak256(abi.encodePacked("token", "url", tokenId))
        );
    }

    function isTokenAcceptOfLoanRequestFromSnark(address storageAddress, uint256 tokenId) public view 
        returns (bool) 
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("token", "isTokenAcceptOfLoanRequestFromSnark", tokenId)));
    }

    function isTokenAcceptOfLoanRequestFromOthers(address storageAddress, uint256 tokenId) 
        public 
        view 
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("token", "isTokenAcceptOfLoanRequestFromOthers", tokenId)));
    }

    function getTokenDetail(address storageAddress, uint256 tokenId) 
        public 
        view 
        returns (
            address currentOwner,
            address artistAddress, 
            string tokenHash,
            uint256 limitedEdition,
            uint256 editionNumber,
            uint256 lastPrice,
            uint256 profitShareSchemeId,
            uint256 profitShareFromSecondarySale,
            string tokenUrl,
            bool isAcceptOfLoanRequestFromSnark,
            bool isAcceptOfLoanRequestFromOthers
        )
    {
        currentOwner = getOwnerOfToken(storageAddress, tokenId);
        artistAddress = getTokenArtist(storageAddress, tokenId);
        tokenHash = getTokenHash(storageAddress, tokenId);
        limitedEdition = getTokenLimitedEdition(storageAddress, tokenId);
        editionNumber = getTokenEditionNumber(storageAddress, tokenId);
        lastPrice = getTokenLastPrice(storageAddress, tokenId);
        profitShareSchemeId = storageAddress.getTokenProfitShareSchemeId(tokenId);
        profitShareFromSecondarySale = getTokenProfitShareFromSecondarySale(storageAddress, tokenId);
        tokenUrl = getTokenURL(storageAddress, tokenId);
        isAcceptOfLoanRequestFromSnark = isTokenAcceptOfLoanRequestFromSnark(storageAddress, tokenId);
        isAcceptOfLoanRequestFromOthers = isTokenAcceptOfLoanRequestFromOthers(storageAddress, tokenId);
    }

    function getOwnedTokensCount(address storageAddress, address tokenOwner) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenOfOwner", "numberOfOwnerTokens", tokenOwner)));
    }

    function getTokenIdOfOwner(address storageAddress, address tokenOwner, uint256 index) 
        public 
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenOfOwner", tokenOwner, index)));
    }

    function getIndexOfOwnerToken(address storageAddress, address tokenOwner, uint256 tokenId)
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenIndexOfOwner", tokenOwner, tokenId))
        );
    }

    function getOwnerOfToken(address storageAddress, uint256 tokenId) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("ownerOfToken", tokenId)));
    }

    function getNumberOfArtistTokens(address storageAddress, address artistAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "numberOfTokens", artistAddress)));
    }

    function getTokenIdForArtist(address storageAddress, address artistAddress, uint256 index)
        public
        view
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artist", "tokenList", artistAddress, index)));
    }

    function getTokenHashAsInUse(address storageAddress, string tokenHash) public view returns (bool) {
        return SnarkStorage(storageAddress).boolStorage(keccak256(abi.encodePacked("hashIsUsed", tokenHash)));
    }

    function getApprovalsToOperator(address storageAddress, address owner, address operator) 
        public 
        view 
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("approvedOperator", owner, operator)));
    }

    function getApprovalsToToken(address storageAddress, address owner, uint256 tokenId) 
        public 
        view
        returns (address)
    {
        return SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("approvalsToToken", owner, tokenId)));
    }

    function getTokenToParticipantApproving(address storageAddress, uint256 tokenId, address participant)
        public 
        view 
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("tokenToParticipantApproving", tokenId, participant)));
    }

    function getPendingWithdrawals(address storageAddress, address owner) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("pendingWithdrawals", owner)));
    }

    function getSaleTypeToToken(address storageAddress, uint256 tokenId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("saleTypeToToken", tokenId)));
    }

    function getSaleStatusToToken(address storageAddress, uint256 tokenId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("saleStatusToToken", tokenId)));
    }

    function getTokenDecryptionKey(address storageAddress, uint256 tokenId) public view returns (string) {
        return SnarkStorage(storageAddress).stringStorage(
            keccak256(abi.encodePacked("token", "decryptionKey", tokenId))
        );
    }

    function isArtistInList(address storageAddress, address artist) public view returns (bool) {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("isArtistInList", artist))
        );
    }

    function getNumberOfArtistsInList(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("numberOfArtistsInList")));
    }

    function getArtistToListByIndex(address storageAddress, uint256 index) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("listOfArtists", index)));
    }

    function getListOfAllArtists(address storageAddress) public view returns (address[]) {
        uint256 countOfArtists = getNumberOfArtistsInList(storageAddress);
        address[] memory listOfArtists = new address[](countOfArtists);
        for (uint256 i = 0; i < countOfArtists; i++) {
            listOfArtists[i] = getArtistToListByIndex(storageAddress, i);
        }
        return listOfArtists;
    }
}