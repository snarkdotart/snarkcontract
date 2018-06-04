pragma solidity ^0.4.24;

import "./SnarkBase.sol";


contract SnarkOfferBid is SnarkBase {

    // событие, оповещающее о созданни нового оффера
    event OfferCreatedEvent(uint256 offerId, address indexed _offerTo);
    // событие на подтверждение согласия участников с их долями
    event NeedApproveOfferEvent(uint256 offerId, address indexed _participant, uint8 _percentAmount);
    // событие, оповещающее, что участник прибыли не согласен с условиями
    event DeclineApproveOfferEvent(uint256 _offerId, address indexed _offerOwner, address indexed _participant);
    // событие, оповещающее об отклонении offerTo чуваков данный оффер
    event OfferToAddressDeclinedEvent(uint256 _offerId, address indexed _offerTo);
    // событие, оповещающее, что offer был удален
    event OfferDeletedEvent(uint256 _offerId);
    // события, оповещающие, что закончился оффер (продались все картины)
    event OfferEndedEvent(uint256 _offerId);
    // событие, оповещающее об установке нового bid-а
    event BidSettedUpEvent(uint256 _bidId, address indexed _bidder, uint256 _value);
    // событие, оповещающее, что был отменен бид для цифровой работы
    event BidCanceledEvent(uint256 _digitalWorkId);
    // событие, возникающие после продажи работы
    event DigitalWorkBoughtEvent(uint256 _tokenId, uint256 price, address seller, address buyer);

    // There are 4 states for an Offer and an Auction:
    // Preparing - "подготавливается", только создался и не апрувнут участниками
    // NotActive - апрувнут участниками, но не работает еще (это только у аукциона)
    // Active - активный, когда начал участвовать в продаже картин
    // Finished - завершенный, когда все картины проданы
    enum SaleStatus { Preparing, NotActive, Active, Finished }
    // тип продажи, в которой участвует цифровая работа
    enum SaleType { None, Offer, Auction, Renting }

    struct Offer {
        // предлагаемая цена в ether для всех работ
        uint256 price;
        // адрес коллекционера, кому явно выставляется предложение
        address offerTo;
        // адреса участников прибыли
        address[] participants;
        // содержит связь участника с размером его доли
        mapping (address => uint8) participantToPercentageAmountMap;
        // содержит связь участника с его подтверждением
        mapping (address => bool) participantToApproveMap;
        // количество работ в данном предложении. Уменьшаем при продаже картины
        uint256 countOfDigitalWorks;
        // offer status (we use 3 states only: Preparing, Active, Finished)
        SaleStatus saleStatus;
    }

    struct Bid {
        // id полотна
        uint digitalWorkId;
        // предложенная цена за полотно
        uint price;
        // статус предложения (используем только 2 состояния: Active, Finished)
        SaleStatus saleStatus;
    }

    // содержит список всех предложений
    Offer[] internal offers;

    // содержит список всех бидов ?????
    Bid[] internal bids;

    // содержит связь цифровой работы с его предложением
    mapping (uint256 => uint256) internal tokenToOfferMap;
    // Mapping lists of tokens to offers
    mapping (uint256 => uint256[]) internal offerToTokensMap;
    // владелец может делать много оферов, каждый из которых включает кучу разных картин
    mapping (uint256 => address) internal offerToOwnerMap;
    // Offers list belongs to owner
    mapping (address => uint256[]) internal ownerToOffersMap;
    // Mapping status to count
    mapping (uint8 => uint256[]) internal saleStatusToOffersMap;
    // содержит связку бида с его владельцем
    mapping (uint256 => address) internal bidToOwnerMap;
    // Mapping from address to Bids list
    mapping (address => uint256[]) internal ownerToBidsMap;
    // содержит связку token с bid
    mapping (uint256 => uint256) internal tokenToBidMap; 
    // содержит признак наличия выставленного бида для цифровой работы
    mapping (uint256 => bool) internal digitalWorkToIsExistBidMap;
    // содержит связку адреса с его балансом
    mapping (address => uint256) public pendingWithdrawals;
    // картина может находиться только в одном из четырех состояний:
    // 1. либо не продаваться
    // 2. либо продаваться через обычное предложение
    // 3. либо продаваться через аукцион
    // 4. либо сдаваться в аренду
    // Это необходимо для исключения возможности двойной продажи 
    mapping (uint256 => SaleType) internal tokenToSaleTypeMap;

    /// @dev Модификатор, пропускающий только участников дохода для этого оффера
    modifier onlyOfferParticipator(uint256 _offerId) {
        bool isItParticipant = false;
        address[] storage p = offers[_offerId].participants;
        for (uint8 i = 0; i < p.length; i++) {
            if (msg.sender == p[i]) isItParticipant = true;
        }
        require(isItParticipant);
        _;
    }

    /// @dev Модификатор, отсекающий чужих offerTo
    modifier onlyOfferTo(uint256 _offerId) {
        require(msg.sender == offers[_offerId].offerTo);
        _;
    }

    /// @dev Модификатор, пропускающий только владельца оффера
    modifier onlyOfferOwner(uint256 _offerId) {
        require(msg.sender == offerToOwnerMap[_offerId]);
        _;
    }
    
    /// @dev Модификатор, проверяющий, чтобы работы не участвовали в продажах где-то еще
    modifier onlyNoneStatus(uint256[] _tokenIds) {
        bool isStatusNone = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isStatusNone = (isStatusNone && (tokenToSaleTypeMap[_tokenIds[i]] == SaleType.None));
        }
        require(isStatusNone);
        _;
    }

    // @dev Модификатор, проверяющий картины на соответствие первичной продажи
    modifier onlyFirstSale(uint256[] _tokenIds) {
        bool isFistSale = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isFistSale = (isFistSale && digitalWorks[_tokenIds[i]].isItFirstSelling);
        }
        require(isFistSale);
        _;
    }

    // @dev Модификатор, проверяющий картины на соответствие вторичной продажи
    modifier onlySecondSale(uint256[] _tokenIds) {
        bool isSecondSale = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isSecondSale = (isSecondSale && !digitalWorks[_tokenIds[i]].isItFirstSelling);
        }
        require(isSecondSale);
        _;
    }    

    /// @dev Модификатор, проверяющий переданный id оффера на попадание в интервал
    modifier correctOfferId(uint256 _offerId) {
        require(offers.length > 0);
        require(_offerId < offers.length);
        _;
    }

    /// @dev Модификатор, пропускающий только владельца бида
    modifier onlyBidOwner(uint256 _bidId) {
        require(msg.sender == bidToOwnerMap[_bidId]);
        _;
    }

    /// @dev Возвращает количество офферов с интересуемым статусом
    /// @param _status Интересуемый статус SaleStatus
    function getCountOfOffers(uint8 _status) public view returns (uint256) {        
        require(uint8(SaleStatus.Finished) >= _status);
        return saleStatusToOffersMap[_status].length;
    }

    /// @dev Return a list of offers which belong to owner
    /// @param _owner Owner address
    function getOwnerOffersList(address _owner) public view returns (uint256[]) {
        return ownerToOffersMap[_owner];
    }

    /// @dev Функция получения всех картин, принадлежащих оферу
    /// @param _offerId Id-шник offer-a
    function getDigitalWorksOffersList(uint256 _offerId) public view correctOfferId(_offerId) returns (uint256[]) {
        return offerToTokensMap[_offerId];
    }

    /// @dev Функция создания офера первичной продажи. вызывает событие апрува для участников
    /// @param _tokenIds Список id-шников цифровых работ, которые будут включены в это предложение
    /// @param _price Цена для всех цифровых работ, включенных в это предложение
    /// @param _offerTo Адрес, кому выставляется данное предложение
    /// @param _participants Список участников прибыли
    /// @param _percentAmounts Список процентных долей участников
    function createOffer(
        uint256[] _tokenIds, 
        uint256 _price, 
        address _offerTo, 
        address[] _participants,
        uint8[] _percentAmounts
    ) 
        public 
        onlyOwnerOfMany(_tokenIds)
        onlyNoneStatus(_tokenIds)
        onlyFirstSale(_tokenIds)
    {
        // создание оффера и получение его id
        uint256 offerId = offers.push(Offer({
            price: _price,
            offerTo: _offerTo,
            participants: new address[](0),
            countOfDigitalWorks: _tokenIds.length,
            saleStatus: SaleStatus.Preparing
        })) - 1;
        // применяем новую схему распределения прибыли
        _applyNewSchemaOfProfitDivisionForOffer(offerId, _participants, _percentAmounts);
        // для всех цифровых работ выполняем следующее
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            // в самой работе помечаем, что она участвует в offer
            tokenToSaleTypeMap[_tokenIds[i]] = SaleType.Offer;
            // помечаем к какому offer она принадлежит
            tokenToOfferMap[_tokenIds[i]] = offerId;
            // add token to offer list
            offerToTokensMap[offerId].push(_tokenIds[i]);
        }
        // count offers with saleType = Offer
        saleStatusToOffersMap[uint8(SaleStatus.Preparing)].push(offerId);
        // записываем владельца данного оффера
        offerToOwnerMap[offerId] = msg.sender;
        // увеличиваем количество офферов принадлежащих овнеру
        ownerToOffersMap[msg.sender].push(offerId);
        // генерим ивент для всех участников, участвующих в дележке прибыли.
        // передаем туда: id текущего оффера, по которому участник сможет получить и просмотреть
        // список картин, а также выставленную цену
        for (i = 0; i < _participants.length; i++) {
            // оповещаем адресно
            emit NeedApproveOfferEvent(offerId, _participants[i], _percentAmounts[i]);
        }
    }

    /// @dev Функция создания офера для вторичной продажи
    /// @param _tokenIds Список id-шников цифровых работ, которые будут включены в это предложение
    /// @param _price Цена для всех цифровых работ, включенных в это предложение
    /// @param _offerTo Адрес, кому выставляется данное предложение
    function createOffer(
        uint256[] _tokenIds, 
        uint256 _price, 
        address _offerTo
    ) 
        public 
        onlyOwnerOfMany(_tokenIds)
        onlyNoneStatus(_tokenIds)
        onlySecondSale(_tokenIds)
    {
        // создание оффера и получение его id
        uint256 offerId = offers.push(Offer({
            price: _price,
            offerTo: _offerTo,
            participants: new address[](0),
            countOfDigitalWorks: _tokenIds.length,
            saleStatus: SaleStatus.Preparing
        })) - 1;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            // в самой работе помечаем, что она участвует в offer
            tokenToSaleTypeMap[_tokenIds[i]] = SaleType.Offer;
            // помечаем к какому offer она принадлежит
            tokenToOfferMap[_tokenIds[i]] = offerId;
            // add token to offer list
            offerToTokensMap[offerId].push(_tokenIds[i]);
        }
        // count offers with saleType = Offer
        saleStatusToOffersMap[uint8(SaleStatus.Preparing)].push(offerId);
        // записываем владельца данного оффера
        offerToOwnerMap[offerId] = msg.sender;
        // увеличиваем количество офферов принадлежащих овнеру
        ownerToOffersMap[msg.sender].push(offerId);
        // сообщаем, что был создан новый оффер
        emit OfferCreatedEvent(offerId, offers[offerId].offerTo);
    }

    /// @dev Участник прибыли подтверждает свое согласие на выставленные условия
    /// @param _offerId id-шник оффера
    function approveOffer(uint256 _offerId) public onlyOfferParticipator(_offerId) {
        Offer storage offer = offers[_offerId];
        // отмечаем текущего участника, как согласного с условиями
        offer.participantToApproveMap[msg.sender] = true;
        // проверяем все ли согласились или нет, а за одно формируем массив долей для участников
        bool isAllApproved = true;
        uint8[] memory parts = new uint8[](offer.participants.length);
        for (uint8 i = 0; i < offer.participants.length; i++) {
            isAllApproved = isAllApproved && offer.participantToApproveMap[offer.participants[i]];
            parts[i] = offer.participantToPercentageAmountMap[offer.participants[i]];
        }
        // если все согласны, то копируем условия в сами картины, дабы каждая картина имела возможность,
        // в последствие, знать условия распределения прибыли
        if (isAllApproved) {
            uint256[] memory tokens = getDigitalWorksOffersList(_offerId);
            for (i = 0; i < tokens.length; i++) {
                _applySchemaOfProfitDivision(tokens[i], offer.participants, parts);
            }
        }
        // и только теперь помечаем, что оффер может выставляться на продажу
        if (isAllApproved) _moveOfferToNextStatus(_offerId);
        emit OfferCreatedEvent(_offerId, offer.offerTo);
    }

    /// @dev Получили отказ от offerTo на наше предложение
    /// @param _offerId Id-шник offer-а
    function declineFromOfferTo(uint256 _offerId) public onlyOfferTo(_offerId) {
        // убираем offerTo для данного офера и оставляем его в в общей продаже
        offers[_offerId].offerTo = address(0);
        // генерим событие owner-у, что offerTo послал нафиг
        emit OfferToAddressDeclinedEvent(_offerId, msg.sender);
    }

    /// @dev Отказ участника прибыли с предложенными условиями
    /// @param _offerId Id-шник offer-а
    function declineOfferApprove(uint256 _offerId) public view onlyOfferParticipator(_offerId) {
        // в этом случае мы только можем только оповестить владельца об отказе
        emit DeclineApproveOfferEvent(_offerId, offerToOwnerMap[_offerId], msg.sender);
    }
    
    /// @dev Удаление offer-а. Вызывается также после продажи последней картины, включенной в оффер.
    /// @param _offerId Id-шник offer-а
    function deleteOffer(uint256 _offerId) public onlyOfferOwner(_offerId) {
        // очищаем все данные в картинах
        uint256[] memory tokens = getDigitalWorksOffersList(_offerId);
        for (uint8 i = 0; i < tokens.length; i++) {
            // drop down a sale status to None
            tokenToSaleTypeMap[tokens[i]] = SaleType.None;
            // удаляем связь цифровой работы с оффером
            delete tokenToOfferMap[tokens[i]];
        }
        address owner = offerToOwnerMap[_offerId];
        // удаляем связь оффера с владельцем
        delete offerToOwnerMap[_offerId];
        // delete the offer from owner
        uint256[] storage ownerOffers = ownerToOffersMap[owner];
        for (i = 0; i < ownerOffers.length; i++) {
            if (ownerOffers[i] == _offerId) {
                ownerOffers[i] = ownerOffers[ownerOffers.length - 1];
                ownerOffers.length--;
                break;
            }
        }
        // помечаем оффер, как завершившийся
        _moveOfferToNextStatus(_offerId);
        // генерим событие о том, что удален оффер
        emit OfferDeletedEvent(_offerId);
    }

    /// @dev Получение списка всех активных offers (которые Approved)
    /// @param status
    function getOffersListByStatus(uint8 _status) public view returns(uint256[]) {
        return saleStatusToOffersMap[_status];
    }

    /// @dev Функция модификации участников и их долей для offera, в случае отклонения одним из участников
    /// @param _offerId Id-шник оффера
    /// @param _participants Массив адресов участников прибыли
    /// @param _percentAmounts Массив долей участников прибыли
    function setNewSchemaOfProfitDivisionForOffer(
        uint256 _offerId,
        address[] _participants,
        uint8[] _percentAmounts
    )
        public
        onlyOfferOwner(_offerId)
    {
        // длины массивов должны совпадать
        require(_participants.length == _percentAmounts.length);
        // применяем новую схему
        _applyNewSchemaOfProfitDivisionForOffer(_offerId, _participants, _percentAmounts);
        // т.к. изменения доли для одного затрагивает всех, то заново всех надо оповещать
        for (uint256 i = 0; i < _participants.length; i++) {
            // оповещаем адресно
            emit NeedApproveOfferEvent(_offerId, _participants[i], _percentAmounts[i]);
        }
    }
 
    /// @dev Функция, выставляющая bid для выбранного токена
    /// @param _tokenId Токен, который хотят приобрести
    function setBid(uint256 _tokenId) public payable {
        // нам не важно, доступен ли токен для продажи, поэтому
        // принимать bid мы можем всегда, за исключением, когда
        // цифровая работа выставлена на аукцион
        require(tokenToSaleTypeMap[_tokenId] != SaleType.Auction);
        // токен не должен принадлежать тому, кто выставляет bid
        require(tokenToOwnerMap[_tokenId] != msg.sender);
        require(msg.sender != address(0));

        uint256 bidId;
        if (digitalWorkToIsExistBidMap[_tokenId]) {
            // если для выбранной цифровой работы bid уже был задан, то получаем его id-шник 
            bidId = tokenToBidMap[_tokenId];
            // получаем сам бид по его id-шнику
            Bid storage bid = bids[bidId];
            // выставленный bid однозначно должен быть больше предыдущего, как минимум на 5%
            require(msg.value >= bid.price + (bid.price * 5 / 100));
            // предыдущему бидеру нужно вернуть его сумму
            if (bid.price > 0) {
                // записываем сумму ему же на "вексель", которые позже он сам может изъять
                pendingWithdrawals[bidToOwnerMap[bidId]] += bid.price;
                // delete the bid from the bidder
                for (uint8 i = 0; i < ownerToBidsMap[msg.sender].length; i++) {
                    if (ownerToBidsMap[msg.sender][i] == bidId) {
                        ownerToBidsMap[msg.sender][i] = 
                            ownerToBidsMap[msg.sender][ownerToBidsMap[msg.sender].length - 1];
                        ownerToBidsMap[msg.sender].length--;
                        break;
                    }
                }
            }
            // теперь устанавливаем новую цену
            bid.price = msg.value;
        } else {
            // бида с таким tokenId у нас небыло раньше, поэтому формируем
            bidId = bids.push(Bid({
                digitalWorkId: _tokenId,
                price: msg.value,
                saleStatus: SaleStatus.Active
            })) - 1;
            // т.к. для работы может быть выставлен только один бид, то его мы и присваиваем этой работе
            tokenToBidMap[_tokenId] = bidId;
            // помечаем, что для данной работы бид был выставлен
            digitalWorkToIsExistBidMap[_tokenId] = true;
        }
        // устанавливаем нового владельца этого бида
        bidToOwnerMap[bidId] = msg.sender;
        ownerToBidsMap[msg.sender].push(bidId);
        // формируем событие о создании нового бида для токена
        emit BidSettedUpEvent(bidId, msg.sender, msg.value);
    }
    
    /// @dev Allows to decline your own bid
    /// @param _bidId Id bid
    function cancelBid(uint256 _bidId) public onlyBidOwner(_bidId) {
        address bidder = bidToOwnerMap[_bidId];
        uint256 bidValue = bids[_bidId].price;
        uint256 digitalWorkId = bids[_bidId].digitalWorkId;
        _deleteBid(_bidId);
        bidder.transfer(bidValue);
        emit BidCanceledEvent(digitalWorkId);
    }

    /// @dev Просмотреть все свои биды
    /// @param _owner Адрес, для которого хотим получить список всех бидов
    function getBidList(address _owner) public view returns (uint256[]) {
        return ownerToBidsMap[_owner];
    }

    /// @dev Просмотреть сколько у чувака есть денег тут у нас в контракте, чтобы мог вывести себе на кошелек
    /// @param _owner Адрес, для которого хотим получить баланс 
    function getWithdrawBalance(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return pendingWithdrawals[_owner];
    }

    /// @dev Функция вывода средств себе на кошелек withdraw funds
    /// @param _owner Адрес, который хочет вывести средства
    function withdrawFunds(address _owner) public {
        require(_owner != address(0));
        uint256 balance = pendingWithdrawals[_owner];
        delete pendingWithdrawals[_owner];
        _owner.transfer(balance);
    }

    /// @dev Switch sale status to the next
    /// @param _offerId Offer Id
    function _moveOfferToNextStatus(uint256 _offerId) internal {
        uint8 prevStatus = uint8(offers[_offerId].saleStatus);
        if (prevStatus < uint8(SaleStatus.Finished)) {
            for (uint8 i = 0; i < saleStatusToOffersMap[prevStatus].length; i++) {
                if (saleStatusToOffersMap[prevStatus][i] == _offerId) {
                    saleStatusToOffersMap[prevStatus][i] =
                        saleStatusToOffersMap[prevStatus][saleStatusToOffersMap[prevStatus].length - 1];
                    saleStatusToOffersMap[prevStatus].length--;
                    break;
                }
            }
            uint8 newStatus = (prevStatus == 0) ? prevStatus + 2 : prevStatus + 1;
            saleStatusToOffersMap[newStatus].push(_offerId);
            offers[_offerId].saleStatus = SaleStatus(newStatus);
        }
    }

    /// @dev Применяем схему к офферу
    /// @param _offerId Id-шник оффера
    /// @param _participants Массив адресов участников прибыли
    /// @param _percentAmounts Массив долей участников прибыли
    function _applyNewSchemaOfProfitDivisionForOffer(
        uint256 _offerId,
        address[] _participants,
        uint8[] _percentAmounts
    ) 
        private
    {
        // удаляем все, ибо могли исключить кого-то из участников и добавить новых
        Offer storage offer = offers[_offerId];
        for (uint8 i = 0; i < offer.participants.length; i++) {
            // удаляем процентные доли
            delete offer.participantToPercentageAmountMap[offer.participants[i]];
            // удаляем "согласия", ибо уже изменились значения для всех
            delete offer.participantToApproveMap[offer.participants[i]];
        }
        offer.participants.length = 0;
        // применяем новую схему
        bool isSnarkDelivered = false;
        // заполняем список участников прибыли
        for (i = 0; i < _participants.length; i++) {
            // сначала сохраняем адрес участника
            offer.participants.push(_participants[i]);
            // а затем его долю
            offer.participantToPercentageAmountMap[_participants[i]] = _percentAmounts[i];
            // на тот случай, если с клиента уже будет приходить информация о доле Snark
            if (_participants[i] == owner) isSnarkDelivered = true;
        }
        // ну и не забываем про себя любимых, т.е. Snark, если он чуть выше не был передан и обработан
        if (isSnarkDelivered == false) {
            // записываем адрес Snark
            offer.participants.push(owner); 
            // записываем долю Snark
            offer.participantToPercentageAmountMap[owner] = snarkPercentageAmount;
        }
        // и сразу апруваем Snark
        offer.participantToApproveMap[owner] = true;
    }

    /// @dev Удаление бида из основной таблицы бидов
    /// @param _bidId Id bid
    function _deleteBid(uint256 _bidId) private {
        // delete the bid from the bidder
        address bidder = bidToOwnerMap[_bidId];
        for (uint8 i = 0; i < ownerToBidsMap[bidder].length; i++) {
            if (ownerToBidsMap[bidder][i] == _bidId) {
                ownerToBidsMap[bidder][i] = 
                    ownerToBidsMap[bidder][ownerToBidsMap[bidder].length - 1];
                ownerToBidsMap[bidder].length--;
                break;
            }
        }
        // удаляем привязку цифровой работы с бидом
        delete tokenToBidMap[bids[_bidId].digitalWorkId];
        // удаляем привязку бида с владельцем
        delete bidToOwnerMap[_bidId];
        // помечаем, что цифровая работа не имеет бидов
        digitalWorkToIsExistBidMap[bids[_bidId].digitalWorkId] = false;
        // помечаем, что этот бид завершил свою работу
        bids[_bidId].saleStatus = SaleStatus.Finished;
    }

    /// @dev Функция распределения прибыли
    /// @param _price Цена, за которую продается цифровая работа
    /// @param _tokenId Id цифровой работы
    /// @param _from Адрес продавца
    function _incomeDistribution(uint256 _price, uint256 _tokenId, address _from) private {
        // распределяем прибыль согласно схеме, содержащейся в самой картине
        DigitalWork storage digitalWork = digitalWorks[_tokenId];
        // вычисляем прибыль предварительно
        if (digitalWork.lastPrice < _price && (_price - digitalWork.lastPrice) >= 100) {
            uint256 profit = _price - digitalWork.lastPrice;
            // проверяем первичная ли эта продажа или нет
            if (digitalWork.isItFirstSelling) { 
                // если да, то помечаем, что первичная продажа закончилась
                digitalWork.isItFirstSelling = false;
            } else {
                // если вторичная продажа, то профит уменьшаем до заданного художником значения в процентах
                // при этом же оставшая сумма должна перейти продавцу
                uint256 amountToSeller = profit;
                // сумма, которая будет распределяться
                profit = profit * digitalWork.appropriationPercentForSecondTrade / 100;
                // сумма, которая уйдет продавцу
                amountToSeller -= profit;
                pendingWithdrawals[_from] += amountToSeller;
            }
            uint256 residue = profit; // тут будем хранить остаток, после выплаты всем участникам
            for (uint8 i = 0; i < digitalWork.participants.length; i++) { // по очереди обрабатываем участников выплат
                // вычисляем сумму выплаты
                uint256 payout = profit * digitalWork.participantToPercentMap[digitalWork.participants[i]] / 100;
                pendingWithdrawals[digitalWork.participants[i]] += payout; // и переводим ему на "вексель"
                residue -= payout; // вычисляем остаток после выплаты
            }
            // если вдруг что-то осталось после распределения, то остаток переводим продавцу
            pendingWithdrawals[_from] += residue;
        } else {
            // если дохода нет, то все зачисляем продавцу
            pendingWithdrawals[_from] += _price; 
        }
        // запоминаем цену, по которой продались, в lastPrice в картине
        digitalWork.lastPrice = _price;
        // помечаем, что не имеет никаких статусов продажи
        tokenToSaleTypeMap[_tokenId] = SaleType.None;
    }
}
