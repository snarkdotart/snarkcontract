pragma solidity ^0.4.21;


import "./SnarkBase.sol";


contract SnarkMarket is SnarkBase {
    event digitalWorkBoughtEvent(uint256 _tokenId, uint256 price, address seller, address buyer);

    struct Bulk {
        string bulkName; // имя кучи
    }

    struct Offer {
        // Id полотна
        uint digitalWorkId;
        // номер экземпляра полотна
        // uint digitalWorkIndex;
        // предлагаемая цена в ether
        uint price;
        // адрес продавца
        address seller;
        // адрес коллекционера, кому явно выставляется предложение
        address offerTo;
    }

    struct Bid {
        // id полотна
        uint digitalWorkId;
        // активен ли текущий бид
        bool isActive;
        // адрес, выставившего bid
        address bidder;
        // предложенная цена за полотно
        uint value;
    }

    // 1. Создается bulk, куда помещаются картины.
    //    Для bulk задается цена и схема распределения доходов,
    //    которые будут распространяться на все картины в bulk.
    // 2. Offer создается для всего bulk, где будут

    // содержит связку token-а картины с bulk
    // mapping(uint256 => Bulk) public bulks;
    



    // содержит связку token с bid
    mapping(uint256 => Bid) public bids;

    // содержит связку token с offer
    mapping(uint256 => Offer) public offers;

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

    // функции продавца
    // 1. сделать offer для своего полотна
    // 2. принять bid
    function setOffer(uint256 _tokenId, uint256 _price, address _offerTo) public {
        require(_tokenId != 0);
        DigitalWork storage digitalWork = digitalWorks[_tokenId];
        require(digitalWork.isReadyForSale); // только, если все участники апрувнули свои доли
        require(msg.sender == ownerOf(_tokenId)); // выставить на продажу может только владелец
        offers[_tokenId] = Offer(_tokenId, _price, msg.sender, _offerTo);
    }

    // общие функции для продавца и покупателя

    // 1. вывод средств на свой кошелек

}
