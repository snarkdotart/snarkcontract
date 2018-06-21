/// @title Base contract for Snark. Holds all common structs, events and base variables.
/// @dev See the Snark contract documentation to understand how the various contract facets are arranged.
pragma solidity ^0.4.24;

import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/AddressUtils.sol";


contract SnarkBase is Ownable { 
    
    using SafeMath for uint256;
    using AddressUtils for address;

    /*** EVENTS ***/

    /// @dev TokenCreatedEvent is executed when a new token is created.
    event TokenCreatedEvent(address indexed _owner, uint256 _tokenId);
    /// @dev Transfer event as defined in current draft of ERC721.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev The main DigitalWork struct. Every digital artwork created by Snark 
    /// is represented by a copy of this structure.
    struct DigitalWork {
        bytes32 hashOfDigitalWork;          // Hash of file SHA3 (32 bytes)
        uint16 limitedEdition;              // Number of editions available for sale
        uint16 editionNumber;               // Edition number or id (2 bytes)
        uint256 lastPrice;                  // Last sale price (32 bytes)
        uint8 profitShareFromSecondarySale; // Profit share % during secondary sale going back to the artist and their list of participants
        bool isFirstSale;                   // Check if it is the first sale of the artwork
        string digitalWorkUrl;              // URL link to the artwork
        address[] participants;             // Address list of all participants involved in profit sharing
        mapping (address => uint8) participantToPercentMap; // Mapping of profit sharing participant to their share %
    }

    /*** CONSTANTS ***/

    uint8 public snarkProfitShare = 5; // Snark profit share %, default = 5%

    /*** STORAGE ***/

    /// @dev An array containing the DigitalWork struct for all digitalWorks.
    DigitalWork[] internal digitalWorks;

    mapping (uint256 => address) internal tokenToOwnerMap;                          // Mapping from token ID to owner
    mapping (address => uint256[]) internal ownerToTokensMap;                       // Mapping from owner to their Token IDs
    mapping (bytes32 => bool) internal hashToUsedMap;                               // Mapping from hash to previously used indicator
    mapping (address => mapping (address => bool)) internal operatorToApprovalsMap; // Mapping from owner to approved operator
    mapping (uint256 => address) internal tokenToApprovalsMap;                      // Mapping from token ID to approved address

    /// @dev Modifier that checks that an owner has a specific token
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == tokenToOwnerMap[_tokenId]);
        _;
    }

    /// @dev Modifier that checks that an owner possesses multiple tokens
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isOwnerOfAll = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && (msg.sender == tokenToOwnerMap[_tokenIds[i]]);
        }
        require(isOwnerOfAll);
        _;
    }

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    /// @dev Returns address and share % of Snark
    function getSnarkParticipation() public view returns (address, uint8) {
        return (owner, snarkProfitShare);
    }

    /// @dev Return details about token
    /// @param _tokenId Token Id of digital work
    function getTokenDetails(uint256 _tokenId) 
        public 
        view 
        returns (
            bytes32 hashOfDigitalWork, 
            uint16 limitedEdition, 
            uint16 editionNumber, 
            uint256 lastPrice, 
            uint8 profitShareFromSecondarySale, 
            bool isFirstSale, 
            address[] participants, 
            string digitalWorkUrl
        ) 
    {
        DigitalWork memory dw = digitalWorks[_tokenId];
        return (
            dw.hashOfDigitalWork,
            dw.limitedEdition,
            dw.editionNumber,
            dw.lastPrice,
            dw.profitShareFromSecondarySale,
            dw.isFirstSale,
            dw.participants,
            dw.digitalWorkUrl
        );
    }

    /// @dev Function to add a new digital artwork to blockchain
    /// @param _hashOfDigitalWork Unique hash of the artwork
    /// @param _limitedEdition Number of artwork edititons
    /// @param _profitShare Profit share % during secondary sale
    ///        going back to the artist and their list of participants
    /// @param _digitalWorkUrl IPFS URL to digital work
    function addDigitalWork(
        bytes32 _hashOfDigitalWork,
        uint8 _limitedEdition,
        uint8 _profitShare,
        string _digitalWorkUrl
    ) 
        public
    {
        // Address cannot be zero
        require(msg.sender != address(0));
        // Chack for an identical hash of the digital artwork in existence to prevent uploading a duplicate artwork
        require(hashToUsedMap[_hashOfDigitalWork] == false);
        // Check that the number of artwork editions is >= 1
        require(_limitedEdition >= 1);
        // Create the number of editions specified by the limitEdition
        // Add Snark %
        for (uint8 i = 0; i < _limitedEdition; i++) {
            uint256 _tokenId = digitalWorks.push(DigitalWork({
                hashOfDigitalWork: _hashOfDigitalWork,
                limitedEdition: _limitedEdition,
                editionNumber: i + 1,
                lastPrice: 0,
                profitShareFromSecondarySale: _profitShare,
                isFirstSale: true,
                participants: new address[](0),
                digitalWorkUrl: _digitalWorkUrl
            })) - 1;
            // memoraze that a digital work with this hash already loaded
            hashToUsedMap[_hashOfDigitalWork] = true;
            // Check that there is no overflow
            require(_tokenId == uint256(uint32(_tokenId)));
            // Set the Snark %
            digitalWorks[_tokenId].participants.push(owner);
            digitalWorks[_tokenId].participantToPercentMap[owner] = snarkProfitShare;
            // Enter the new owner
            tokenToOwnerMap[_tokenId] = msg.sender;
            // Add new token to new owner's token list
            ownerToTokensMap[msg.sender].push(_tokenId);
            // Emit token event 
            emit TokenCreatedEvent(msg.sender, _tokenId);
        }
    }

    /// @dev Change in profit sharing. Change can only be to the percentages for already registered wallet addresses.
    /// @param _tokenId Token to which a change in profit sharing will be applied.
    /// @param _profitShareParticipants An array of addresses that will participate in profit sharing.
    /// @param _profitSharePartPercentage Profit share % that correspond to participant addresses.    
    function changeProfitShare(
        uint256 _tokenId,        
        address[] _profitShareParticipants,
        uint8[] _profitSharePartPercentage
    ) 
        public
        onlyOwnerOf(_tokenId) 
    {
        // Lengths of two arrays should be equal
        require(_profitShareParticipants.length == _profitSharePartPercentage.length);
        // Change a percentage for existing profit sharing participants only
        for (uint8 i = 0; i < _profitShareParticipants.length; i++) {
            digitalWorks[_tokenId].participantToPercentMap[_profitShareParticipants[i]] = _profitSharePartPercentage[i];
        }
    }

    /// @dev Apply the profit sharing mapping for a digital artwork, during Offer or Auction sale.
    /// @param _tokenId Token to which a change in profit sharing will be applied.
    /// @param _profitShareParticipants An array of addresses that will participate in profit sharing.
    /// @param _profitSharePartPercentage Profit share % that correspond to participant addresses.    
    function _applyProfitShare(
        uint _tokenId, 
        address[] _profitShareParticipants, 
        uint8[] _profitSharePartPercentage
    ) 
        internal 
        onlyOwnerOf(_tokenId)
    {
        // Arrays of participants and their shares should be equal in length.
        require(_profitShareParticipants.length == _profitSharePartPercentage.length);
        // Delete if the Profit Sharing mapping already exists
        _deleteProfitShare(_tokenId);
        // Save the list of participants in profit sharing and their share %
        // except for Snark, since it was already set in the addDigitalWork function        
        for (uint8 i = 0; i < _profitShareParticipants.length; i++) {
            digitalWorks[_tokenId].participants.push(_profitShareParticipants[i]);
            digitalWorks[_tokenId].participantToPercentMap[_profitShareParticipants[i]] = _profitSharePartPercentage[i];
        }
    }

    /// @dev Delete the profit sharing mapping for a selected digital artwork
    /// @param _tokenId ID of a digital artwork    
    function _deleteProfitShare(uint256 _tokenId) internal {
        for (uint8 i = 0; i < digitalWorks[_tokenId].participants.length; i++) {
            delete digitalWorks[_tokenId].participantToPercentMap[digitalWorks[_tokenId].participants[i]];
        }
        // Collapse the participant array
        digitalWorks[i].participants.length = 0;
    }

    /// @dev Transfer a token from one address to another 
    /// @param _from Address of previous owner
    /// @param _to Address of new owner
    /// @param _tokenId Token Id
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            // Remove the transferred token from the array of tokens belonging to the owner
            for (uint i = 0; i < ownerToTokensMap[_from].length; i++) {
                if (ownerToTokensMap[_from][i] == _tokenId) {
                    ownerToTokensMap[_from][i] = ownerToTokensMap[_from][ownerToTokensMap[_from].length - 1];
                    ownerToTokensMap[_from].length--;
                    break;
                }
            }
        }
        // Enter the new owner
        tokenToOwnerMap[_tokenId] = _to;
        // Add token to token list of new owner
        ownerToTokensMap[_to].push(_tokenId);
        // Emit ERC721 Transfer event
        emit Transfer(_from, _to, _tokenId);
    }
}