// solhint-disable-next-line
pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol";


contract SnarkBase is Ownable { 
    
    using SafeMath for uint256;
    using AddressUtils for address;

    /// @dev This emits when a new token creates
    event TokenCreatedEvent(address indexed _owner, uint256 _tokenId);

    struct DigitalWork {
        // hash of file SHA3 (32 bytes)
        bytes32 hashOfDigitalWork;
        // a total number of copies available for sale
        uint16 limitedEdition; 
        // номер копии экземпляра или id копии (2 bytes)
        uint16 copyNumber;
        // стоимость предыдущей продажи (32 bytes)
        uint256 lastPrice;
        // доля дохода при вторичной продаже, идущая художнику и его списку участников (1 bytes)
        // по умолчанию предполагаем - 20%
        uint8 appropriationPercentForSecondTrade;
        // признак первичной продажи
        bool isItFirstSelling;
        // ссылка для доступа к картине
        string digitalWorkUrl;
        // список адресов участников, задействованных в распределении дохода
        address[] participants;
        // schema of profit division
        mapping (address => uint8) participantToPercentMap;
    }

    // percentage of Snark
    uint8 internal snarkPercentageAmount = 5;
    // An array keeps a list of all the ERC721 tokens created in that contract
    DigitalWork[] internal digitalWorks;
    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenToOwnerMap;
    // Tokens list belongs to an owner
    mapping (address => uint256[]) internal ownerToTokensMap;
    // Mapping from hash to owner
    mapping (bytes32 => bool) internal hashToIsExistMap;

    // модификатор, фильтрующий по принадлежности к токену
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == tokenToOwnerMap[_tokenId]);
        _;
    }

    // модификатор, проверяющий принадлежность токенов одному владельцу
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isOwnerOfAll = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && (msg.sender == tokenToOwnerMap[_tokenIds[i]]);
        }
        require(isOwnerOfAll);
        _;
    }

    /// @dev Функция уничтожения контракты в сети блокчейн
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    /// @dev Возвращает адрес и долю Snark-а
    function getSnarkParticipation() public view returns (address, uint8) {
        return (owner, snarkPercentageAmount);
    }

    /// @dev Return details about token
    /// @param _tokenId Token Id of digital work
    function getDetailsForToken(uint256 _tokenId) 
        public 
        view 
        returns (
            bytes32 hashOfDigitalWork, 
            uint16 limitedEdition, 
            uint16 copyNumber, 
            uint256 lastPrice, 
            uint8 appropriationPercentForSecondTrade, 
            bool isItFirstSelling, 
            address[] participants, 
            string digitalWorkUrl
        ) 
    {
        DigitalWork memory dw = digitalWorks[_tokenId];
        return (
            dw.hashOfDigitalWork,
            dw.limitedEdition,
            dw.copyNumber,
            dw.lastPrice,
            dw.appropriationPercentForSecondTrade,
            dw.isItFirstSelling,
            dw.participants,
            dw.digitalWorkUrl
        );
    }

    /// @dev Фукнция добавления нового цифрового полотна в блокчейн
    /// @param _hashOfDigitalWork Уникальный хэш картины
    /// @param _limitedEdition Количество экземпляров данной цифровой работы
    /// @param _appropriationPercent Доля в процентах для вторичной продажи, 
    ///        которая будет задействована в распредлении прибыли
    /// @param _digitalWorkUrl IPFS URL to digital work
    function addDigitalWork(
        bytes32 _hashOfDigitalWork,
        uint8 _limitedEdition,
        uint8 _appropriationPercent,
        string _digitalWorkUrl
    ) 
        public
    {
        // адрес не должен быть равен нулю
        require(msg.sender != address(0));
        // проверяем на существование картины с таким хэшем во избежание повторной загрузки
        require(hashToIsExistMap[_hashOfDigitalWork] == false);
        // проверяем, что количество полотен было >= 1
        require(_limitedEdition >= 1);
        // создаем столько экземпляров полотна, сколько задано в limitEdition
        // сразу добавляем "интерес" Snark 
        for (uint8 i = 0; i < _limitedEdition; i++) {
            uint256 _tokenId = digitalWorks.push(DigitalWork({
                hashOfDigitalWork: _hashOfDigitalWork,
                limitedEdition: _limitedEdition,
                copyNumber: i + 1,
                lastPrice: 0,
                appropriationPercentForSecondTrade: _appropriationPercent,
                isItFirstSelling: true,
                participants: new address[](0),
                digitalWorkUrl: _digitalWorkUrl
            })) - 1;
            // memoraze that a digital work with this hash already loaded
            hashToIsExistMap[_hashOfDigitalWork] = true;
            // на всякий случай проверяем, что нет переполнения
            require(_tokenId == uint256(uint32(_tokenId)));
            // сразу же закладываем долю Snark
            digitalWorks[_tokenId].participants.push(owner);
            digitalWorks[_tokenId].participantToPercentMap[owner] = snarkPercentageAmount;
            // записываем нового владельца
            tokenToOwnerMap[_tokenId] = msg.sender;
            // add new token to tokens list of new owner
            ownerToTokensMap[msg.sender].push(_tokenId);
            // emits event 
            emit TokenCreatedEvent(msg.sender, _tokenId);

            /** DELETE START */
            // назначение владельца экземпляра, где также будет сгенерировано событие Transfer протокола ERC 721,
            // которое укажет на то, что полотно было добавлено в блокчейн.
            // _transfer(0, msg.sender, _tokenId);
            /** DELETE END */
        }
    }

    /// @dev Изменение долевого участия. Менять можно только процентные доли для уже записанных адресов
    /// @param _tokenId Токен, для которого хотят поменять условия распределения прибыли
    /// @param _addrIncomeParticipants Массив адресов, которые участвуют в распределении прибыли
    /// @param _percentageParts Доли соответствующие адресам
    function changePercentageParticipation(
        uint256 _tokenId,        
        address[] _addrIncomeParticipants,
        uint8[] _percentageParts
    ) 
        public
        onlyOwnerOf(_tokenId) 
    {
        // lengths of two arrays should be equals
        require(_addrIncomeParticipants.length == _percentageParts.length);
        // change a percentage for existing participants only
        for (uint8 i = 0; i < _addrIncomeParticipants.length; i++) {
            digitalWorks[_tokenId].participantToPercentMap[_addrIncomeParticipants[i]] = _percentageParts[i];
        }
    }

    /// @dev применяем схему распределения дохода для цифровой работы, заданную для Offer или Auction
    /// @param _tokenId Токен, к которому будем применять распределение
    /// @param _addrIncomeParticipants Адреса участников прибыли
    /// @param _percentageParts Процентные доли участников прибыли
    function _applySchemaOfProfitDivision(
        uint _tokenId, 
        address[] _addrIncomeParticipants, 
        uint8[] _percentageParts
    ) 
        internal 
        onlyOwnerOf(_tokenId)
    {
        // массивы участников и их долей должны быть равны по длине
        require(_addrIncomeParticipants.length == _percentageParts.length);
        // удаляем, если схема уже существует
        _deleteSchemaOfProfitDivision(_tokenId);
        // теперь необходимо сохранить список участников, участвующих в дележке прибыли и их доли
        // кроме Snark, т.к. оно было задано ранее в функции addDigitalWork
        for (uint8 i = 0; i < _addrIncomeParticipants.length; i++) {
            digitalWorks[_tokenId].participants.push(_addrIncomeParticipants[i]);
            digitalWorks[_tokenId].participantToPercentMap[_addrIncomeParticipants[i]] = _percentageParts[i];
        }
    }

    /// @dev Удаление схемы распределения дохода для выбранной цифровой работы
    /// @param _tokenId Id цифровой работы
    function _deleteSchemaOfProfitDivision(uint256 _tokenId) internal {
        for (uint8 i = 0; i < digitalWorks[_tokenId].participants.length; i++) {
            delete digitalWorks[_tokenId].participantToPercentMap[digitalWorks[_tokenId].participants[i]];
        }
        // "схлопываем" массив с участниками
        digitalWorks[i].participants.length = 0;
    }

    /** DELETE START */
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    // event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev Transfer a token from one to another address
    /// @param _from Address of previous owner
    /// @param _to Address of new owner
    /// @param _tokenId Token Id
    // function _transfer(address _from, address _to, uint256 _tokenId) internal {
    //     if (_from != address(0)) {
    //         // удаляем из массива токенов, принадлежащих владельцу
    //         uint256[] storage arrayOfTokens = ownerToTokensMap[_from];
    //         for (uint i = 0; i < arrayOfTokens.length; i++) {
    //             if (arrayOfTokens[i] == _tokenId) {
    //                 arrayOfTokens[i] = arrayOfTokens[arrayOfTokens.length - 1];
    //                 arrayOfTokens.length--;
    //                 break;
    //             }
    //         }
    //     }
    //     // записываем нового владельца
    //     tokenToOwnerMap[_tokenId] = _to;
    //     // add to tokens list of new owner
    //     ownerToTokensMap[_to].push(_tokenId);
    //     // вызов события по спецификации ERC721
    //     emit Transfer(_from, _to, _tokenId);
    // }

    /** DELETE END */

}