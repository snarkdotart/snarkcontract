pragma solidity ^0.4.21;


import "zeppelin-solidity/contracts/token/ERC721/ERC721.sol";


contract SnarkOwnership is ERC721 {

    // содержит связь id полотна с их владельцем
    mapping(uint256 => address) internal tokenToOwner;

    // содержит информацию о количестве токенов, принадлежащих владельцу
    mapping(address => uint256) internal ownershipTokenCount;

    // содержит список адресов новых владельцев, которых апрувнули владельцы токенов
    mapping (uint256 => address) internal digitalWorkApprovals;

    // содержит адрес Snark аккаунта
    address internal snarkOwner;

    // модификатор, фильтрующий по принадлежности к токену
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == tokenToOwner[_tokenId]);
        _;
    }

    // конструктор, где запоминаем адрес Snark аккаунта
    function SnarkOwnership() public {
        snarkOwner = msg.sender;
    }

    /// @dev Функция протокола ERC 721. Возвращает количество токенов, принадлежащих адресу
    /// @param _owner Адрес клиента, колчество токенов которого хотят узнать
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownershipTokenCount[_owner];
    }

    /// @dev Возвращает адрес владельца токена
    /// @param _tokenId Токен, владельца которого хотим узнать
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return tokenToOwner[_tokenId];
    }

    /// @dev Производит передачу токена на другой адрес
    /// @param _to Адрес, которому хотим передать токен
    /// @param _tokenId Токен, который хотим передать
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Владелец токена утверждает право владения нокеном нового владельца
    /// @param _to Адрес нового владельца, которому предаются права на токен
    /// @param _tokenId Токен, который будет передан новому владельцу
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        digitalWorkApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @dev Передача токена новому владельцу, если предыдущий владелец утвердил нового владельца
    /// @param _tokenId Токен, который будет передан новому владельцу
    function takeOwnership(uint256 _tokenId) public {
        require(digitalWorkApprovals[_tokenId] == msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }

    /// @dev Назначаем владельца полотна
    /// @param _from Адрес предыдущего владельца
    /// @param _to Адрес нового владельца
    /// @param _tokenId Токен полотна
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            // уменьшаем количество картин у предыдущего владельца
            ownershipTokenCount[_from]--;
        }
        // увеличиваем количество картин у нового владельца
        ownershipTokenCount[_to]++;
        // записываем нового владельца
        tokenToOwner[_tokenId] = _to;
        // вызов события по спецификации ERC721
        emit Transfer(_from, _to, _tokenId);
    }
   
}
