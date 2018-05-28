pragma solidity ^0.4.24;


import "./SnarkStorehouse.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./ERC165.sol";


contract SnarkOwnership is ERC721, ERC165 {

    // A tokens list belong to an owner
    mapping (address => uint256[]) internal ownedTokens;

    // Mapping from token ID to owner
    mapping(uint256 => address) internal tokenOwner;

    // Mapping from token ID to index of the owner tokens list 
    mapping(uint256 => uint256) internal ownedTokensIndex; 

    //Mapping from token id to position in the allTokens array 
    mapping(uint256 => uint256) internal allTokensIndex;

    // Mapping from owner to number of owned token
    mapping(address => uint256) internal ownedTokensCount;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    // содержит список адресов новых владельцев, которых апрувнули владельцы токенов
    mapping (uint256 => address) internal digitalWorkApprovals;
    

    // модификатор, фильтрующий по принадлежности к токену
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == tokenOwner[_tokenId]);
        _;
    }

    // модификатор, фильтрующий по принадлежности токенов одному владельцу
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isSenderOwner = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isSenderOwner = (isSenderOwner && (msg.sender == tokenOwner[_tokenIds[i]]));
        }
        require(isSenderOwner);
        _;
    }


/***********************************************************************************/

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


    function name() public view returns (string) {
        return "Snark Art Token";
    }

    function symbol() public view returns (string) {
        return "SAT";
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        return "";
    }

    function totalSupply() public view returns (uint256) {
        return digitalWorks.length;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId) {

    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {

    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return tokenOwner[_tokenId];
    }

    /// @dev
    /// @param _tokenId
    function exists(uint256 _tokenId) public view returns (bool _exists) {
        return (tokenOwner[_tokenId] != address(0));
    }

    /// @dev Владелец токена утверждает право владения нокеном нового владельца
    /// @param _to Адрес нового владельца, которому предаются права на токен
    /// @param _tokenId Токен, который будет передан новому владельцу
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        digitalWorkApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @dev
    /// @param _tokenId
    function getApproved(uint256 _tokenId) public view returns (address _operator) {

    }

    function setApprovalForAll(address _operator, bool _approved) public {

    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {

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
    function transferFrom(address _from, address _to, uint256 _tokenId) public {

    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {

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
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public {

    }

/****************************************************************************************************/


    /// @dev Производит передачу токена на другой адрес
    /// @param _to Адрес, которому хотим передать токен
    /// @param _tokenId Токен, который хотим передать
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }


    /// @dev Передача токена новому владельцу, если предыдущий владелец утвердил нового владельца
    /// @param _tokenId Токен, который будет передан новому владельцу
    function takeOwnership(uint256 _tokenId) public {
        require(digitalWorkApprovals[_tokenId] == msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }

    /**
    * @dev Назначаем владельца полотна
    * @param _from Address of previous owner
    * @param _to Address of new owner
    * @param _tokenId Token Id
    */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            // уменьшаем количество картин у предыдущего владельца
            ownedTokensCount[_from]--;
        }
        // увеличиваем количество картин у нового владельца
        ownedTokensCount[_to]++;
        // записываем нового владельца
        tokenOwner[_tokenId] = _to;
        // вызов события по спецификации ERC721
        emit Transfer(_from, _to, _tokenId);
    }


   
}
