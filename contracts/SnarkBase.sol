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
    event TokenCreatedEvent(address indexed _owner, uint256 _tokenId);
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
            // Check that there is no overflow
            require(_tokenId == uint256(uint32(_tokenId)));
            // memoraze that a digital work with this hash already loaded
            _storage.setArtworkHashAsInUse(_hashOfArtwork, true);
            // Enter the new owner
            _storage.setOwnerOfArtwork(_tokenId, msg.sender);
            // Add new token to new owner's token list
            _storage.setArtworkToOwner(msg.sender, _tokenId);
            // Add new token to new artist's token list
            _storage.addArtworkToArtistList(_tokenId, msg.sender);
            // Emit token event 
            emit TokenCreatedEvent(msg.sender, _tokenId);
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

    /// @dev Transfer a token from one address to another 
    /// @param _from Address of previous owner
    /// @param _to Address of new owner
    /// @param _tokenId Token Id
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        /* !!!!!!!!!!! set to internal after test !!!!!!!!!!! */
        _storage.transferArtwork(_tokenId, _from, _to);
        // Emit ERC721 Transfer event
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Function to distribute the profits to participants
    /// @param _price Price at which artwork is sold
    /// @param _tokenId Artwork token ID
    /// @param _from Seller Address
    function _incomeDistribution(uint256 _price, uint256 _tokenId, address _from) internal { 
        /* !!!!!!!!!!! set to internal after test !!!!!!!!!!! */
        // distribute the profit according to the schedule contained in the artwork token
        uint256 lastPrice = _storage.getArtworkLastPrice(_tokenId);
        uint256 profitShareSchemaId = _storage.getArtworkProfitShareSchemeId(_tokenId);
        uint256 profitShareFromSecondarySale = _storage.getArtworkProfitShareFromSecondarySale(_tokenId);

        // calculate profit
        // in primary sale the lastPrice should be 0 while in a secondary it should be a prior sale price
        if (lastPrice < _price && (_price - lastPrice) >= 100) {
            uint256 profit = _price - lastPrice;
            if (lastPrice > 0) {
                // if it is a secondary sale, reduce the profit by the profit sharing % specified by the artist 
                // the remaining count goes back to the seller
                uint256 countToSeller = _price;
                // the count to be distributed
                profit = profit * profitShareFromSecondarySale / 100;
                // the count that will go to the seller
                countToSeller -= profit;
                _storage.addPendingWithdrawals(_from, countToSeller);
            }
            uint256 residue = profit; // hold any uncollected count in residue after paying out all of the participants
            uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(profitShareSchemaId);
            address currentParticipant;
            uint256 participantProfit;
            for (uint256 i = 0; i < participantsCount; i++) { // one by one go through each profit sharing participant
                (currentParticipant, participantProfit) = 
                    _storage.getParticipantOfProfitShareScheme(profitShareSchemaId, i);
                // calculate the payout count
                uint256 payout = profit * participantProfit / 100;
                // move the payout count to each participant
                _storage.addPendingWithdrawals(currentParticipant, payout);
                residue -= payout; // recalculate the uncollected count after the payout
            }
            // if there is any uncollected counts after distribution, move the count to the seller
            lastPrice = residue;
        } else {
            // if there is no profit, then all goes back to the seller
            lastPrice = _price;
        }
        _storage.addPendingWithdrawals(_from, lastPrice);
    }

    /// @dev Snark platform takes it's profit share
    /// @param _profit A price of selling
    function _takePlatformProfitShare(uint256 _profit) internal {
        /* !!!!!!!!!!! set to internal after test !!!!!!!!!!! */
        address snarkWallet = _storage.getSnarkWalletAddress();
        _storage.addPendingWithdrawals(snarkWallet, _profit);
    }

    function _calculatePlatformProfitShare(uint256 _income) internal view returns (uint256 profit, uint256 residue) {
        /* !!!!!!!!!!! set to internal after test !!!!!!!!!!! */
        profit = (_income * _storage.getPlatformProfitShare() / 100);
        residue = (_income - profit);
    }

    /// @dev Function of an artwork buying
    /// @param _tokenId Artwork ID
    /// @param _value Selling price of artwork
    /// @param _from Address of seller
    /// @param _to Address of buyer
    /// @param _mediator Address of token's temporary keeper (Snark)
    function _buy(uint256 _tokenId, uint256 _value, address _from, address _to, address _mediator) internal {
        _incomeDistribution(_value, _tokenId, _from);
        // mark the price for which the artwork sold
        _storage.setArtworkLastPrice(_tokenId, _value);
        // mark the sale type to None after sale
        _storage.setArtworkToSaleType(_tokenId, uint256(SaleType.None));
        _transfer(_mediator, _to, _tokenId);
    }

}