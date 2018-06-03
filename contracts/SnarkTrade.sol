pragma solidity ^0.4.24;

import "./SnarkRenting.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./ERC165.sol";


contract SnarkTrade is ERC165, ERC721 {

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC165 = 0x01ffc9a7;
    /*
    bytes4(keccak256('supportsInterface(bytes4)'));
    */

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
    /*
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
    bytes4(keccak256('tokenByIndex(uint256)'));
    */

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    /*
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('tokenURI(uint256)'));
    */

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC721 = 0x80ac58cd;
    /*
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('getApproved(uint256)')) ^
    bytes4(keccak256('setApprovalForAll(address,bool)')) ^
    bytes4(keccak256('isApprovedForAll(address,address)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'));
    */

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC721Optional = 0x4f558e79;
    /*
    bytes4(keccak256('exists(uint256)'));
    */

    // Mapping from token ID to index of the owner tokens list 
    mapping(uint256 => uint256) internal ownedTokensIndex; 
    //Mapping from token id to position in the allTokens array 
    mapping(uint256 => uint256) internal allTokensIndex;
    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;
    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;
    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;
    // содержит список адресов новых владельцев, которых апрувнули владельцы токенов
    mapping (uint256 => address) internal digitalWorkApprovals;

    // модификатор, фильтрующий по принадлежности токенов одному владельцу
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isSenderOwner = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isSenderOwner = (isSenderOwner && (msg.sender == tokenToOwnerMap[_tokenIds[i]]));
        }
        require(isSenderOwner);
        _;
    }

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165)
        || (_interfaceID == InterfaceSignature_ERC721)
        || (_interfaceID == InterfaceSignature_ERC721Enumerable)
        || (_interfaceID == InterfaceSignature_ERC721Metadata) 
        || (_interfaceID == InterfaceSignature_ERC721Optional));
    }

    function name() public view returns (string) {
        return "Snark Art Token";
    }

    function symbol() public view returns (string) {
        return "SAT";
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(_tokenId < digitalWorks.length);
        return digitalWorks[_tokenId].digitalWorkUrl;
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
        return ownerToTokensMap[_owner].length;
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return tokenToOwnerMap[_tokenId];
    }

    /// @dev
    /// @param _tokenId
    function exists(uint256 _tokenId) public view returns (bool _exists) {
        return (tokenToOwnerMap[_tokenId] != address(0));
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

    /// @dev Возвращает общее количество цифровых работ в системе
    function getAmountOfTokens() public view returns(uint256) {
        return digitalWorks.length;
    }

    /// @dev Возвращает список токенов по адресу
    /// @param _owner Адрес, для которого хотим получить список токенов
    function getOwnerTokenList(address _owner) public view returns (uint256[]) {
        uint256[] memory tokensList = new uint256[](balanceOf(msg.sender));
        uint256 index = 0;
        for (uint i = 0; i < digitalWorks.length; i++) {
            if (ownerOf(i) == _owner) 
                tokensList[index++] = i;
        }
        return tokensList;
    }

    // функция продажи картины. снять все оферы и биды для картины.
    /// @dev Фукнция совершения покупки полотна
    /// @param _tokenId Токен, который покупают
    function buyDigitalWork(uint256 _tokenId) public payable {
        // сюда могут зайти как с Offer, так и с Auction
        // совершить покупку можно лишь только той работы, которая выставлена
        // на продажу через аукцион или вторичную
        require(digitalWorks[_tokenId].saleType == SaleType.Offer || 
            digitalWorks[_tokenId].saleType == SaleType.Auction);
        // запоминаем, был ли оффер, чтобы в конце удалить его или аукцион
        bool isTypeOffer = (digitalWorks[_tokenId].saleType == SaleType.Offer);

        address _from;
        address _to;
        uint256 _price;

        if (isTypeOffer) {
            // если это таки был Offer
            uint256 offerId = tokenToOfferMap[_tokenId];
            _from = offerToOwnerMap[offerId];
            _to = msg.sender;
            _price = offers[offerId].price;
            // покупатель должен быть либо не установлен заранее, либо установлен на того, 
            // кто сейчас пытается купить это полотно
            require(offers[offerId].offerTo == address(0) || offers[offerId].offerTo == _to);
        } else {
            // если это таки был Auction
            uint256 auctionId = digitalWorkToAuctionMap[_tokenId];
            _from = auctionToOwnerMap[auctionId];
            _to = msg.sender;
            _price = auctions[auctionId].workingPrice;
        }
        // переданное количество денег не должно быть меньше установленной цены
        require(msg.value >= _price); 
        // нельзя продать самому себе
        require(ownerOf(_tokenId) != _to);
        // устанавливаем владельцем текущего пользователя
        tokenToOwnerMap[_tokenId] = _to;
        // производим передачу токена (смотри SnarkOwnership)
        _transfer(_from, _to, _tokenId); 
        // распределяем прибыль
        _incomeDistribution(msg.value, _tokenId, _from);        
        // удаляем бид, если есть
        if (digitalWorkToIsExistBidMap[_tokenId]) {
            uint256 bidId = tokenToBidMap[_tokenId];
            uint256 bidValue = bids[bidId].price;
            address bidder = bidToOwnerMap[bidId];
            // удаляем бид
            _deleteBid(bidId);
            // предыдущему бидеру нужно вернуть его сумму
            bidder.transfer(bidValue);
        }

        if (isTypeOffer) {
            // продали - уменьшили общее количество работ в офере
            offers[offerId].countOfDigitalWorks--;
            // удаляем offer, если там ничего не осталось
            if (offers[offerId].countOfDigitalWorks == 0)
                deleteOffer(offerId);
        } else {
            // также - уменьшаем количество работ в аукционе
            auctions[auctionId].countOfDigitalWorks--;
            // удаляем аукцион, если там все распродалось
            if (auctions[auctionId].countOfDigitalWorks == 0)
                deleteAuction(auctionId);
        }
         // геренируем событие, оповещающее, что совершена покупка
        emit DigitalWorkBoughtEvent(_tokenId, msg.value, _from, _to);
    }

    /// @dev Функция принятия бида и продажи предложившему. снять все оферы и биды.
    function acceptBid(uint256 _bidId) public onlyOwnerOf(_tokenId) {
        // получаем id цифровой работы, которую владелец согласен продать по цене бида
        uint256 _tokenId = bids[_bidId].digitalWorkId;
        // запоминаем от кого и куда должна уйти цифровая работа
        address _from = msg.sender;
        address _to = bidToOwnerMap[_bidId];
        // сохраняем сумму
        uint256 _price = bids[_bidId].price;
        // устанавливаем владельцем текущего пользователя
        tokenToOwnerMap[_tokenId] = _to;
        // т.к. деньги уже были перечислены за бид, то просто передаем токен новому владельцу
        _transfer(_from, _to, _tokenId);
        // был ли оффер?
        bool doesItHasOffer = (digitalWorks[_tokenId].saleType == SaleType.Offer);
        // распределяем прибыль
        _incomeDistribution(_price, _tokenId, _from);
        // удаляем бид
        _deleteBid(_bidId);
        // если есть оффер, то его также надо удалить
        if (doesItHasOffer) {
            uint256 offerId = tokenToOfferMap[_tokenId];
            // удаляем только, если у него не осталось картин для продажи
            if (getDigitalWorksOffersList(offerId).length == 0)
                deleteOffer(offerId);
        }
        // оповещаем, что картина была продана
        emit DigitalWorkBoughtEvent(_tokenId, _price, _from, _to);
    }
   
}
