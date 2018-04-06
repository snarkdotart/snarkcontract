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

    // содержит список всех предложений
    Offer[] internal offers;

    // содержит связь цифровой работы с его предложением
    mapping(uint256 => uint256) internal digitalWorkToOfferMap;

    // владелец может делать много оферов, каждый из которых включает кучу разных картин
    mapping(uint256 => address) internal offerToOwnerMap;

    // содержит количество офферов для овнера
    mapping(address => uint256) internal ownerToCountOffersMap;

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

    // @dev Модификатор, пропускающий только владельца оффера
    modifier onlyOfferOwner(uint256 _offerId) {
        require(msg.sender == offerToOwnerMap[_offerId]);
        _;
    }

    // function SnarkMarket() public {
        // добавляем пустой Offer в качестве первого
        // предполагаем, что картина по умолчанию ссылается на нулевой оффер,
        // либо ссылается на него сразу после продажи
        // isApproved = false для отсекания попадания этого офера в список активных
        // offers.push(Offer({
        //     price: 0,
        //     offerTo: address(0),
        //     isApproved: false,
        //     isAllSoldOut: true,
        //     participants: address[](0),
        //     countOfDigitalWorks: 0
        // }));
    // }

    // @dev Возвращает количество офферов
    function getCountOfOffers() public view returns (uint256) {
        // меньше на 1, т.к. есть пустой первый оффер
        return offers.length; // - 1;
    }

    /// @dev Проверка на пустой оффер
    /// @param _offerId Id-шник offer-a
    // function isItEmptyOffer(uint256 _offerId) public view returns (bool) {
    //     return (
    //         offers[_offerId].price == 0 &&
    //         offers[_offerId].offerTo.length == 0 &&
    //         offers[_offerId].isApproved == false &&
    //         offers[_offerId].isAllSoldOut == true &&
    //         offers[_offerId].participants.length == 0 &&
    //         offers[_offerId].countOfDigitalWorks == 0 
    //     );
    // }

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
        bool isSnarkDelivered = false;
        // заполняем список участников прибыли
        for (uint8 i = 0; i < _participants.length; i++) {
            // сначала сохраняем адрес участника
            offers[offerId].participants.push(_participants[i]);
            // а затем его долю
            offers[offerId].participantToPercentageAmountMap[_participants[i]] = _percentAmounts[i];
            // на тот случай, если с клиента уже будет приходить информация о доле Snark
            if (_participants[i] == snarkOwner) isSnarkDelivered = true;
        }
        // ну и не забываем про себя любимых, т.е. Snark, если он чуть выше не был передан и обработан
        if (isSnarkDelivered == false) {
            // записываем адрес Snark
            offers[offerId].participants.push(snarkOwner); 
            // записываем долю Snark
            offers[offerId].participantToPercentageAmountMap[snarkOwner] = snarkPercentageAmount;
        }
        // и сразу апруваем Snark
        offers[offerId].participantToApproveMap[snarkOwner] = true;
        // для всех цифровых работ выполняем следующее
        for (i = 0; i < _tokenIds.length; i++) {
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

    // !!!!!!!! Вопросы по фукнциональности: !!!!!!!!
    // Надо ли показывать в общей куче офферов те, офферы, которые выставлены адресно, т.е. имеют offerTo 
    // Что делать в случае отклонения/отказа чувака offerTo от этого предложения?

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

    // функция модификации участников и их долей в случае отклонения

    // функция продажи картины. снять все оферы и биды для картины.
    // функция принятия бида и продажи. снять все оферы и биды.
    /// @dev Проверяем, не прода

/********************************************************************************************************/
    struct Bid {
        // id полотна
        uint digitalWorkId;
        // активен ли текущий бид
        bool isActive;
        // адрес, выставившего bid
        address bidder;
        // предложенная цена за полотно
        uint price;
    }

    // 1. Создается bulk, куда помещаются картины.
    //    Для bulk задается цена и схема распределения доходов,
    //    которые будут распространяться на все картины в bulk.
    // 2. Offer создается для всего bulk, где будут

    // содержит связку token-а картины с bulk
    // mapping(uint256 => Bulk) public bulks;
    
    // содержит связку token с bid
    // mapping(uint256 => Bid) public bids;

    // содержит связку token с offer
    // mapping(uint256 => Offer) public offers;

    // содержит связку адреса с его балансом
    mapping(address => uint256) public pendingWithdrawals;

    // функции покупателя
    /// @dev Функция, выставляющая bid для выбранного токена
    /// @param _tokenId Токен, который хотят приобрести
    function setBid(uint256 _tokenId) public payable {
        // 1. нам не важно, доступен ли токен для продажи,
        // поэтому принимать bid мы можем всегда.
        // 2. токен не должен принадлежать тому, кто выставляет bid
        require(tokenToOwner[_tokenId] != msg.sender);
        require(msg.sender != address(0));
        require(msg.value > 0);

        Bid storage bid = bids[_tokenId];

        // выставленный bid однозначно должен быть больше предыдущего, как минимум на 5%
        require(msg.value >= bid.value + (bid.value * 5 / 100));

        // предыдущему бидеру нужно вернуть его сумму
        if (bid.value > 0) {
            pendingWithdrawals[bid.bidder] += bid.value;
        }

        // сохраняем текущий bid для выбранного токена
        bids[_tokenId] = Bid(_tokenId, true, msg.sender, msg.value);
    }

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


    // общие функции для продавца и покупателя

    // 1. вывод средств на свой кошелек
    /********* ПО ИДЕЕ ТОЛЬКО ПОСЛЕ АПРУВА ВСЕХ УЧАСТНИКОВ СТОИТ ДЕЛАТЬ ApplySchema распрделения прибыли по картинам **********/
    // ОТНОСИТСЯ К ОФФЕР или к АУКЦИОНУ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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


}
