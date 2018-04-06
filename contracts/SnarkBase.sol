pragma solidity ^0.4.21;


import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./SnarkOwnership.sol";


contract SnarkBase is Ownable, SnarkOwnership { 
    // тип продажи, в которой участвует цифровая работа
    enum SaleType { None, Offer, Auction }

    // значение в процентах доли Snark
    uint8 internal snarkPercentageAmount = 5;

    struct DigitalWork {
        // название работы
        string digitalWorkTitle;

        // имя художника (до 32 bytes)
        string artistName; 

        // hash файла SHA3 (32 bytes)
        bytes32 hashOfDigitalWork;

        // общее количество экземпляров данной работы, доступных для продажи (2 bytes)
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

        // картина может находиться только в одном из трех состояний:
        // 1. либо не продаваться
        // 2. либо продаваться через обычное предложение
        // 3. либо продаваться через аукцион
        // Это необходимо для исключения возможности двойной продажи 
        SaleType saleType;
        
        // schema of profit division
        mapping(address => uint8) participantToPercentMap;

        // список адресов участников, задействованных в распределении дохода
        address[] participants;

        // ссылка для доступа к картине
        string digitalWorkUrl;
    }

    // массив, содержащий абсолютно все цифровые работы в нашей системе
    DigitalWork[] internal digitalWorks;

    /// @dev Возвращает адрес и долю Snark-а
    function getSnarkParticipation() public view returns (address, uint8) {
        return (snarkOwner, snarkPercentageAmount);
    }

    /// @dev Фукнция добавления нового цифрового полотна в блокчейн
    /// @param _digitalWorkTitle Название цифрового полотна
    /// @param _artistName Имя художника
    /// @param _hashOfDigitalWork Уникальный хэш картины
    /// @param _limitedEdition Количество экземпляров данной цифровой работы
    /// @param _appropriationPercent Доля в процентах для вторичной продажи, 
    ///        которая будет задействована в распредлении прибыли
    function addDigitalWork(
        string _digitalWorkTitle,
        string _artistName,
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
        require(isExistDigitalWorkByHash(_hashOfDigitalWork) == false);
        // проверяем, что количество полотен было >= 1
        require(_limitedEdition >= 1);
        // создаем столько экземпляров полотна, сколько задано в limitEdition
        // сразу добавляем "интерес" Snark 
        for (uint8 i = 0; i < _limitedEdition; i++) {
            digitalWorks.push(DigitalWork({
                digitalWorkTitle: _digitalWorkTitle,
                artistName: _artistName,
                hashOfDigitalWork: _hashOfDigitalWork,
                limitedEdition: _limitedEdition,
                copyNumber: i + 1,
                lastPrice: 0,
                appropriationPercentForSecondTrade: _appropriationPercent,
                isItFirstSelling: true,
                saleType: SaleType.None,
                participants: new address[](0),
                digitalWorkUrl: _digitalWorkUrl
            }));
            // получаем id помещенного полотна в хранилище
            uint256 _tokenId = SafeMath.sub(digitalWorks.length, 1);
            // на всякий случай проверяем, что нет переполнения
            require(_tokenId == uint256(uint32(_tokenId)));
            // сразу же закладываем долю Snark
            digitalWorks[_tokenId].participants.push(snarkOwner);
            digitalWorks[_tokenId].participantToPercentMap[snarkOwner] = snarkPercentageAmount;
            // назначение владельца экземпляра, где также будет сгенерировано событие Transfer протокола ERC 721,
            // которое укажет на то, что полотно было добавлено в блокчейн.
            _transfer(0, msg.sender, _tokenId);
        }
    }

    /// @dev применяем схему распределения дохода для цифровой работы, заданную для Offer или Auction
    /// @param _tokenId Токен, к которому будем применять распределение
    /// @param _addrIncomeParticipants Адреса участников прибыли
    /// @param _percentageParts Процентные доли участников прибыли
    function applySchemaOfProfitDivision(
        uint _tokenId, 
        address[] _addrIncomeParticipants, 
        uint8[] _percentageParts
    ) 
        internal 
        onlyOwnerOf(_tokenId)
    {
        // массивы участников и их долей должны быть равны по длине
        require(_addrIncomeParticipants.length == _percentageParts.length);
        // теперь необходимо сохранить список участников, участвующих в дележке прибыли и их доли
        // кроме Snark, т.к. оно было задано ранее в функции addDigitalWork
        for (uint8 i = 0; i < _addrIncomeParticipants.length; i++) {
            digitalWorks[_tokenId].participants.push(_addrIncomeParticipants[i]);
            digitalWorks[_tokenId].participantToPercentMap[_addrIncomeParticipants[i]] = _percentageParts[i];
        }
    }

    /// @dev Удаление схемы распределения дохода для выбранной цифровой работы
    /// @param _tokenId Id цифровой работы
    function deleteSchemaOfProfitDivision(uint256 _tokenId) internal {
        for (uint8 i = 0; i < digitalWorks[_tokenId].participants.length; i++) {
            delete digitalWorks[_tokenId].participantToPercentMap[digitalWorks[_tokenId].participants[i]];
        }
        // "схлопываем" массив с участниками
        digitalWorks[i].participants.length = 0;
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
        // массивы участников и их долей должны быть равны по длине
        require(_addrIncomeParticipants.length == _percentageParts.length);
        // меняем только проценты для уже существующих адресов
        for (uint8 i = 0; i < _addrIncomeParticipants.length; i++) {
            digitalWorks[_tokenId].participantToPercentMap[_addrIncomeParticipants[i]] = _percentageParts[i];
        }
    }

    /// @dev Функция проверки существования картины по хешу
    /// @param _hash Хеш полотна
    function isExistDigitalWorkByHash(bytes32 _hash) private view returns (bool) {
        bool _isExist = false;
        for (uint256 i = 0; i < digitalWorks.length; i++) {
            if (digitalWorks[i].hashOfDigitalWork == _hash) {
                _isExist = true;
                break;
            }
        }
        return _isExist;
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

    /// @dev Возвращает детальную информацию по одной выбранной цифровой работе
    /// @param _tokenId Токен, для которого хотим получить детальную информацию
    function getDetailsForToken(uint256 _tokenId) 
        public 
        view 
        returns (
            string digitalWorkTitle, 
            string artistName, 
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
        return (
            digitalWorks[_tokenId].digitalWorkTitle,
            digitalWorks[_tokenId].artistName,
            digitalWorks[_tokenId].hashOfDigitalWork,
            digitalWorks[_tokenId].limitedEdition,
            digitalWorks[_tokenId].copyNumber,
            digitalWorks[_tokenId].lastPrice,
            digitalWorks[_tokenId].appropriationPercentForSecondTrade,
            digitalWorks[_tokenId].isItFirstSelling,
            digitalWorks[_tokenId].participants,
            digitalWorks[_tokenId].digitalWorkUrl
        );
    }
}