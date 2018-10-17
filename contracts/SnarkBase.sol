/// @title Base contract for Snark. Holds all common structs, events and base variables.
/// @dev See the Snark contract documentation to understand how the contract is structured.
pragma solidity ^0.4.24;

import "./openzeppelin/Ownable.sol";
import "./openzeppelin/SafeMath.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";


contract SnarkBase is Ownable, SnarkDefinitions { 
    
    using SafeMath for uint256;
    using SnarkBaseLib for address;
    using SnarkCommonLib for address;

    /*** STORAGE ***/

    address private _storage;

    /*** EVENTS ***/

    /// @dev TokenCreatedEvent is executed when a new token is created.
    event TokenCreated(address indexed tokenOwner, uint256 tokenId);
    /// @dev Event occurs when profit share scheme is created.
    event ProfitShareSchemeAdded(address schemeOwner, uint256 profitShareSchemeId);
    /// @dev Event occurs when an artist wants to remove the profit share for secondary sale
    event NeedApproveProfitShareRemoving(address participant, uint256 tokenId);
    /// @dev Transfer event as defined in current draft of ERC721.
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    
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
    constructor(address storageAddress) public {
        _storage = storageAddress;
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

    function setTokenAcceptOfLoanRequestFromSnark(uint256 tokenId, bool isAccept) public onlyOwnerOf(tokenId) {
        _storage.setTokenAcceptOfLoanRequestFromSnark(tokenId, isAccept);
    }

    function setTokenAcceptOfLoanRequestFromOthers(uint256 tokenId, bool isAccept) public onlyOwnerOf(tokenId) {
        _storage.setTokenAcceptOfLoanRequestFromOthers(tokenId, isAccept);
    }

    function setTokenName(string tokenName) public onlyOwner {
        _storage.setTokenName(tokenName);
    }

    function setTokenSymbol(string tokenSymbol) public onlyOwner {
        _storage.setTokenSymbol(tokenSymbol);
    }

    /// @dev Create a scheme of profit share for user
    /// @param participants List of profit sharing participants
    /// @param percentAmount List of profit share % of participants
    /// @return A scheme id
    function createProfitShareScheme(address[] participants, uint256[] percentAmount) public returns(uint256) {
        require(participants.length == percentAmount.length);
        uint256 schemeId = _storage.addProfitShareScheme(msg.sender, participants, percentAmount);
        emit ProfitShareSchemeAdded(msg.sender, schemeId);
    }

    /// @dev Return a total number of profit share schemes
    function getProfitShareSchemesTotalCount() public view returns (uint256) {
        return _storage.getTotalNumberOfProfitShareSchemes();
    }

    /// @dev Return a total number of user's profit share schemes
    function getProfitShareSchemeCountByAddress() public view returns (uint256) {
        return _storage.getNumberOfProfitShareSchemesForOwner(msg.sender);
    }

    /// @dev Return a scheme Id for user by index
    /// @param index Index of scheme for current user's address
    function getProfitShareSchemeIdByIndex(uint256 index) public view returns (uint256) {
        return _storage.getProfitShareSchemeIdForOwner(msg.sender, index);
    }

    /// @dev Return a list of user profit share schemes
    /// @return A list of schemes belongs to owner
    function getProfitShareParticipantsCount() public view returns(uint256) {
        return _storage.getNumberOfProfitShareSchemesForOwner(msg.sender);
    }

    function getOwnerOfToken(uint256 tokenId) public view returns (address) {
        return _storage.getOwnerOfToken(tokenId);
    }

    /// @dev Function to add a new digital token to blockchain
    /// @param hashOfToken Unique hash of the token
    /// @param limitedEdition Number of token edititons
    /// @param profitShareForSecondarySale Profit share % during secondary sale
    ///        going back to the artist and their list of participants
    /// @param tokenUrl IPFS URL to digital work
    /// @param profitShareSchemeId Profit share scheme Id
    function addToken(
        bytes32 hashOfToken,
        uint8 limitedEdition,
        uint8 profitShareForSecondarySale,
        string tokenUrl,
        uint8 profitShareSchemeId,
        bool isAcceptOfLoanRequestFromSnark,
        bool isAcceptOfLoanRequestFromOthers
    ) 
        public
    {
        // Check for an identical hash of the digital token in existence to prevent uploading a duplicate token
        require(_storage.getTokenHashAsInUse(hashOfToken) == false);
        // Check that the number of token editions is >= 1
        require(limitedEdition >= 1);
        // Create the number of editions specified by the limitEdition
        for (uint8 i = 0; i < limitedEdition; i++) {
            uint256 tokenId = _storage.addToken(
                msg.sender,
                hashOfToken,
                limitedEdition,
                i + 1,
                0,
                profitShareSchemeId,
                profitShareForSecondarySale,
                tokenUrl,
                isAcceptOfLoanRequestFromSnark,
                isAcceptOfLoanRequestFromOthers
            );
            // set that a digital work with this hash has already been loaded
            _storage.setTokenHashAsInUse(hashOfToken, true);
            // Enter the new owner
            _storage.setOwnerOfToken(tokenId, msg.sender);
            // Add new token to new owner's token list
            _storage.addTokenToOwner(msg.sender, tokenId);
            // Add new token to new artist's token list
            _storage.addTokenToArtistList(tokenId, msg.sender);
            // Emit token event
            emit TokenCreated(msg.sender, tokenId);
        }
    }

    function getTokensCount() public view returns (uint256) {
        return _storage.getTotalNumberOfTokens();
    }

    function getTokensCountByArtist(address artist) public view returns (uint256) {
        return _storage.getNumberOfArtistTokens(artist);
    }

    function getTokensCountByOwner(address tokenOwner) public view returns (uint256) {
        return _storage.getOwnedTokensCount(tokenOwner);
    }

    function isTokenAcceptOfLoanRequestFromSnark(uint256 tokenId) public view returns (bool) {
        return _storage.isTokenAcceptOfLoanRequestFromSnark(tokenId);
    }

    function isTokenAcceptOfLoanRequestFromOthers(uint256 tokenId) public view returns (bool) {
        return _storage.isTokenAcceptOfLoanRequestFromOthers(tokenId);
    }
    
    // /// @dev Return details about token
    // /// @param tokenId Token Id of digital work
    function getTokenDetails(uint256 tokenId) 
        public 
        view 
        returns (
            address artist,
            bytes32 hashOfToken, 
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
        return _storage.getTokenDetails(tokenId);
    }

    /// @dev Change in profit sharing. Change can only be to the percentages for already registered wallet addresses.
    /// @param tokenId Token to which a change in profit sharing will be applied.
    /// @param newProfitShareSchemeId Id of profit share scheme
    function changeProfitShareSchemeForToken(
        uint256 tokenId,
        uint256 newProfitShareSchemeId
    ) 
        public
        onlyOwnerOf(tokenId) 
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
        msg.sender.transfer(balance);
    }

    function setSnarkWalletAddress(address snarkWalletAddr) public onlyOwner {
        _storage.setSnarkWalletAddress(snarkWalletAddr);
    }

    function setPlatformProfitShare(uint256 profit) public onlyOwner {
        _storage.setPlatformProfitShare(profit);
    }

    function getSnarkWalletAddressAndProfit() public view returns (address snarkWalletAddr, uint256 platformProfit) {
        snarkWalletAddr = _storage.getSnarkWalletAddress();
        platformProfit = _storage.getPlatformProfitShare();
    }

}
