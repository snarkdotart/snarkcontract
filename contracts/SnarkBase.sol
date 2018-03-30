pragma solidity ^0.4.21;


import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./SnarkOwnership.sol";


contract SnarkBase is Ownable, SnarkOwnership { 

    // событие, оповещающее, что требуется подтверждение согласия от участников по их долям
    event PercentageApprovalEvent(uint256 _tokenId, address _to, uint8 _percentageAmount);

    // Описывает структуру цифровой работы
    struct DigitalWork {
        // номер копии экземпляра или id копии
        uint16 digitalWorkCopyNumber;
        
        // цена предыдущей продажи, присущей данной конкретной копии полотна
        // необходима для того, чтобы можно было вычислить прибыль при вторичной продаже.
        // при первичной продаже, тут будет 0.
        uint lastPrice;
        
        // общее количество экземпляров данного полотна, доступных для продажи
        // ??? возможно эта величина не относится к самой картине, должна принадлежать как свойство в маркетинге
        uint16 limitedEdition; 
        
        // адрес художника
        address artist;

        // доля дохода при вторичной продаже, идущая художнику и его списку участников
        uint8 artistPart;
        
        // hash файла SHA3
        bytes32 hashOfDigitalWork;
        
        // выставлено ли полотно на продажу
        bool isForSale;

        // готово к продаже будет только тогда, когда абсолютно все участники прибыли
        // одобрили свои доли в доходе
        bool isReadyForSale;

        // признак первичной продажи
        bool isItFirstSelling;
        
        // адреса участников прибыли, кроме самого художника, так как
        // художнику отправляем остаток, после всех переводов
        // Сюда snark прописываем автоматом при создании полотна
        // address[] addressesOfIncomesParticipants;

        // доли участников, участвующих в распределении прибыли
        // для snark прописываем сразу при создании полотна
        // mapping(address => uint8) addressToPercentagePart;

        // содержит согласие участников на предложенную долю
        // от дохода для каждого полотна
        // mapping(address => bool) addressToApprovedByParticipant;

        // адрес доступа к картине, в случае расположения ее в сети IPFS
        // ??? надо ли шифровать картину и если да, то где тогда будем хранить 
        // пароль для расшифровки ???
        // string ipfsUrl; // - похоже этот url надо хранить снаружи, т.е. у нас в базе
    }

    // описывает участников и их доли
    struct Participant {
        address participant;
        uint8 persentageAmount;
        bool isApproved;
    }

    // значение в процентах доли Snark
    uint8 private snarkPercentageAmount = 5;

    // массив, содержащий абсолютно все полотна
    DigitalWork[] internal digitalWorks;

    // содержит связь id полотна со списком участников и их долей
    mapping(uint256 => Participant[]) internal digitalWorkIdToParticipants;

    // добавляем новое цифровое полотно в блокчейн
    function addNewDigitalWork(
        bytes32 _hashOfDigitalWork,
        uint8 _limitedEdition,
        address _artist,
        uint8 _artistPart,
        address[] _addrIncomeParticipants,
        uint8[] _percentageParts
    ) 
        external
    {
        // адрес не должен быть равен нулю
        require(msg.sender != address(0));
        // массивы участников и их долей должны быть равны по длине
        require(_addrIncomeParticipants.length == _percentageParts.length);
        // проверяем на существование картины с таким хэшем во избежание повторной загрузки
        require(isExistDigitalWorkByHash(_hashOfDigitalWork) == false);
        // проверяем, что количество полотен было >= 1
        require(_limitedEdition >= 1);
        // создаем столько экземпляров полотна, сколько задано в limitEdition
        for (uint8 i = 0; i < _limitedEdition; i++) {
            digitalWorks.push(DigitalWork({
                digitalWorkCopyNumber: i,
                lastPrice: 0,
                limitedEdition: _limitedEdition,
                artist: _artist,
                artistPart: _artistPart,
                hashOfDigitalWork: _hashOfDigitalWork,
                isForSale: false,
                isReadyForSale: false,
                isItFirstSelling: true
            }));
            // получаем id помещенного полотна в хранилище
            uint256 _tokenId = SafeMath.sub(digitalWorks.length, 1);
            // на всякий случай проверяем, что нет переполнения
            require(_tokenId == uint256(uint32(_tokenId)));

            // теперь необходимо сохранить список участников, участвующих в дележке прибыли и их доли
            Participant[] storage investors = digitalWorkIdToParticipants[_tokenId];
            // первым делом добавляем snark, как участника, по умолчанию
            investors.push(Participant(owner, snarkPercentageAmount, true));
            // а теперь добавляем всех остальных из списка, заданных художником
            for (uint8 inv = 0; inv < _addrIncomeParticipants.length; inv++) {
                investors.push(Participant(_addrIncomeParticipants[inv], _percentageParts[inv], false));

                // отправляем уведомление всем участникам, чтобы они подтвердили свое 
                // согласие на установленную их долю в доходе. 
                // !!! То, что событие будет вызываться для каждой копии картины отдельно - БОЛЬШОЙ НЕДОСТАТОК
                // !!! НАДО БЫ отправить лучше один раз массивом (id полотна, адресат, его доля).
                emit PercentageApprovalEvent(_tokenId, _addrIncomeParticipants[inv], _percentageParts[inv]);
            }

            // назначение владельца экземпляра, где также будет сгенерировано событие Transfer протокола ERC 721,
            // которое укажет на то, что полотно было добавлено в блокчейн.
            _transfer(0, _artist, _tokenId);
        }
    }

    /// @dev Принятие подтверждения от участника о согласии его доле
    /// @param _tokenId Токен, для которого хотим получить участиков распределения прибыли
    function approveParticipation(uint256 _tokenId) public {
        require(msg.sender != address(0));
        bool _isReady = true;
        Participant[] storage investors = digitalWorkIdToParticipants[_tokenId];
        for (uint8 i = 0; i < investors.length; i++) {
            if (msg.sender == investors[i].participant) {
                // выставляем для текущего адреса свойство подтвреждения
                investors[i].isApproved = true;
            }
            _isReady = _isReady && investors[i].isApproved;
        }
        // проверяем все ли участники подтверждены и если да, то 
        // выставляем готовность полотна торговаться
        if (_isReady) {
            DigitalWork storage digitalWork = digitalWorks[_tokenId];
            digitalWork.isReadyForSale = _isReady;
        }
    }

    /// @dev Изменение долевого участия. Возможно только до тех пор, 
    /// пока картина не выставлена на продажу. ??? ИЛИ ЗАПРЕТИТЬ ???
    /// @param _tokenId Токен, для которого хотят поменять условия распределения прибыли
    /// @param _addrIncomeParticipants Массив адресов, которые участвуют в распределении прибыли
    /// @param _percentageParts Доли соответствующие адресам
    function changePercentageParticipation(
        uint256 _tokenId,        
        address[] _addrIncomeParticipants,
        uint8[] _percentageParts
    ) 
        public 
    {
        require(_addrIncomeParticipants.length == _percentageParts.length);

        // теперь необходимо сохранить список участников, участвующих в дележке прибыли и их доли
        Participant[] storage investors = digitalWorkIdToParticipants[_tokenId];
        // первым делом добавляем snark, как участника, по умолчанию
        investors.push(Participant(owner, snarkPercentageAmount, true));
        // а теперь добавляем всех остальных из списка, заданных художником
        for (uint8 inv = 0; inv < _addrIncomeParticipants.length; inv++) {
            investors.push(Participant(_addrIncomeParticipants[inv], _percentageParts[inv], false));

            // отправляем уведомление всем участникам, чтобы они подтвердили свое 
            // согласие на установленную их долю в доходе. 
            // !!! То, что событие будет вызываться для каждой копии картины отдельно - БОЛЬШОЙ НЕДОСТАТОК
            // !!! НАДО БЫ отправить лучше один раз массивом (id полотна, адресат, его доля).
            emit PercentageApprovalEvent(_tokenId, _addrIncomeParticipants[inv], _percentageParts[inv]);
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

    // получение списка картин и долей участника, ожидающих его подтверждения
    // function getWaiteApprovalList

}