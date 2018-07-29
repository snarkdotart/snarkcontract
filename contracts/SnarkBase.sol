/// @title Base contract for Snark. Holds all common structs, events and base variables.
/// @dev See the Snark contract documentation to understand how the various contract facets are arranged.
pragma solidity ^0.4.24;

import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/AddressUtils.sol";
import "./Storages/SnarkDefinitions.sol";
import "./Storages/SnarkStorage.sol";


contract SnarkBase is Ownable, SnarkDefinitions { 
    
    using SafeMath for uint256;
    using AddressUtils for address;

    /*** EVENTS ***/

    /// @dev TokenCreatedEvent is executed when a new token is created.
    event TokenCreatedEvent(address indexed _owner, uint256 _tokenId);
    /// @dev Event occurs when profit share scheme is created.
    event ProfitShareSchemeAdded(address _schemeOwner, uint256 _profitShareSchemeId);
    /// @dev Event occurs when an artist wants to remove the profit share for secondary sale
    event NeedApproveProfitShareRemoving(address _participant, uint256 _tokenId);
    /// @dev Transfer event as defined in current draft of ERC721.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);


    /*** STORAGE ***/
    SnarkStorage internal _snarkStorage;

    /// @dev Modifier that checks that an owner has a specific token
    /// @param _tokenId Token ID
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == _snarkStorage.get_tokenToOwnerMap(_tokenId));
        _;
    }

    /// @dev Modifier that checks that an owner possesses multiple tokens
    /// @param _tokenIds Array of token IDs
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isOwnerOfAll = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && (msg.sender == _snarkStorage.get_tokenToOwnerMap(_tokenIds[i]));
        }
        require(isOwnerOfAll);
        _;
    }

    /// @dev Modifier that allows do an operation by an artist only
    /// @param _tokenId Artwork Id
    modifier onlyArtistOf(uint256 _tokenId) {
        address artist;
        (artist, , , ) = _snarkStorage.get_artwork_description(_tokenId);
        require(msg.sender == artist);
        _;
    }

    /// @dev Modifier that allows access for a participant only
    modifier onlyParticipantOf(uint256 _tokenId) {
        bool isItParticipant = false;
        uint256 schemeId;
        (, schemeId, , ) = _snarkStorage.get_artwork_details(_tokenId);
        uint256 participantsCount = _snarkStorage.get_profitShareSchemes_participants_length(schemeId);
        address participant;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _snarkStorage.get_profitShareSchemes(schemeId, i);
            if (msg.sender == participant) { 
                isItParticipant = true; 
                break; 
            }
        }
        require(isItParticipant);
        _;
    }

    /// @dev Constructor of contract
    /// @param _snarkStorageAddress Address of a storage contract
    constructor(address _snarkStorageAddress) public {
        _snarkStorage = SnarkStorage(_snarkStorageAddress);
        // _snarkStorage.set_snarkWalletAddress(owner);
    }

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    /// @dev Generating event to approval from each participant of token
    /// @param _tokenId Id of artwork
    function sendRequestForApprovalOfProfitShareRemovalForSecondarySale(uint _tokenId) external onlyArtistOf(_tokenId) {
        uint256 schemeId;
        (, schemeId, , ) = _snarkStorage.get_artwork_details(_tokenId);
        uint256 participantsCount = _snarkStorage.get_profitShareSchemes_participants_length(schemeId);
        address participant;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _snarkStorage.get_profitShareSchemes(schemeId, i);
            _snarkStorage.set_tokenToParticipantApprovingMap(_tokenId, participant, false);
            emit NeedApproveProfitShareRemoving(participant, _tokenId);
        }
    }

    /// @dev Delete a profit share from secondary sale
    /// @param _tokenId Token Id
    function approveRemovingProfitShareFromSecondarySale(uint256 _tokenId) external onlyParticipantOf(_tokenId) {
        _snarkStorage.set_tokenToParticipantApprovingMap(_tokenId, msg.sender, true);

        uint256 schemeId;
        address participant;
        bool isApproved = true;
        (, schemeId, , ) = _snarkStorage.get_artwork_details(_tokenId);
        uint256 participantsCount = _snarkStorage.get_profitShareSchemes_participants_length(schemeId);
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = _snarkStorage.get_profitShareSchemes(schemeId, i);
            isApproved = isApproved && _snarkStorage.get_tokenToParticipantApprovingMap(_tokenId, participant);
        }

        if (isApproved) _snarkStorage.update_artworks_profitShareFromSecondarySale(_tokenId, 0);
    }

    /// @dev Create a scheme of profit share for user
    /// @param _participants List of profit sharing participants
    /// @param _percentAmount List of profit share % of participants
    /// @return A scheme id
    function createProfitShareScheme(address[] _participants, uint8[] _percentAmount) public returns(uint256) {
        require(_participants.length == _percentAmount.length);
        uint256 schemeId = _snarkStorage.add_profitShareSchemes(_participants, _percentAmount);
        _snarkStorage.add_addressToProfitShareSchemesMap(msg.sender, schemeId);
        emit ProfitShareSchemeAdded(msg.sender, schemeId);
    }

    /// @dev Return a total number of profit share schemes
    function getProfitShareSchemesTotalCount() public view returns (uint256) {
        return _snarkStorage.get_profitShareSchemes_length();
    }

    /// @dev Return a total number of user's profit share schemes
    function getProfitShareSchemeCountByAddress() public view returns (uint256) {
        return _snarkStorage.get_addressToProfitShareSchemesMap_length(msg.sender);
    }

    /// @dev Return a scheme Id for user by an index
    /// @param _index Index of scheme for current user's address
    function getProfitShareSchemeIdByIndex(uint256 _index) public view returns (uint256) {
        return _snarkStorage.get_addressToProfitShareSchemesMap(msg.sender, _index);
    }

    /// @dev Return a list of user profit share schemes
    /// @return A list of schemes belongs to owner
    function getProfitShareParticipantsCount() public view returns(uint256) {
        return _snarkStorage.get_addressToProfitShareSchemesMap_length(msg.sender);
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
        // Address cannot be zero
        require(msg.sender != address(0));
        // Check for an identical hash of the digital artwork in existence to prevent uploading a duplicate artwork
        require(_snarkStorage.get_hashToUsedMap(_hashOfArtwork) == false);
        // Check that the number of artwork editions is >= 1
        require(_limitedEdition >= 1);
        // Create the number of editions specified by the limitEdition
        for (uint8 i = 0; i < _limitedEdition; i++) {
            uint256 _tokenId = _snarkStorage.add_artwork(
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
            _snarkStorage.set_hashToUsedMap(_hashOfArtwork, true);
            // Check that there is no overflow
            require(_tokenId == uint256(uint32(_tokenId)));
            // Enter the new owner
            _snarkStorage.set_tokenToOwnerMap(_tokenId, msg.sender);
            // Add new token to new owner's token list
            _snarkStorage.add_ownerToTokensMap(msg.sender, _tokenId);
            // Add new token to new artist's token list
            _snarkStorage.add_artistToTokensMap(msg.sender, _tokenId);
            // Emit token event 
            emit TokenCreatedEvent(msg.sender, _tokenId);
        }
    }

    function getTokensCount() public view returns (uint256) {
        return _snarkStorage.get_artworks_length();
    }

    function getTokensCountByArtist(address _artist) public view returns (uint256) {
        return _snarkStorage.get_artistToTokensMap_length(_artist);
    }

    function getTokensCountByOwner() public view returns (uint256) {
        return _snarkStorage.get_ownerToTokensMap_length(msg.sender);
    }

    /// @dev Return description about token
    /// @param _tokenId Token Id of digital work
    function getTokenDescription(uint256 _tokenId) 
        public 
        view 
        returns (
            address artist,
            uint16 limitedEdition, 
            uint16 editionNumber, 
            uint256 lastPrice
        ) 
    {
        return _snarkStorage.get_artwork_description(_tokenId);
    }

    /// @dev Return details about token
    /// @param _tokenId Token Id of digital work
    function getTokenDetails(uint256 _tokenId) 
        public 
        view 
        returns (
            bytes32 hashOfArtwork, 
            uint256 profitShareSchemaId,
            uint8 profitShareFromSecondarySale, 
            string artworkUrl
        ) 
    {
        return _snarkStorage.get_artwork_details(_tokenId);
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
        _snarkStorage.update_artworks_profitShareSchemaId(_tokenId, _newProfitShareSchemeId);
    }
    
    /// @dev Function to view the balance in our contract that an owner can withdraw 
    function getWithdrawBalance() public view returns (uint256) {
        require(msg.sender != address(0));
        return _snarkStorage.get_pendingWithdrawals(msg.sender);
    }

    /// @dev Function to withdraw funds to the owners wallet 
    function withdrawFunds() public {
        require(msg.sender != address(0));
        uint256 balance = _snarkStorage.get_pendingWithdrawals(msg.sender);
        _snarkStorage.sub_pendingWithdrawals(msg.sender, balance);
        msg.sender.transfer(balance);
    }

    /// @dev Transfer a token from one address to another 
    /// @param _from Address of previous owner
    /// @param _to Address of new owner
    /// @param _tokenId Token Id
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            uint256 tokensCount = _snarkStorage.get_ownerToTokensMap_length(_from);
            // Remove the transferred token from the array of tokens belonging to the owner
            for (uint i = 0; i < tokensCount; i++) {
                uint256 ownerTokenId = _snarkStorage.get_ownerToTokensMap(_from, i);
                if (ownerTokenId == _tokenId) {
                    _snarkStorage.delete_ownerToTokensMap(_from, i);
                    break;
                }
            }
        }
        // Enter the new owner
        _snarkStorage.set_tokenToOwnerMap(_tokenId, _to);
        // Add token to token list of new owner
        _snarkStorage.add_ownerToTokensMap(_to, _tokenId);
        // Emit ERC721 Transfer event
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Function to distribute the profits to participants
    /// @param _price Price at which artwork is sold
    /// @param _tokenId Artwork token ID
    /// @param _from Seller Address
    function _incomeDistribution(uint256 _price, uint256 _tokenId, address _from) internal {
        // distribute the profit according to the schedule contained in the artwork token
        uint256 lastPrice;
        uint256 profitShareSchemaId;
        uint8 profitShareFromSecondarySale;
        (, , , lastPrice) = _snarkStorage.get_artwork_description(_tokenId);
        (, profitShareSchemaId, profitShareFromSecondarySale, ) = _snarkStorage.get_artwork_details(_tokenId);

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
                _snarkStorage.add_pendingWithdrawals(_from, countToSeller);
            }
            uint256 residue = profit; // hold any uncollected count in residue after paying out all of the participants
            uint256 participantsCount = _snarkStorage.get_profitShareSchemes_participants_length(profitShareSchemaId);
            address currentParticipant;
            uint8 participantProfit;
            for (uint8 i = 0; i < participantsCount; i++) { // one by one go through each profit sharing participant
                (currentParticipant, participantProfit) = _snarkStorage.get_profitShareSchemes(profitShareSchemaId, i);
                // calculate the payout count
                uint256 payout = profit * participantProfit / 100;
                // move the payout count to each participant
                _snarkStorage.add_pendingWithdrawals(currentParticipant, payout);
                residue -= payout; // recalculate the uncollected count after the payout
            }
            // if there is any uncollected counts after distribution, move the count to the seller
            lastPrice = residue;
        } else {
            // if there is no profit, then all goes back to the seller
            lastPrice = _price;
        }
        _snarkStorage.add_pendingWithdrawals(_from, lastPrice);
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
        _snarkStorage.update_artworks_lastPrice(_tokenId, _value);
        // mark the sale type to None after sale
        _snarkStorage.set_tokenToSaleTypeMap(_tokenId, SaleType.None);
        _transfer(_mediator, _to, _tokenId);
    }

    /// @dev Snark platform takes it's profit share
    /// @param income A price of selling
    function _takePlatformProfitShare(uint256 income) internal returns (uint256 residue) {
        uint256 profit = income * _snarkStorage.get_platformProfitShare() / 100;
        residue = income - profit;
        address snarkWallet = _snarkStorage.get_snarkWalletAddress();
        _snarkStorage.add_pendingWithdrawals(snarkWallet, profit);
        return residue;
    }

}