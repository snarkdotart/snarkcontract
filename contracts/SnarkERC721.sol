pragma solidity ^0.4.24;

import "./SnarkTrade.sol";
import "./OpenZeppelin/ERC721Holder.sol";


contract SnarkERC721 is SnarkTrade, ERC721Receiver {

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
    /// @param _tokenId uint256 ID of the token to validate
    modifier canTransfer(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }
    
    /********************/
    /** ERC721Metadata **/
    /********************/
    function name() public pure returns (string) {
        return "Snark Art Token";
    }

    function symbol() public pure returns (string) {
        return "SAT";
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(_tokenId < digitalWorks.length);
        return digitalWorks[_tokenId].digitalWorkUrl;
    }

    /**********************/
    /** ERC721Enumerable **/
    /**********************/
    function totalSupply() public view returns (uint256) {
        return digitalWorks.length;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId) {
        require(_index < balanceOf(_owner));
        return ownerToTokensMap[_owner][_index];
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return _index;
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
        return ownerToTokensMap[_owner].length;
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_tokenId < digitalWorks.length);
        return tokenToOwnerMap[_tokenId];
    }

    /// @dev Returns whether the specified token exists
    /// @param _tokenId uint256 ID of the token to query the existance of
    /// @return whether the token exists
    function exists(uint256 _tokenId) public view returns (bool _exists) {
        return (tokenToOwnerMap[_tokenId] != address(0));
    }

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) public {
        address tokenOwner = tokenToOwnerMap[_tokenId];
        require(tokenOwner != _approved);
        require(msg.sender == owner || isApprovedForAll(tokenOwner, msg.sender));
        if (getApproved(_tokenId) != address(0) || _approved != address(0)) {
            tokenToApprovalsMap[_tokenId] = _approved;
            emit Approval(msg.sender, _approved, _tokenId);
        }
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) public view returns (address _operator) {
        require(_tokenId < totalSupply());
        return tokenToApprovalsMap[_tokenId];
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender);
        operatorToApprovalsMap[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorToApprovalsMap[_owner][_operator];
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
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) payable {
        require(_from != address(0));
        require(_to != address(0));
        _clearApproval(_from, _tokenId);
        buyToken(_from, _to, _tokenId);
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
        bytes _data
    ) 
        public 
        canTransfer(_tokenId) 
        payable 
    {
        transferFrom(_from, _to, _tokenId);
        require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /// @dev Internal function to clear current approval of a given token ID
    /// @dev Reverts if the given address is not indeed the owner of the token
    /// @param _owner owner of the token
    /// @param _tokenId uint256 ID of the token to be transferred
    function _clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenToApprovalsMap[_tokenId] != address(0)) {
            tokenToApprovalsMap[_tokenId] = address(0);
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
        return _spender == tokenOwner || getApproved(_tokenId) == _spender || isApprovedForAll(tokenOwner, _spender);
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
        bytes _data
    ) 
        internal 
        returns (bool) 
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }

}