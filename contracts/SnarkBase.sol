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
    event TokenCreated(address indexed _owner, uint256 _tokenId);
    /// @dev Event occurs when profit share scheme is created.
    event ProfitShareSchemeAdded(address _schemeOwner, uint256 _profitShareSchemeId);
    /// @dev Event occurs when an artist wants to remove the profit share for secondary sale
    event NeedApproveProfitShareRemoving(address _participant, uint256 _tokenId);
    /// @dev Transfer event as defined in current draft of ERC721.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    
    /// @dev Modifier that checks that an owner has a specific token
    /// @param _tokenId Token ID
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == _storage.getOwnerOfArtwork(_tokenId));
        _;
    }

    /// @dev Modifier that checks that an owner possesses multiple tokens
    /// @param _tokenIds Array of token IDs
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isOwnerOfAll = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && 
                (msg.sender == _storage.getOwnerOfArtwork(_tokenIds[i]));
        }
        require(isOwnerOfAll);
        _;
    }

    /// @dev Modifier that allows do an operation by an artist only
    /// @param _tokenId Artwork Id
    modifier onlyArtistOf(uint256 _tokenId) {
        address artist = _storage.getArtworkArtist(_tokenId);
        require(msg.sender == artist);
        _;
    }

    /// @dev Modifier that allows access for a participant only
    modifier onlyParticipantOf(uint256 _tokenId) {
        bool isItParticipant = false;
        uint256 schemeId = _storage.getArtworkProfitShareSchemeId(_tokenId);
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
    /// @param _storageAddress Address of a storage contract
    constructor(address _storageAddress) public {
        _storage = _storageAddress;
    }

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    /// @dev Generating event to approval from each participant of token
    /// @param _tokenId Id of artwork
    function sendRequestForApprovalOfProfitShareRemovalForSecondarySale(uint _tokenId) external onlyArtistOf(_tokenId) {
        uint256 schemeId = _storage.getArtworkProfitShareSchemeId(_tokenId);
        uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(schemeId);
        address participant;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _storage.getParticipantOfProfitShareScheme(schemeId, i);
            _storage.setArtworkToParticipantApproving(_tokenId, participant, false);
            emit NeedApproveProfitShareRemoving(participant, _tokenId);
        }
    }

    /// @dev Delete a profit share from secondary sale
    /// @param _tokenId Token Id
    function approveRemovingProfitShareFromSecondarySale(uint256 _tokenId) external onlyParticipantOf(_tokenId) {
        _storage.setArtworkToParticipantApproving(_tokenId, msg.sender, true);
        uint256 schemeId = _storage.getArtworkProfitShareSchemeId(_tokenId);
        uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(schemeId);
        address participant;
        bool isApproved = true;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _storage.getParticipantOfProfitShareScheme(schemeId, i);
            isApproved = isApproved && _storage.getArtworkToParticipantApproving(_tokenId, participant);
        }
        if (isApproved) _storage.setArtworkProfitShareFromSecondarySale(_tokenId, 0);
    }

    /// @dev Create a scheme of profit share for user
    /// @param _participants List of profit sharing participants
    /// @param _percentAmount List of profit share % of participants
    /// @return A scheme id
    function createProfitShareScheme(address[] _participants, uint256[] _percentAmount) public returns(uint256) {
        require(_participants.length == _percentAmount.length);
        uint256 schemeId = _storage.addProfitShareScheme(msg.sender, _participants, _percentAmount);
        // нужно ли хранить связь id схемы с владельцем, для быстрого получения адреса владельца по id схемы???
        // _storage.add_addressToProfitShareSchemesMap(msg.sender, schemeId);
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
    /// @param _index Index of scheme for current user's address
    function getProfitShareSchemeIdByIndex(uint256 _index) public view returns (uint256) {
        return _storage.getProfitShareSchemeIdForOwner(msg.sender, _index);
    }

    /// @dev Return a list of user profit share schemes
    /// @return A list of schemes belongs to owner
    function getProfitShareParticipantsCount() public view returns(uint256) {
        return _storage.getNumberOfProfitShareSchemesForOwner(msg.sender);
    }

    function getOwnerOfArtwork(uint256 _artworkId) public view returns (address) {
        return _storage.getOwnerOfArtwork(_artworkId);
    }

    /// @dev Function to add a new digital artwork to blockchain
    /// @param _hashOfArtwork Unique hash of the artwork
    /// @param _limitedEdition Number of artwork edititons
    /// @param _profitShareForSecondarySale Profit share % during secondary sale
    ///        going back to the artist and their list of participants
    /// @param _artworkUrl IPFS URL to digital work
    /// @param _profitShareSchemeId Profit share scheme Id
    function addArtwork(
        bytes32 _hashOfArtwork,
        uint8 _limitedEdition,
        uint8 _profitShareForSecondarySale,
        string _artworkUrl,
        uint8 _profitShareSchemeId
    ) 
        public
    {
        // Check for an identical hash of the digital artwork in existence to prevent uploading a duplicate artwork
        require(_storage.getArtworkHashAsInUse(_hashOfArtwork) == false);
        // Check that the number of artwork editions is >= 1
        require(_limitedEdition >= 1);
        // Create the number of editions specified by the limitEdition
        for (uint8 i = 0; i < _limitedEdition; i++) {
            uint256 _tokenId = _storage.addArtwork(
                msg.sender,
                _hashOfArtwork,
                _limitedEdition,
                i + 1,
                0,
                _profitShareSchemeId,
                _profitShareForSecondarySale,
                _artworkUrl
            );
            // memoraze that a digital work with this hash already loaded
            _storage.setArtworkHashAsInUse(_hashOfArtwork, true);
            // Enter the new owner
            _storage.setOwnerOfArtwork(_tokenId, msg.sender);
            // Add new token to new owner's token list
            _storage.setArtworkToOwner(msg.sender, _tokenId);
            // Add new token to new artist's token list
            _storage.addArtworkToArtistList(_tokenId, msg.sender);
            // Emit token event
            emit TokenCreated(msg.sender, _tokenId);
        }
    }

    function getTokensCount() public view returns (uint256) {
        return _storage.getTotalNumberOfArtworks();
    }

    function getTokensCountByArtist(address _artist) public view returns (uint256) {
        return _storage.getNumberOfArtistArtworks(_artist);
    }

    function getTokensCountByOwner(address _owner) public view returns (uint256) {
        return _storage.getNumberOfOwnerArtworks(_owner);
    }
    
    // /// @dev Return details about token
    // /// @param _tokenId Token Id of digital work
    function getTokenDetails(uint256 _tokenId) 
        public 
        view 
        returns (
            address artist,
            uint256 limitedEdition, 
            uint256 editionNumber, 
            uint256 lastPrice,
            bytes32 hashOfArtwork, 
            uint256 profitShareSchemeId,
            uint256 profitShareFromSecondarySale, 
            string artworkUrl
        ) 
    {
        artist = _storage.getArtworkArtist(_tokenId);
        limitedEdition = _storage.getArtworkLimitedEdition(_tokenId);
        editionNumber = _storage.getArtworkEditionNumber(_tokenId);
        lastPrice = _storage.getArtworkLastPrice(_tokenId);
        hashOfArtwork = _storage.getArtworkHash(_tokenId);
        profitShareSchemeId = _storage.getArtworkProfitShareSchemeId(_tokenId);
        profitShareFromSecondarySale = _storage.getArtworkProfitShareFromSecondarySale(_tokenId);
        artworkUrl = _storage.getArtworkURL(_tokenId);
    }

    /// @dev Change in profit sharing. Change can only be to the percentages for already registered wallet addresses.
    /// @param _tokenId Token to which a change in profit sharing will be applied.
    /// @param _newProfitShareSchemeId Id of profit share scheme
    function changeProfitShareSchemeForToken(
        uint256 _tokenId,
        uint256 _newProfitShareSchemeId
    ) 
        public
        onlyOwnerOf(_tokenId) 
    {
        _storage.setArtworkProfitShareSchemeId(_tokenId, _newProfitShareSchemeId);
    }
    
    /// @dev Function to view the balance in our contract that an owner can withdraw 
    function getWithdrawBalance(address _owner) public view returns (uint256) {
        return _storage.getPendingWithdrawals(_owner);
    }

    /// @dev Return number of particpants
    function getNumberOfParticipantsForProfitShareScheme(uint256 _schemeId) public view returns (uint256) {
        return _storage.getNumberOfParticipantsForProfitShareScheme(_schemeId);
    }

    /// @dev Function returns a participant address and its profit
    /// @param _schemeId Id of Profit Share Scheme
    /// @param _index index of element in array of ProfitShareSchemes
    function getParticipantOfProfitShareScheme(uint256 _schemeId, uint256 _index) 
        public 
        view 
        returns (address, uint256) 
    {
        return _storage.getParticipantOfProfitShareScheme(_schemeId, _index);
    }

    /// @dev Function to withdraw funds to the owners wallet 
    function withdrawFunds() public {
        uint256 balance = _storage.getPendingWithdrawals(msg.sender);
        require(balance > 0);
        _storage.subPendingWithdrawals(msg.sender, balance);
        msg.sender.transfer(balance);
    }

    function setSnarkWalletAddress(address _snarkWalletAddr) public onlyOwner {
        _storage.setSnarkWalletAddress(_snarkWalletAddr);
    }

    function setPlatformProfitShare(uint256 _profit) public onlyOwner {
        _storage.setPlatformProfitShare(_profit);
    }

    function getSnarkWalletAddressAndProfit() public view returns (address snarkWalletAddr, uint256 platformProfit) {
        snarkWalletAddr = _storage.getSnarkWalletAddress();
        platformProfit = _storage.getPlatformProfitShare();
    }

}