pragma solidity ^0.4.19;


import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./SnarkOwnership.sol";


contract SnarkBase is Ownable, SnarkOwnership { 

    // событие, оповещающее, что требуется подтверждение согласия от участников по их долям
    event PercentageApprovalEvent(uint256 _tokenId, address _to, uint8 _percentageAmount);

    // Описывает структуру цифрового полотна
    struct DigitalCanvas {
        // номер копии экземпляра или id копии
        uint16 canvasCopyNumber;
        
        // цена предыдущей продажи, присущей данной конкретной копии полотна
        // необходима для того, чтобы можно было вычислить прибыль при вторичной продаже.
        // при первичной продаже, тут будет 0.
        uint lastPrice;
        
        // общее количество экземпляров данного полотна, доступных для продажи
        // ??? возможно эта величина не относится к самой картине, должна принадлежать как свойство в маркетинге
        uint16 limitedEdition; 
        
        // адрес художника
        address artist;
        
        // hash файла SHA3
        bytes32 hashOfCanvas;
        
        // выставлено ли полотно на продажу
        bool isForSale;

        // готово к продаже будет только тогда, когда абсолютно все участники прибыли
        // одобрили свои доли в доходе
        bool isReadyForSale;
        
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
    DigitalCanvas[] internal digitalCanvases;

    // содержит связь id полотна со списком участников и их долей
    mapping(uint256 => Participant[]) internal canvasIdToParticipants;

    // добавляем новое цифровое полотно в блокчейн
    function addNewCanvas(
        bytes32 _hashOfCanvas,
        uint8 _limitedEdition,
        address _artist,
        address[] _addrIncomeParticipants,
        uint8[] _percentageParts
    ) 
        external
    {
        // адрес не должен быть равен нулю
        require(msg.sender != address(0));
        // проверяем на существование картины с таким хэшем во избежание повторной загрузки
        require(isExistCanvasByHash(_hashOfCanvas) == false);
        // проверяем, что количество полотен было >= 1
        require(_limitedEdition >= 1);
        // создаем столько экземпляров полотна, сколько задано в limitEdition
        for (uint8 i = 0; i < _limitedEdition; i++) {
            digitalCanvases.push(DigitalCanvas({
                canvasCopyNumber: i,
                lastPrice: 0, 
                limitedEdition: _limitedEdition, 
                artist: _artist, 
                hashOfCanvas: _hashOfCanvas,
                isForSale: false,
                isReadyForSale: false
            }));
            // получаем id помещенного полотна в хранилище
            uint256 _tokenId = SafeMath.sub(digitalCanvases.length, 1);
            // на всякий случай проверяем, что нет переполнения
            require(_tokenId == uint256(uint32(_tokenId)));
            // теперь необходимо сохранить список участников, участвующих в дележке прибыли и их доли
            Participant[] storage investors = canvasIdToParticipants[_tokenId];
            // первым делом добавляем snark, как участника, по умолчанию
            investors.push(Participant(owner, snarkPercentageAmount, true));
            // а теперь добавляем всех остальных из списка, заданных художником
            for (uint8 inv = 0; inv < _addrIncomeParticipants.length; inv++) {
                investors.push(Participant(_addrIncomeParticipants[inv], _percentageParts[inv], false));

                // отправляем уведомление всем участникам, чтобы они подтвердили свое 
                // согласие на установленную их долю в доходе. 
                // !!! То, что событие будет вызываться для каждой копии картины отдельно - БОЛЬШОЙ НЕДОСТАТОК
                // !!! НАДО БЫ отправить лучше один раз массивом (id полотна, адресат, его доля).
                PercentageApprovalEvent(_tokenId, _addrIncomeParticipants[inv], _percentageParts[inv]);
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
        bool isReady = true;
        Participant[] storage investors = canvasIdToParticipants[_tokenId];
        for (uint8 i = 0; i < investors.length; i++) {
            if (msg.sender == investors[i].participant) {
                // выставляем для текущего адреса свойство подтвреждения
                investors[i].isApproved = true;
            }
            isReady = isReady && investors[i].isApproved;
        }
        // проверяем все ли участники подтверждены и если да, то 
        // выставляем готовность полотна торговаться
        if (isReady) {
            DigitalCanvas storage canvas = digitalCanvases[_tokenId];
            canvas.isReadyForSale = isReady;
        }
    }

    /// @dev Функция проверки существования картины по хешу
    /// @param _hash Хеш полотна
    function isExistCanvasByHash(bytes32 _hash) private view returns (bool) {
        bool _isExist = false;
        for (uint256 i = 0; i < digitalCanvases.length; i++) {
            if (digitalCanvases[i].hashOfCanvas == _hash) {
                _isExist = true;
                break;
            }
        }
        return _isExist;
    }

    // получение списка картин и долей участника, ожидающих его подтверждения
    // function getWaiteApprovalList


    // изменение долевого участия можно только до тех пор, пока картина не выставлена на продажу

}