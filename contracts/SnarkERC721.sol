pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";
import "./openzeppelin/SupportsInterfaceWithLookup.sol";
import "./openzeppelin/ERC721Basic.sol";
import "./openzeppelin/ERC721.sol";
import "./openzeppelin/ERC721Receiver.sol";
import "./openzeppelin/SafeMath.sol";
import "./openzeppelin/AddressUtils.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkBaseExtraLib.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkLoanLib.sol";


contract SnarkERC721 is Ownable, SupportsInterfaceWithLookup, ERC721Basic, ERC721, SnarkDefinitions {

    using SafeMath for uint256;
    using AddressUtils for address;
    using SnarkBaseLib for address;
    using SnarkBaseExtraLib for address;
    using SnarkCommonLib for address;
    using SnarkLoanLib for address;

    address private _storage;

    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    /// @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
    /// @param _tokenId uint256 ID of the token to validate
    modifier canTransfer(uint256 _tokenId) {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == owner,
            "You have to be either token owner or be approved by owner"
        );
        _;
    }

    modifier correctToken(uint256 _tokenId) {
        require(
            _tokenId > 0 && _tokenId <= SnarkBaseLib.getTotalNumberOfTokens(_storage),
            "Token is not correct"
        );
        _;
    }

    constructor(address storageAddress) public {
        // get an address of a storage
        _storage = storageAddress;
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(INTERFACEID_ERC721);
        _registerInterface(INTERFACEID_ERC721EXISTS);
        _registerInterface(INTERFACEID_ERC721ENUMERABLE);
        _registerInterface(INTERFACEID_ERC721METADATA);
    }

    /// @notice Will receive any eth sent to the contract
    function() external payable {} // solhint-disable-line

    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    /********************/
    /** ERC721Metadata **/
    /********************/
    /// @dev Gets the token name
    /// @return string representing the token name
    function name() public view returns (string memory) {
        return SnarkBaseLib.getTokenName(_storage);
    }

    /// @dev Gets the token symbol
    /// @return string representing the token symbol
    function symbol() public view returns (string memory) {
        return SnarkBaseLib.getTokenSymbol(_storage);
    }

    /// @dev Returns an URI for a given token ID
    /// Throws if the token ID does not exist. May return an empty string.
    /// @param _tokenId uint256 ID of the token to query
    function tokenURI(uint256 _tokenId) public view correctToken(_tokenId) returns (string memory) {
        return SnarkBaseLib.getDecorationUrl(_storage, _tokenId);
    }

    /**********************/
    /** ERC721Enumerable **/
    /**********************/
    function totalSupply() public view returns (uint256) {
        return SnarkBaseLib.getTotalNumberOfTokens(_storage);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId) {
        require(_index < balanceOf(_owner));
        uint256 tokenId;
        uint256 loanId = SnarkLoanLib.getLoanPointer(_storage);
        bool isActive = SnarkLoanLib.isLoanActive(_storage);
        address loanOwner = SnarkLoanLib.getOwnerOfLoan(_storage, loanId);
        if (isActive && _owner == loanOwner) {
            uint256 countOfNotApprovedTokens = 
                SnarkLoanLib.getTotalNumberOfTokensInNotApprovedTokensForLoan(_storage, _owner);
            if (_index < countOfNotApprovedTokens) {
                tokenId = SnarkLoanLib.getTokenFromNotApprovedTokensForLoanByIndex(_storage, _owner, _index);
            } else {
                uint256 index = _index - countOfNotApprovedTokens;
                tokenId = SnarkLoanLib.getTokenFromApprovedTokensForLoanByIndex(_storage, index);
            }
        } else {
            tokenId = SnarkBaseLib.getTokenIdOfOwner(_storage, _owner, _index);
        }
        return tokenId;
    }

    // for the case when a loan is active
    function tokenOfRealOwnerByIndex(address _owner, uint256 _index) 
        public view returns (uint256 _tokenId, address _realOwner) 
    {
        _tokenId = tokenOfOwnerByIndex(_owner, _index);
        _realOwner = ownerOf(_tokenId);
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return _index.add(1);
    }

    /*****************/
    /** ERC721Basic **/
    /*****************/
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        uint256 balance = 0;
        uint256 loanId = SnarkLoanLib.getLoanPointer(_storage);
        if (SnarkLoanLib.isLoanActive(_storage) 
            && _owner == SnarkLoanLib.getOwnerOfLoan(_storage, loanId)
        ) {
            balance = SnarkLoanLib.getTotalNumberOfTokensInApprovedTokensForLoan(_storage);
            balance += SnarkLoanLib.getTotalNumberOfTokensInNotApprovedTokensForLoan(_storage, _owner);
        } else {
            balance = SnarkBaseLib.getOwnedTokensCount(_storage, _owner);
        }
        return balance;
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view correctToken(_tokenId) returns (address) {
        address tokenOwner = SnarkBaseLib.getOwnerOfToken(_storage, _tokenId);
        require(tokenOwner != address(0));
        return tokenOwner;
    }

    /// @dev Returns whether the specified token exists
    /// @param _tokenId uint256 ID of the token to query the existance of
    /// @return whether the token exists
    function exists(uint256 _tokenId) public view returns (bool _exists) {
        return (SnarkBaseLib.getOwnerOfToken(_storage, _tokenId) != address(0));
    }

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _to address to be approved for the given token ID
    /// @param _tokenId uint256 ID of the token to be approved
    function approve(address _to, uint256 _tokenId) public correctToken(_tokenId) {
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != _to);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender));
        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            SnarkBaseLib.setApprovalsToToken(_storage, tokenOwner, _tokenId, _to);
            emit Approval(msg.sender, _to, _tokenId);
        }
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) public view correctToken(_tokenId) returns (address _operator) {
        address tokenOwner = ownerOf(_tokenId);
        return SnarkBaseLib.getApprovalsToToken(_storage, tokenOwner, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender);
        SnarkBaseLib.setApprovalsToOperator(_storage, msg.sender, _operator, _approved);
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return SnarkBaseLib.getApprovalsToOperator(_storage, _owner, _operator);
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) 
        public 
        canTransfer(_tokenId) 
        correctToken(_tokenId) 
        payable 
    {
        require(
            SnarkBaseLib.getSaleTypeToToken(_storage, _tokenId) == uint256(SaleType.None), 
            "Token has to be free from different obligations on Snark platform"
        );
        require(_from != address(0), "Sender's address can't be equal zero");
        require(_to != address(0), "Receiver's  address can't be equal zero");
        require(_from != _to, "Sender's address can't be equal receiver's  address");

        _clearApproval(_from, _tokenId);

        if (msg.value > 0) {
            address(uint160(_storage)).transfer(msg.value);
            SnarkCommonLib.buy(_storage, _tokenId, msg.value, _from, _to);
        } else {
            SnarkCommonLib.transferToken(_storage, _tokenId, _from, _to);
        }
        emit Transfer(_from, _to, _tokenId);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId, 
        bytes memory _data
    ) 
        public 
        canTransfer(_tokenId)
        payable
    {
        transferFrom(_from, _to, _tokenId);
        require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    function echoTransfer(address _from, address _to, uint256 _tokenId) public {
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Internal function to clear current approval of a given token ID
    /// @dev Reverts if the given address is not indeed the owner of the token
    /// @param _owner owner of the token
    /// @param _tokenId uint256 ID of the token to be transferred
    function _clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (SnarkBaseLib.getApprovalsToToken(_storage, _owner, _tokenId) != address(0)) {
            SnarkBaseLib.setApprovalsToToken(_storage, _owner, _tokenId, address(0));
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    /// @dev Returns whether the given spender can transfer a given token ID
    /// @param _spender address of the spender to query
    /// @param _tokenId uint256 ID of the token to be transferred
    /// @return bool whether the msg.sender is approved for the given token ID,
    ///  is an operator of the owner, or is the owner of the token
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(_tokenId);
        return (
            _spender == tokenOwner || 
            getApproved(_tokenId) == _spender || 
            isApprovedForAll(tokenOwner, _spender)
        );
    }

    /// @dev Internal function to invoke `onERC721Received` on a target address
    /// @dev The call is not executed if the target address is not a contract
    /// @param _from address representing the previous owner of the given token ID
    /// @param _to target address that will receive the tokens
    /// @param _tokenId uint256 ID of the token to be transferred
    /// @param _data bytes optional data to send along with the call
    /// @return whether the call correctly returned the expected magic value
    function _checkAndCallSafeTransfer(
        address _from, 
        address _to, 
        uint256 _tokenId, 
        bytes memory _data
    ) 
        internal 
        returns (bool) 
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }

}