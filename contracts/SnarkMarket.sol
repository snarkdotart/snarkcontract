pragma solidity ^0.4.21;


import "./SnarkBase.sol";


contract SnarkMarket is SnarkBase {

    // событие на подтверждение согласия участников с их долями
    event NeedApproveOfferEvent(uint256 offerId, address[] _participants, uint8[] _percentAmounts);
    // событие, оповещающее о выставленном предложении выбранного участника системы
    event OfferToEvent(uint256 offerId, address _offerTo);
    // событие, оповещающее об отклонении offerTo чуваков данный оффер
    event OfferToDeclined(uint256 _offerId, address _offerTo);
    // событие, оповещающее, что участник прибыли не согласен с условиями
    event DeclineApprove(uint256 _offerId, address _participant);
    // событие, оповещающее, что offer был удален
    event OfferDeleted(uint256 _offerId);
    // событие, оповещающее об установке нового bid-а
    event NewBidEstablished(uint256 _bidId, address _bidder, uint256 _value);
    // событие, оповещающее, что был отменен бид для цифровой работы
    event BidCanceled(uint256 digitalWorkId);
    // событие, возникающие после продажи работы
    event digitalWorkBoughtEvent(uint256 _tokenId, uint256 price, address seller, address buyer);

    struct Offer {
        // предлагаемая цена в ether для всех работ
        uint price;
        // адрес коллекционера, кому явно выставляется предложение
        address offerTo;
        // признак готовности к продаже (true когда все approve)
        bool isApproved;
        // адреса участников прибыли
        address[] participants;
        // содержит связь участника с размером его доли
        mapping(address => uint8) participantToPercentageAmountMap;
        // содержит связь участника с его подтверждением
        mapping(address => bool) participantToApproveMap;
        // количество работ в данном предложении. Уменьшаем при продаже картины
        uint256 countOfDigitalWorks;
    }

    struct Bid {
        // id полотна
        uint digitalWorkId;
        // предложенная цена за полотно
        uint price;
    }

    // содержит список всех предложений
    Offer[] internal offers;

    // содержит список всех бидов
    Bid[] internal bids;

    // содержит связь цифровой работы с его предложением
    mapping(uint256 => uint256) internal digitalWorkToOfferMap;
    // владелец может делать много оферов, каждый из которых включает кучу разных картин
    mapping(uint256 => address) internal offerToOwnerMap;
    // содержит количество офферов для овнера
    mapping(address => uint256) internal ownerToCountOffersMap;
    // содержит связку бида с его владельцем
    mapping(uint256 => address) internal bidToOwnerMap;
    // содержит связку token с bid
    mapping(uint256 => uint256) internal digitalWorkToBidMap; 
    // счетчик количества бидов для каждого овнера
    mapping(address => uint256) internal bidderToCountBidsMap;
    // содержит признак наличия выставленного бида для цифровой работы
    mapping(uint256 => bool) internal digitalWorkToIsExistBidMap;
    // содержит связку адреса с его балансом
    mapping(address => uint256) public pendingWithdrawals;


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

    /// @dev Модификатор, пропускающий только владельца бида
    modifier onlyBidOwner(uint256 _bidId) {
        require(msg.sender == bidToOwnerMap[_bidId]);
        _;
    }

    // @dev Возвращает количество офферов
    function getCountOfOffers() public view returns (uint256) {
        // меньше на 1, т.к. есть пустой первый оффер
        return offers.length; // - 1;
    }

    /// @dev Возвращает список offers, принадлежащие интересуемому овнеру
    /// @param _owner Адрес интересуемого овнера
    function getOwnerOffersList(address _owner) public view returns (uint256[]) {
        // выделяем массив под то количество, которое записано для этого овнера
        uint256[] memory offersList = new uint256[](ownerToCountOffersMap[_owner]);
        uint256 index = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offerToOwnerMap[i] == _owner) {
                offersList[index++] = i;
            }
        }
        return offersList;
    }

    /// @dev Функция получения всех картин, принадлежащих оферу
    /// @param _offerId Id-шник offer-a
    function getDigitalWorksOffersList(uint256 _offerId) public view returns (uint256[]) {
        require(offers.length > 0);
        // выделяем массив размерности, заданной в оффере
        uint256[] memory offerDigitalWorksList = new uint256[](offers[_offerId].countOfDigitalWorks);
        uint256 index = 0;
        for (uint256 i = 0; i < digitalWorks.length; i++) {
            // если текущая работа принадлежит уже какому-то оферу и этот офер тот, 
            // что нас инетересует, то добавляем его индекс в возвращаемую таблицу
            if (digitalWorkToOfferMap[digitalWorks[i]] == _offerId &&
                digitalWorks[i].saleType == SaleType.Offer) {
                offerDigitalWorksList[index++] = i;
            }
        }
        return offerDigitalWorksList;
    }

    /// @dev Функция создания офера. вызывает событие апрува для участников
    /// @param _tokenIds Список id-шников цифровых работ, которые будут включены в это предложение
    /// @param _price Цена для всех цифровых работ, включенных в это предложение
    /// @param _offerTo Адрес, кому выставляется данное предложение
    /// @param _participants Список участников прибыли
    function createOffer(
        uint256[] _tokenIds, 
        uint256 _price, 
        address _offerTo, 
        address[] _participants,
        uint8[] _percentAmounts
    ) 
        public 
        onlyOwnerOfMany(_tokenIds)
    {
        // создание оффера и получение его id
        uint256 offerId = offers.push(Offer({
            price: _price,
            offerTo: _offerTo,
            isApproved: false,
            participants: address[](0),
            countOfDigitalWorks: _tokenIds.length
        })) - 1;
        // применяем новую схему распределения прибыли
        applyNewSchemaOfProfitDivisionForOffer(offerId, _participants, _percentAmounts);
        // для всех цифровых работ выполняем следующее
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            // в самой работе помечаем, что она участвует в offer
            digitalWorks[_tokenIds[i]].saleType = SaleType.Offer;
            // помечаем к какому offer она принадлежит
            digitalWorkToOfferMap[_tokenIds[i]] = offerId;
        }
        // записываем владельца данного оффера
        offerToOwnerMap[offerId] = msg.sender;
        // увеличиваем количество офферов принадлежащих овнеру
        ownerToCountOffersMap[msg.sender]++;
        // генерим ивент для всех участников, участвующих в дележке прибыли.
        // передаем туда: id текущего оффера, по которому участник сможет получить и просмотреть
        // список картин, а также выставленную цену
        emit NeedApproveOfferEvent(offerId, _participants, _percentAmounts);
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
                applySchemaOfProfitDivision(tokens[i], offer.participants, parts);
            }
        }
        // и только теперь помечаем, что оффер может выставляться на продажу
        offer.isApproved = isAllApproved;
        // если offerTo не пустой и все участники согласны с условиями, 
        // то оповещаем того, для кого это предложение предназначено
        if (offer.offerTo != address(0) && offer.isAllApproved) {
            emit OfferToEvent(_offerId, offer.offerTo);
        }
    }

    /// @dev Получили отказ от offerTo на наше предложение
    /// @param _offerId Id-шник offer-а
    function declineFromOfferTo(uint256 _offerId) public onlyOfferTo(_offerId) {
        // убираем offerTo для данного офера и оставляем его в в общей продаже
        offers[_offerId].offerTo = address(0);
        // генерим событие owner-у, что offerTo послал нафиг
        emit OfferToDeclined(_offerId, msg.sender);
    }

    /// @dev Отказ участника прибыли с предложенными условиями
    /// @param _offerId Id-шник offer-а
    function declineOfferApprove(uint256 _offerId) public onlyOfferParticipator(_offerId) {
        // в этом случае мы только можем только оповестить владельца об отказе
        emit DeclineApprove(_offerId, msg.sender);
    }
    
    /// @dev Удаление offer-а. Вызывается также после продажи последней картины, включенной в оффер.
    /// @param _offerId Id-шник offer-а
    function deleteOffer(uint256 _offerId) public onlyOfferOwner(_offerId) {
        // очищаем все данные в картинах
        uint256[] memory tokens = getDigitalWorksOffersList(_offerId);
        for (uint8 i = 0; i < tokens.length; i++) {
            // "отвязываем" картину от оффера
            digitalWorks[tokens[i]].saleType = SaleType.None;
            // очищаем связи участников с их долями
            deleteSchemaOfProfitDivision(tokens[i]);
            // удаляем связь цифровой работы с оффером
            delete digitalWorkToOfferMap[tokens[i]];
        }
        // удаляем связь оффера с владельцем
        delete offerToOwnerMap[_offerId];
        // уменьшаем счетчик офферов у владельца
        ownerToCountOffersMap[msg.sender]--;
        // удаляем сам оффер из таблицы offers
        for (i = _offerId; i < offers.length - 1; i++) {
            offers[i] = offers[i+1];
        }
        offers.length--;
        // генерим событие о том, что удален оффер
        emit OfferDeleted(_offerId);
    }

    /// @dev Получение списка всех активных offers (которые Approved)
    function getActiveOffersList() public view returns(uint256[]) {
        // пока подготавливаем максимальный размер
        uint256[] memory list = new uint256[](offers.length);
        uint256 index = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].isApproved) list[index++] = i;
        }
        list.length = index;
        return list;
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
        applyNewSchemaOfProfitDivisionForOffer(_offerId, _participants, _percentAmounts);
        // т.к. изменения доли для одного затрагивает всех, то заново всех надо оповещать
        emit NeedApproveOfferEvent(_offerId, _participants, _percentAmounts);
    }

    /// @dev Применяем схему к офферу
    /// @param _offerId Id-шник оффера
    /// @param _participants Массив адресов участников прибыли
    /// @param _percentAmounts Массив долей участников прибыли
    function applyNewSchemaOfProfitDivisionForOffer(
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
            if (_participants[i] == snarkOwner) isSnarkDelivered = true;
        }
        // ну и не забываем про себя любимых, т.е. Snark, если он чуть выше не был передан и обработан
        if (isSnarkDelivered == false) {
            // записываем адрес Snark
            offer.participants.push(snarkOwner); 
            // записываем долю Snark
            offer.participantToPercentageAmountMap[snarkOwner] = snarkPercentageAmount;
        }
        // и сразу апруваем Snark
        offer.participantToApproveMap[snarkOwner] = true;
    }
 
    /// @dev Функция, выставляющая bid для выбранного токена
    /// @param _tokenId Токен, который хотят приобрести
    function setBid(uint256 _tokenId) public payable {
        // нам не важно, доступен ли токен для продажи, поэтому
        // принимать bid мы можем всегда, за исключением, когда
        // цифровая работа выставлена на аукцион
        require(digitalWorks[_tokenId].saleType != SaleType.Auction);
        // токен не должен принадлежать тому, кто выставляет bid
        require(tokenToOwner[_tokenId] != msg.sender);
        require(msg.sender != address(0));

        uint256 bidId;
        if (digitalWorkToIsExistBidMap[_tokenId]) {
            // если для выбранной цифровой работы bid уже был задан, то получаем его id-шник 
            bidId = digitalWorkToBidMap[_tokenId];
            // получаем сам бид по его id-шнику
            Bid storage bid = bids[bidId];
            // если такой бид уже существует у нас, то выполняем проверки
            if (bid.digitalWorkId == _tokenId) {
                // выставленный bid однозначно должен быть больше предыдущего, как минимум на 5%
                require(msg.value >= bid.price + (bid.price * 5 / 100));
                // предыдущему бидеру нужно вернуть его сумму
                if (bid.price > 0) {
                    // записываем сумму ему же на "вексель", которые позже он сам может изъять
                    // pendingWithdrawals[bidToOwnerMap[bidId]] += bid.price;

                    // возвращаем денежку предыдущему биддеру
                    bidToOwnerMap[bidId].transfer(bid.price);
                    // уменьшаем счетчик количества бидов у биддера
                    bidderToCountBidsMap[bidToOwnerMap[bidId]]--;
                }
            } 
            // теперь устанавливаем новую цену
            bid.price = msg.value;
        } else {
            // бида с таким tokenId у нас небыло раньше, поэтому формируем
            bidId = bids.push(Bid({
                digitalWorkId: _tokenId,
                price: msg.value
            })) - 1;
            // т.к. для работы может быть выставлен только один бид, то его мы и присваиваем этой работе
            digitalWorkToBidMap[_tokenId] = bidId;
            // помечаем, что для данной работы бид был выставлен
            digitalWorkToIsExistBidMap[_tokenId] = true;
        }
        // устанавливаем нового владельца этого бида
        bidToOwnerMap[bidId] = msg.sender;
        // увеличиваем количество бидов у биддера
        bidderToCountBidsMap[msg.sender]++;
        // формируем событие о создании нового бида для токена
        emit NewBidEstablished(bidId, msg.value);
    }
    
    /// @dev отмена своего бида
    /// @param _bidId Id bid
    function cancelBid(uint256 _bidId) public onlyBidOwner(_bidId) {
        // получаем адрес, кто являлся владельцев бида
        address bidder = bidToOwnerMap[_bidId];
        uint256 bidValue = bids[_bidId].price;
        uint256 digitalWorkId = bids[_bidId].digitalWorkId;
        // уменьшаем счетчик количества бидов у биддера
        bidderToCountBidsMap[bidder]--;
        // удаляем привязку цифровой работы с бидом
        delete digitalWorkToBidMap[digitalWorkId];
        // удаляем привязку бида с владельцем
        delete bidToOwnerMap[_bidId];
        // помечаем, что цифровая работа не имеет бидов
        digitalWorkToIsExistBidMap[digitalWorkId] = false;
        // удаляем запись из таблицы бидов
        for (uint256 i = _bidId; i < bids.length - 1; i++) {
            bids[i] = bids[i+1];
        }
        bids.length--;
        // предыдущему бидеру нужно вернуть его сумму
        bidder.transfer(bidValue);
        // генерим событие о том, что бид был удален
        emit BidCanceled(digitalWorkId);
    }

    // функция принятия бида и продажи предложившему. снять все оферы и биды.
    function acceptBid(uint256 _bidId) public {}

    // функция продажи картины. снять все оферы и биды для картины.
    /// @dev Фукнция совершения покупки полотна
    /// @param _tokenId Токен, который покупают
    function buyDigitalWork(uint256 _tokenId) public payable {
        require(_tokenId != 0);
        Offer storage offer = offers[_tokenId];
        DigitalWork storage digitalWork = digitalWorks[_tokenId];
        address seller = offer.seller;
        address buyer = msg.sender;
        require(digitalWork.isForSale); // совершить покупку можно лишь только того полотна, которое выставлено на продажу
        require(msg.value >= offer.price); // переданное количество денег не должно быть меньше установленной цены
        // покупатель должен быть либо не установлен заранее, либо установлен на того, 
        // кто сейчас пытается купить это полотно
        require(offer.offerTo == address(0) || offer.offerTo == buyer);
        require(ownerOf(_tokenId) != buyer); // нельзя продать самому себе
        tokenToOwner[_tokenId] = buyer; // устанавливаем владельцем текущего пользователя
        _transfer(seller, buyer, _tokenId); // производим передачу токена (смотри SnarkOwnership)
        // теперь необходимо выявить доход, и если он был, то произвести
        // распределение дохода, согласно долей участников. Расчет в weis.
        if (digitalWork.lastPrice < msg.value && (msg.value - digitalWork.lastPrice) >= 100) {
            uint256 profit = msg.value - digitalWork.lastPrice; // вычисляем доход, полученный при продаже.
            if (digitalWork.isItFirstSelling) { // проверяем первичная ли эта продажа или нет
                digitalWork.isItFirstSelling = false; // помечаем, что первичная продажа закончилась
            } else {
                // если вторичная продажа, то профит уменьшаем до заданного художником значения в процентах
                // при этом же оставшая сумма должна перейти продавцу
                uint256 amountToSeller = profit;
                profit = profit * digitalWork.artistPart / 100; // сумма, которая будет распределяться
                amountToSeller -= profit; // сумма, которая уйдет продавцу
                pendingWithdrawals[seller] += amountToSeller;
            }
            uint256 residue = profit; // тут будем хранить остаток, после выплаты всем участникам
            Participant[] storage participants = digitalWorkIdToParticipants[_tokenId]; // получаем список участников прибыли
            for (uint8 i = 0; i < participants.length; i++) { // по очереди обрабатываем участников выплат
                uint256 payout = profit * participants[i].persentageAmount / 100; // вычисляем сумму выплаты
                pendingWithdrawals[participants[i].participant] += payout; // и выплачиваем
                residue -= payout; // вычисляем остаток после выплаты
            }
            if (seller != digitalWork.artist && digitalWork.isItFirstSelling == false) {
                pendingWithdrawals[digitalWork.artist] += residue; // вторичная продажа, художнику - остаток
            } else {
                pendingWithdrawals[offer.seller] += residue; // первичная продажа, продавцу - остаток
            }
        } else {
            pendingWithdrawals[offer.seller] += msg.value; // если дохода нет, то все оставляем себе
        }
        digitalWork.lastPrice = msg.value; // записываем по какой цене полотно было куплено
        digitalWork.isForSale = false; // снимаем с продажи
        emit digitalWorkBoughtEvent(_tokenId, msg.value, seller, buyer); // геренируем событие покупки токена
        Bid storage bid = bids[_tokenId];
        if (bid.bidder == buyer) { // если покупатель выставлял bid, то необходимо его ему вернуть
            pendingWithdrawals[buyer] += bid.value;
            bids[_tokenId] = Bid(_tokenId, false, address(0), 0);
        }
    }

    // просмотреть все свои биды
    function getBidList(address owner) public view {}

    // просмотреть сколько у чувака есть денег тут у нас в контракте, чтобы мог вывести себе на кошелек
    function getWithdrawBalance(address owner) public view {}

    // функция вывода средств себе на кошелек withdraw funds
    function withdrawFunds(address owner) public {}

/********************************************************************************************************/

    /// @dev Функция позволяет тказаться от bid и вернуть деньги себе на кошелек
    /// @param _tokenId Токен, от которого хотят отказаться
    function withdrawBid(uint256 _tokenId) public {
        // вызвавший не должен быть владельцем полотна
        require(tokenToOwner[_tokenId] != msg.sender);

        Bid storage bid = bids[_tokenId];

        // вызов должен быть только тем, кто является бидером
        require(msg.sender == bid.bidder);

        // запоминаем предыдущую стоимость
        uint256 amount = bid.value;

        // забиваем бид пустышкой
        bids[_tokenId] = Bid(_tokenId, false, address(0), 0);

        // возвращаем денежку
        msg.sender.transfer(amount);
    }

}
