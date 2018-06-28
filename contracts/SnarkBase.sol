/// @title Base contract for Snark. Holds all common structs, events and base variables.
/// @dev See the Snark contract documentation to understand how the various contract facets are arranged.
pragma solidity ^0.4.24;

import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/AddressUtils.sol";
import "./SnarkDefinitions.sol";
import "./SnarkStorage.sol";


contract SnarkBase is Ownable, SnarkDefinitions { 
    
    using SafeMath for uint256;
    using AddressUtils for address;

    /*** EVENTS ***/

    /// @dev TokenCreatedEvent is executed when a new token is created.
    event TokenCreatedEvent(address indexed _owner, uint256 _tokenId);
    /// @dev Transfer event as defined in current draft of ERC721.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);


    /*** CONSTANTS ***/

    uint8 public platformProfitShare = 5;   // Snark profit share %, default = 5%

    /*** STORAGE ***/
    SnarkStorage _snarkStorage;

    /// @dev Modifier that checks that an owner has a specific token
    /// @param _tokenId Token ID
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == _snarkStorage.getOwnerByToken(_tokenId));
        _;
    }

    /// @dev Modifier that checks that an owner possesses multiple tokens
    /// @param _tokenIds Array of token IDs
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isOwnerOfAll = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && (msg.sender == _snarkStorage.getOwnerByToken(_tokenIds[i]));
        }
        require(isOwnerOfAll);
        _;
    }

    /// @dev Constructor of contract
    /// @param _snarkStorageAddress Address of a storage contract
    constructor(address _snarkStorageAddress) public {
        _snarkStorage = SnarkStorage(_snarkStorageAddress);
    }

    /// @dev Set a new profit share for Snark platform
    /// @param _platformProfitShare new a profit share
    function setPlatformProfitShare(uint8 _platformProfitShare) external onlyOwner {
        platformProfitShare = _platformProfitShare;
    }

    /// @dev Delete a profit share from secondary sale
    /// @param _tokenId Token Id
    function dropProfitShareFromSecondarySale(uint256 _tokenId) external onlyOwner {
        _snarkStorage.updateArtworkProfitShareFromSecondarySale(_tokenId, 0);
    }

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    /// @dev Create a scheme of profit share for user
    /// @param _participants List of profit sharing participants
    /// @param _percentAmounts List of profit share % of participants
    /// @return A scheme id
    function createProfitShareScheme(address[] _participants, uint8[] _percentAmounts) public returns(uint256) {
        require(_participants.length == _percentAmounts.length);
        uint256 schemeId = _snarkStorage.addProfitShareScheme(_participants, _percentAmounts);
        _snarkStorage.addProfitShareSchemeToAddress(msg.sender, schemeId);
        return schemeId;
    }

    /// @dev Return a list of user profit share schemes
    /// @return A list of schemes belongs to owner
    function getProfitShareSchemeList() public view returns(uint256[]) {
        return _snarkStorage.getProfitShareSchemeByAddress(msg.sender);
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
        require(_snarkStorage.getHashToUsed(_hashOfArtwork) == false);
        // Check that the number of artwork editions is >= 1
        require(_limitedEdition >= 1);
        // Create the number of editions specified by the limitEdition
        for (uint8 i = 0; i < _limitedEdition; i++) {
            uint256 _tokenId = _snarkStorage.addArtwork(
                _hashOfArtwork,
                _limitedEdition,
                i + 1,
                0,
                _profitShareSchemeId,
                _profitShareForSecondarySale,
                _artworkUrl
            );
            // memoraze that a digital work with this hash already loaded
            _snarkStorage.setHashToUsed(_hashOfArtwork, true);
            // Check that there is no overflow
            require(_tokenId == uint256(uint32(_tokenId)));
            // Enter the new owner
            _snarkStorage.setOwnerForToken(_tokenId, msg.sender);
            // Add new token to new owner's token list
            _snarkStorage.addTokenToOwner(msg.sender, _tokenId);
            // Emit token event 
            emit TokenCreatedEvent(msg.sender, _tokenId);
        }
    }

    /// @dev Return details about token
    /// @param _tokenId Token Id of digital work
    function getTokenDetails(uint256 _tokenId) 
        public 
        view 
        returns (
            bytes32 hashOfArtwork, 
            uint16 limitedEdition, 
            uint16 editionNumber, 
            uint256 lastPrice, 
            uint256 profitShareSchemaId,
            uint8 profitShareFromSecondarySale, 
            string artworkUrl
        ) 
    {
        return _snarkStorage.getArtwork(_tokenId);
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
        _snarkStorage.updateArtworkProfitShareSchemaId(_tokenId, _newProfitShareSchemeId);
    }

    /// @dev Transfer a token from one address to another 
    /// @param _from Address of previous owner
    /// @param _to Address of new owner
    /// @param _tokenId Token Id
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            // Remove the transferred token from the array of tokens belonging to the owner
            uint256[] memory tokensArray = _snarkStorage.getTokensByOwner(_from);
            for (uint i = 0; i < tokensArray.length; i++) {
                if (tokensArray[i] == _tokenId) {
                    _snarkStorage.deleteOwnerTokenByIndex(_from, i);
                    break;
                }
            }
        }
        // Enter the new owner
        _snarkStorage.setOwnerForToken(_tokenId, _to);
        // Add token to token list of new owner
        _snarkStorage.addTokenToOwner(_to, _tokenId);
        // Emit ERC721 Transfer event
        emit Transfer(_from, _to, _tokenId);
    }

}