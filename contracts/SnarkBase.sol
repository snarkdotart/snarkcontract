/// @title Base contract for Snark. Holds all common structs, events and base variables.
/// @dev See the Snark contract documentation to understand how the various contract facets are arranged.
pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./SnarkDefinitions.sol";
import "./SnarkBaseLib.sol";
import "./SnarkCommonLib.sol";


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
        require(msg.sender == _storage.getOwnerOfArtwork(tokenId));
        _;
    }

    /// @dev Modifier that checks that an owner possesses multiple tokens
    /// @param tokenIds Array of token IDs
    modifier onlyOwnerOfMany(uint256[] tokenIds) {
        bool isOwnerOfAll = true;
        for (uint8 i = 0; i < tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && 
                (msg.sender == _storage.getOwnerOfArtwork(tokenIds[i]));
        }
        require(isOwnerOfAll);
        _;
    }

    /// @dev Modifier that allows do an operation by an artist only
    /// @param tokenId Artwork Id
    modifier onlyArtistOf(uint256 tokenId) {
        address artist = _storage.getArtworkArtist(tokenId);
        require(msg.sender == artist);
        _;
    }

    /// @dev Modifier that allows access for a participant only
    modifier onlyParticipantOf(uint256 tokenId) {
        bool isItParticipant = false;
        uint256 schemeId = _storage.getArtworkProfitShareSchemeId(tokenId);
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

    /// @dev Generating event to approval from each participant of token
    /// @param tokenId Id of artwork
    function sendRequestForApprovalOfProfitShareRemovalForSecondarySale(uint tokenId) external onlyArtistOf(tokenId) {
        uint256 schemeId = _storage.getArtworkProfitShareSchemeId(tokenId);
        uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(schemeId);
        address participant;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _storage.getParticipantOfProfitShareScheme(schemeId, i);
            _storage.setArtworkToParticipantApproving(tokenId, participant, false);
            emit NeedApproveProfitShareRemoving(participant, tokenId);
        }
    }

    /// @dev Delete a profit share from secondary sale
    /// @param tokenId Token Id
    function approveRemovingProfitShareFromSecondarySale(uint256 tokenId) external onlyParticipantOf(tokenId) {
        _storage.setArtworkToParticipantApproving(tokenId, msg.sender, true);
        uint256 schemeId = _storage.getArtworkProfitShareSchemeId(tokenId);
        uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(schemeId);
        address participant;
        bool isApproved = true;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _storage.getParticipantOfProfitShareScheme(schemeId, i);
            isApproved = isApproved && _storage.getArtworkToParticipantApproving(tokenId, participant);
        }
        if (isApproved) _storage.setArtworkProfitShareFromSecondarySale(tokenId, 0);
    }

    function setArtworkAcceptOfLoanRequestFromSnark(uint256 tokenId, bool isAccept) public onlyOwnerOf(tokenId) {
        _storage.setArtworkAcceptOfLoanRequestFromSnark(tokenId, isAccept);
    }

    function setArtworkAcceptOfLoanRequestFromOthers(uint256 tokenId, bool isAccept) public onlyOwnerOf(tokenId) {
        _storage.setArtworkAcceptOfLoanRequestFromOthers(tokenId, isAccept);
    }

    /// @dev Create a scheme of profit share for user
    /// @param participants List of profit sharing participants
    /// @param percentAmount List of profit share % of participants
    /// @return A scheme id
    function createProfitShareScheme(address[] participants, uint256[] percentAmount) public returns(uint256) {
        require(participants.length == percentAmount.length);
        uint256 schemeId = _storage.addProfitShareScheme(msg.sender, participants, percentAmount);
        // нужно ли хранить связь id схемы с владельцем, для быстрого получения адреса владельца по id схемы???
        // _storage.addaddressToProfitShareSchemesMap(msg.sender, schemeId);
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

    /// @dev Return a scheme Id for user by an index
    /// @param index Index of scheme for current user's address
    function getProfitShareSchemeIdByIndex(uint256 index) public view returns (uint256) {
        return _storage.getProfitShareSchemeIdForOwner(msg.sender, index);
    }

    /// @dev Return a list of user profit share schemes
    /// @return A list of schemes belongs to owner
    function getProfitShareParticipantsCount() public view returns(uint256) {
        return _storage.getNumberOfProfitShareSchemesForOwner(msg.sender);
    }

    function getOwnerOfArtwork(uint256 artworkId) public view returns (address) {
        return _storage.getOwnerOfArtwork(artworkId);
    }

    /// @dev Function to add a new digital artwork to blockchain
    /// @param hashOfArtwork Unique hash of the artwork
    /// @param limitedEdition Number of artwork edititons
    /// @param profitShareForSecondarySale Profit share % during secondary sale
    ///        going back to the artist and their list of participants
    /// @param artworkUrl IPFS URL to digital work
    /// @param profitShareSchemeId Profit share scheme Id
    function addArtwork(
        bytes32 hashOfArtwork,
        uint8 limitedEdition,
        uint8 profitShareForSecondarySale,
        string artworkUrl,
        uint8 profitShareSchemeId,
        bool isAcceptOfLoanRequestFromSnark,
        bool isAcceptOfLoanRequestFromOthers
    ) 
        public
    {
        // Check for an identical hash of the digital artwork in existence to prevent uploading a duplicate artwork
        require(_storage.getArtworkHashAsInUse(hashOfArtwork) == false);
        // Check that the number of artwork editions is >= 1
        require(limitedEdition >= 1);
        // Create the number of editions specified by the limitEdition
        for (uint8 i = 0; i < limitedEdition; i++) {
            uint256 tokenId = _storage.addArtwork(
                msg.sender,
                hashOfArtwork,
                limitedEdition,
                i + 1,
                0,
                profitShareSchemeId,
                profitShareForSecondarySale,
                artworkUrl,
                isAcceptOfLoanRequestFromSnark,
                isAcceptOfLoanRequestFromOthers
            );
            // memoraze that a digital work with this hash already loaded
            _storage.setArtworkHashAsInUse(hashOfArtwork, true);
            // Enter the new owner
            _storage.setOwnerOfArtwork(tokenId, msg.sender);
            // Add new token to new owner's token list
            _storage.setArtworkToOwner(msg.sender, tokenId);
            // Add new token to new artist's token list
            _storage.addArtworkToArtistList(tokenId, msg.sender);
            // Emit token event
            emit TokenCreated(msg.sender, tokenId);
        }
    }

    function getTokensCount() public view returns (uint256) {
        return _storage.getTotalNumberOfArtworks();
    }

    function getTokensCountByArtist(address artist) public view returns (uint256) {
        return _storage.getNumberOfArtistArtworks(artist);
    }

    function getTokensCountByOwner(address tokenOwner) public view returns (uint256) {
        return _storage.getNumberOfOwnerArtworks(tokenOwner);
    }

    function isArtworkAcceptOfLoanRequestFromSnark(uint256 artworkId) public view returns (bool) {
        return _storage.isArtworkAcceptOfLoanRequestFromSnark(artworkId);
    }

    function isArtworkAcceptOfLoanRequestFromOthers(uint256 artworkId) public view returns (bool) {
        return _storage.isArtworkAcceptOfLoanRequestFromOthers(artworkId);
    }
    
    // /// @dev Return details about token
    // /// @param tokenId Token Id of digital work
    function getTokenDetails(uint256 tokenId) 
        public 
        view 
        returns (
            address artist,
            bytes32 hashOfArtwork, 
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
        return _storage.getArtworkDetails(tokenId);
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
        _storage.setArtworkProfitShareSchemeId(tokenId, newProfitShareSchemeId);
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