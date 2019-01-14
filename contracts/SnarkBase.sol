/// @title Base contract for Snark. Holds all common structs, events and base variables.
/// @dev See the Snark contract documentation to understand how the contract is structured.
pragma solidity ^0.4.25;

import "./openzeppelin/Ownable.sol";
import "./openzeppelin/SafeMath.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseExtraLib.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";


contract SnarkBase is Ownable, SnarkDefinitions { 
    
    using SafeMath for uint256;
    using SnarkBaseExtraLib for address;
    using SnarkBaseLib for address;
    using SnarkCommonLib for address;

    /*** STORAGE ***/

    address private _storage;
    address private _erc721;

    /*** EVENTS ***/

    /// @dev TokenCreatedEvent is executed when a new token is created.
    event TokenCreated(address indexed tokenOwner, string hashOfToken, uint256 tokenId);
    /// @dev Event occurs when profit share scheme is created.
    event ProfitShareSchemeAdded(address indexed schemeOwner, uint256 profitShareSchemeId);
    /// @dev Event occurs when an artist wants to remove the profit share for secondary sale
    event NeedApproveProfitShareRemoving(address indexed participant, uint256 tokenId);
    
    modifier restrictedAccess() {
        if (_storage.isRestrictedAccess()) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }

    /// @dev Modifier that checks that an owner has a specific token
    /// @param tokenId Token ID
    modifier onlyOwnerOf(uint256 tokenId) {
        require(msg.sender == _storage.getOwnerOfToken(tokenId));
        _;
    }

    /// @dev Modifier that checks that an owner possesses multiple tokens
    /// @param tokenIds Array of token IDs
    modifier onlyOwnerOfMany(uint256[] tokenIds) {
        bool isOwnerOfAll = true;
        for (uint8 i = 0; i < tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && 
                (msg.sender == _storage.getOwnerOfToken(tokenIds[i]));
        }
        require(isOwnerOfAll);
        _;
    }
    
    /// @dev Modifier that only allows the artist to do an operation
    /// @param tokenId Token Id
    modifier onlyArtistOf(uint256 tokenId) {
        address artist = _storage.getTokenArtist(tokenId);
        require(msg.sender == artist);
        _;
    }

    modifier onlyProfitShareSchemeOfOwner(uint256 tokenId, uint256 schemeId) {
        require(schemeId > 0, "id of scheme can't be zero");
        
        address artist = _storage.getTokenArtist(tokenId);
        require(msg.sender == artist, "Only artist can change the profit share scheme");

        bool isSchemeOwner = false;
        uint256 schemeNumber = getNumberOfProfitShareSchemesForOwner(artist);        
        for (uint256 i = 0; i < schemeNumber; i++) {
            uint256 schId = getProfitShareSchemeIdForOwner(artist, i);
            isSchemeOwner = isSchemeOwner || (schId == schemeId);
        }
        require(isSchemeOwner == true, "Profit share scheme is not your");
        _;
    }

    /// @dev Modifier that allows access for a participant only
    modifier onlyParticipantOf(uint256 tokenId) {
        bool isItParticipant = false;
        uint256 schemeId = _storage.getTokenProfitShareSchemeId(tokenId);
        uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(schemeId);
        address participant;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _storage.getParticipantOfProfitShareScheme(schemeId, i);
            if (msg.sender == participant) { 
                isItParticipant = true; 
                break; 
            }
        }
        require(isItParticipant);
        _;
    }

    /// @dev Constructor of contract
    /// @param storageAddress Address of a storage contract
    /// @param erc721Address Address of a ERC721 contract
    constructor(address storageAddress, address erc721Address) public {
        _storage = storageAddress;
        _erc721 = erc721Address;
    }

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    /// @dev Generate event to get approval from each participant of the token
    /// @param tokenId Id of token
    function sendRequestForApprovalOfProfitShareRemovalForSecondarySale(uint tokenId) external onlyArtistOf(tokenId) {
        uint256 schemeId = _storage.getTokenProfitShareSchemeId(tokenId);
        uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(schemeId);
        address participant;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _storage.getParticipantOfProfitShareScheme(schemeId, i);
            _storage.setTokenToParticipantApproving(tokenId, participant, false);
            emit NeedApproveProfitShareRemoving(participant, tokenId);
        }
    }

    /// @dev Delete profit share from secondary sale
    /// @param tokenId Token Id
    function approveRemovingProfitShareFromSecondarySale(uint256 tokenId) external onlyParticipantOf(tokenId) {
        _storage.setTokenToParticipantApproving(tokenId, msg.sender, true);
        uint256 schemeId = _storage.getTokenProfitShareSchemeId(tokenId);
        uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(schemeId);
        address participant;
        bool isApproved = true;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _storage.getParticipantOfProfitShareScheme(schemeId, i);
            isApproved = isApproved && _storage.getTokenToParticipantApproving(tokenId, participant);
        }
        if (isApproved) _storage.setTokenProfitShareFromSecondarySale(tokenId, 0);
    }

    function setTokenAcceptOfLoanRequestFromSnarkAndOthers(
        uint256 tokenId, 
        bool isAcceptForSnark, 
        bool isAcceptForOthers
    ) 
        public 
    {
        require(msg.sender == owner || msg.sender == _storage.getOwnerOfToken(tokenId));
        _storage.setTokenAcceptOfLoanRequestFromSnark(tokenId, isAcceptForSnark);
        _storage.setTokenAcceptOfLoanRequestFromOthers(tokenId, isAcceptForOthers);
    }

    function setTokenName(string tokenName) public onlyOwner {
        _storage.setTokenName(tokenName);
    }

    function setTokenSymbol(string tokenSymbol) public onlyOwner {
        _storage.setTokenSymbol(tokenSymbol);
    }

    function changeRestrictAccess(bool isRestrict) public onlyOwner {
        _storage.setRestrictAccess(isRestrict);
    }

    /// @dev Create a scheme of profit share for user
    /// @param participants List of profit sharing participants
    /// @param percentAmount List of profit share % of participants
    /// @return A scheme id
    function createProfitShareScheme(address artistAddress, address[] participants, uint256[] percentAmount)
        public
        restrictedAccess
        returns(uint256)
    {
        require(participants.length == percentAmount.length);
        require(participants.length <= 5);
        uint256 sum = 0;
        for (uint i = 0; i < percentAmount.length; i++) {
            require(percentAmount[i] > 0, "Percent value has to be greater than zero");
            sum = sum.add(percentAmount[i]);
        }
        require(sum == 100, "Sum of all percentages has to be equal 100");
        uint256 schemeId = _storage.addProfitShareScheme(artistAddress, participants, percentAmount);
        emit ProfitShareSchemeAdded(artistAddress, schemeId);
    }

    /// @dev Return a total number of profit share schemes
    function getProfitShareSchemesTotalCount() public view returns (uint256) {
        return _storage.getTotalNumberOfProfitShareSchemes();
    }

    /// @dev Return a total number of user's profit share schemes
    function getProfitShareSchemeCountByAddress(address schemeOwner) public view onlyOwner returns (uint256) {
        return _storage.getNumberOfProfitShareSchemesForOwner(schemeOwner);
    }

    /// @dev Return a scheme Id for user by index
    /// @param index Index of scheme for current user's address
    function getProfitShareSchemeIdByIndex(address schemeOwner, uint256 index) public view onlyOwner returns (uint256) {
        return _storage.getProfitShareSchemeIdForOwner(schemeOwner, index);
    }

    /// @dev Return a list of user profit share schemes
    /// @return A list of schemes belongs to owner
    function getProfitShareParticipantsCount(address schemeOwner) public view onlyOwner returns(uint256) {
        return _storage.getNumberOfUniqueParticipantsForOwner(schemeOwner);
    }

    /// @dev Return a list of unique profit share participants
    function getProfitShareParticipantsList(address schemeOwner) public view onlyOwner returns (address[]) {
        return _storage.getListOfUniqueParticipantsForOwner(schemeOwner);
    }

    function getOwnerOfToken(uint256 tokenId) public view returns (address) {
        return _storage.getOwnerOfToken(tokenId);
    }

    /// @dev Function to add a new digital token to blockchain. Only Snark can call this function.
    /// @param artistAddress Address of artist
    /// @param hashOfToken Unique hash of the token
    /// @param tokenUrl IPFS URL to digital work
    /// @param decorationUrl IPFS URL to json decoration file
    /// @param decriptionKey Decription key for digital work
    /// @param limitedEditionProfitSFSSProfitSSID Array of 3 variables: 
    ///         0 - Number of token edititons,
    ///         1 - Profit share % during secondary sale, going back to the artist and their list of participants
    ///         2 - Profit share scheme Id,
    /// @param isAcceptOfLoanRequestFromSnarkFromOthers sign of auto accept of requests from Snark and other users
    function addToken(
        address artistAddress,
        string hashOfToken,
        string tokenUrl,
        string decorationUrl,
        string decriptionKey,
        uint256[] limitedEditionProfitSFSSProfitSSID,
        bool[] isAcceptOfLoanRequestFromSnarkFromOthers
    ) 
        public
        restrictedAccess
    {
        // check if profitShareSchemeId belongs to artistAddress
        require(_storage.doesProfitShareSchemeIdBelongsToOwner(
                artistAddress, limitedEditionProfitSFSSProfitSSID[2]) == true,
            "Artist has to have the profit share schemeId");
        // Check for an identical hash of the digital token in existence to prevent uploading a duplicate token
        require(_storage.getTokenHashAsInUse(hashOfToken) == false, 
            "Token is already exist with the same hash"
        );
        // Check that the number of token editions is >= 1 and <= 10
        // otherwise there is a chance to spend all the Gas
        require(limitedEditionProfitSFSSProfitSSID[0] >= 1 && limitedEditionProfitSFSSProfitSSID[0] <= 25,
            "Limited edition should be less or equal 25"
        );
        require(limitedEditionProfitSFSSProfitSSID[1] <= 100, 
            "Profit Share for secondary sale has to be less or equal 100"
        );
        // Create the number of editions specified by the limitEdition
        uint256[] memory lEeNlPpSSIDpSFSS = new uint256[](5);
        for (uint8 i = 0; i < limitedEditionProfitSFSSProfitSSID[0]; i++) {
            lEeNlPpSSIDpSFSS[0] = limitedEditionProfitSFSSProfitSSID[0];    // limitedEdition
            lEeNlPpSSIDpSFSS[1] = i + 1;                                    // editionNumber
            lEeNlPpSSIDpSFSS[2] = 0;                                        // lastPrice
            lEeNlPpSSIDpSFSS[3] = limitedEditionProfitSFSSProfitSSID[2];    // profitShareSchemeId
            lEeNlPpSSIDpSFSS[4] = limitedEditionProfitSFSSProfitSSID[1];    // profitShareForSecondarySale

            uint256 tokenId = _storage.addToken(
                artistAddress,                                              // artistAddress
                hashOfToken,                                                // tokenHash
                lEeNlPpSSIDpSFSS,
                tokenUrl,                                                   // tokenUrl
                isAcceptOfLoanRequestFromSnarkFromOthers
            );
            // set that a digital work with this hash has already been loaded
            _storage.setTokenHashAsInUse(hashOfToken, true);
            // Add new token to new artist's token list
            _storage.addTokenToArtistList(tokenId, artistAddress);
            // Set a decription key for original file of token
            _storage.setTokenDecryptionKey(tokenId, decriptionKey);
            // Set a url for token decoration on OpenSea platform
            _storage.setDecorationUrl(tokenId, decorationUrl);
            // Enter the new owner
            _storage.setOwnerOfToken(tokenId, artistAddress);
            // Add new token to new owner's token list
            _storage.addTokenToOwner(artistAddress, tokenId);
            // emit token event
            emit TokenCreated(artistAddress, hashOfToken, tokenId);
            // emit transfer token event
            _erc721.echoTransfer(address(0), artistAddress, tokenId);
        }
    }

    function getTokenDecryptionKey(uint256 tokenId) public view returns (string) {
        require(
            msg.sender == _storage.getOwnerOfToken(tokenId) ||
            msg.sender == owner
        );
        return _storage.getTokenDecryptionKey(tokenId);
    }

    function getTokensCount() public view returns (uint256) {
        return _storage.getTotalNumberOfTokens();
    }

    function getTokensCountByArtist(address artist) public view returns (uint256) {
        return _storage.getNumberOfArtistTokens(artist);
    }

    function getTokenListForArtist(address artist) public view returns (uint256[]) {
        uint256 _count = _storage.getNumberOfArtistTokens(artist);
        uint256[] memory _retarray = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _retarray[i] = _storage.getTokenIdForArtist(artist, i);
        }
        return _retarray;
    }

    function getTokensCountByOwner(address tokenOwner) public view returns (uint256) {
        return _storage.getOwnedTokensCount(tokenOwner);
    }

    function getTokenListForOwner(address tokenOwner) public view returns (uint256[]) {
        uint256 _count = _storage.getOwnedTokensCount(tokenOwner);
        uint256[] memory _retarray = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _retarray[i] = _storage.getTokenIdOfOwner(tokenOwner, i);
        }
        return _retarray;
    }

    function isTokenAcceptOfLoanRequestFromSnarkAndOthers(uint256 tokenId) public view returns (bool, bool) {
        return (
            _storage.isTokenAcceptOfLoanRequestFromSnark(tokenId),
            _storage.isTokenAcceptOfLoanRequestFromOthers(tokenId)
        );
    }

    // /// @dev Return details about token
    // /// @param tokenId Token Id of digital work
    function getTokenDetail(uint256 tokenId) 
        public 
        view 
        returns (
            address currentOwner,
            address artist,
            string hashOfToken, 
            uint256 limitedEdition, 
            uint256 editionNumber, 
            uint256 lastPrice,
            uint256 profitShareSchemeId,
            uint256 profitShareFromSecondarySale, 
            string tokenUrl,
            string decorationUrl,
            bool isAcceptOfLoanRequestFromSnark,
            bool isAcceptOfLoanRequestFromOthers
        ) 
    {
        return _storage.getTokenDetail(tokenId);
    }

    /// @dev Change in profit sharing. Change can only be to the percentages for already registered wallet addresses.
    /// @param tokenId Token to which a change in profit sharing will be applied.
    /// @param newProfitShareSchemeId Id of profit share scheme
    function changeProfitShareSchemeForToken(
        uint256 tokenId,
        uint256 newProfitShareSchemeId
    ) 
        public
        onlyProfitShareSchemeOfOwner(tokenId, newProfitShareSchemeId)
    {
        _storage.setTokenProfitShareSchemeId(tokenId, newProfitShareSchemeId);
    }
    
    /// @dev Function to view the balance in our contract that an owner can withdraw 
    function getWithdrawBalance(address tokenOwner) public view returns (uint256) {
        return _storage.getPendingWithdrawals(tokenOwner);
    }

    /// @dev Return number of particpants
    function getNumberOfParticipantsForProfitShareScheme(uint256 schemeId) public view returns (uint256) {
        return _storage.getNumberOfParticipantsForProfitShareScheme(schemeId);
    }

    /// @dev Function returns a participant address and its profit
    /// @param schemeId Id of Profit Share Scheme
    /// @param index index of element in array of ProfitShareSchemes
    function getParticipantOfProfitShareScheme(uint256 schemeId, uint256 index) 
        public 
        view 
        returns (address, uint256) 
    {
        return _storage.getParticipantOfProfitShareScheme(schemeId, index);
    }

    /// @dev Function to withdraw funds to the owners wallet 
    function withdrawFunds() public {
        uint256 balance = _storage.getPendingWithdrawals(msg.sender);
        require(balance > 0);
        _storage.subPendingWithdrawals(msg.sender, balance);
        SnarkStorage(_storage).transferFunds(msg.sender, balance);
    }

    function setSnarkWalletAddress(address snarkWalletAddr) public onlyOwner {
        _storage.setSnarkWalletAddress(snarkWalletAddr);
    }

    function setPlatformProfitShare(uint256 profit) public onlyOwner {
        _storage.setPlatformProfitShare(profit);
    }

    function changeTokenData(
        uint256 tokenId,
        string hashOfToken,
        string tokenUrl,
        string decorationUrl,
        string decriptionKey
    ) 
        public 
        onlyOwner 
    {
        SnarkStorage(_storage).setString(
            keccak256(abi.encodePacked("token", "hashOfToken", tokenId)), hashOfToken);
        SnarkStorage(_storage).setString(
            keccak256(abi.encodePacked("token", "url", tokenId)), tokenUrl);

        _storage.setDecorationUrl(tokenId, decorationUrl);
        _storage.setTokenDecryptionKey(tokenId, decriptionKey);
    }

    function getSnarkWalletAddressAndProfit() public view returns (address snarkWalletAddr, uint256 platformProfit) {
        snarkWalletAddr = _storage.getSnarkWalletAddress();
        platformProfit = _storage.getPlatformProfitShare();
    }

    function getPlatformProfitShare() public view returns (uint256) {
        return _storage.getPlatformProfitShare();
    }

    function getSaleTypeToToken(uint256 tokenId) public view returns (uint256) {
        return _storage.getSaleTypeToToken(tokenId);
    }

    function getTokenHashAsInUse(string tokenHash) public view returns (bool) {
        return _storage.getTokenHashAsInUse(tokenHash);
    }

    function getNumberOfProfitShareSchemesForOwner(address schemeOwner) public view returns (uint256) {
        return _storage.getNumberOfProfitShareSchemesForOwner(schemeOwner);
    }

    function getProfitShareSchemeIdForOwner(address schemeOwner, uint256 index)
        public
        view
        returns (uint256)
    {
        return _storage.getProfitShareSchemeIdForOwner(schemeOwner, index);
    }

    function getListOfAllArtists() public view returns (address[]) {
        return _storage.getListOfAllArtists();
    }
}
