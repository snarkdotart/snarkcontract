pragma solidity ^0.4.19;


import "./SnarkBase.sol";


contract SnarkMarket is SnarkBase {
    event CanvasBoughtEvent(uint256 _tokenId, uint256 price, address seller, address buyer);

    struct Offer {
        // Id полотна
        uint canvasId;
        // номер экземпляра полотна
        uint canvasIndex;
        // предлагаемая цена в ether
        uint price;
        // адрес продавца
        address seller;
        // адрес коллекционера, кому явно выставляется предложение
        address offerTo;
    }

    struct Bid {
        // id полотна
        uint canvasId;
        // активен ли текущий бид
        bool isActive;
        // адрес, выставившего bid
        address bidder;
        // предложенная цена за полотно
        uint value;
    }

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
    function buyCanvas(uint256 _tokenId) public payable {
        // токен не может быть нулевым
        require(_tokenId != 0);
        Offer storage offer = offers[_tokenId];
        DigitalCanvas storage canvas = digitalCanvases[_tokenId];
        // совершить покупку можно лишь только того полотна, которое выставлено на продажу
        require(canvas.isForSale);
        // переданное количество денег не должно быть меньше установленной цены
        require(msg.value >= offer.price);
        // покупатель должен быть либо не установлен заранее, либо установлен на того, 
        // кто сейчас пытается купить это полотно
        require(offer.offerTo == address(0) || offer.offerTo == msg.sender);
        // нельзя продать самому себе
        require(tokenToOwner[_tokenId] != msg.sender);
        // устанавливаем владельцем текущего пользователя
        tokenToOwner[_tokenId] = msg.sender;
        // производим передачу токена (смотри SnarkOwnership)
        _transfer(offer.seller, msg.sender, _tokenId);
        // теперь необходимо выявить доход, и если он был, то произвести
        // распределение дохода, согласно долей участников. Расчет в weis
        if (canvas.lastPrice < msg.value && (msg.value - canvas.lastPrice) >= 100) {
            // вычисляем доход, полученный при продаже
            uint profit = msg.value - canvas.lastPrice;
            // тут будем хранить остаток, после выплаты всем участникам
            uint residue = profit;
            // получаем список участников прибыли
            Participant[] storage participants = canvasIdToParticipants[_tokenId];
            // и по очереди выплачиваем
            for (uint8 i = 0; i < participants.length; i++) {
                uint payout = profit * participants[i].persentageAmount / 100;
                pendingWithdrawals[participants[i].participant] += payout;
                residue -= payout;
            }
            // все что осталось после выплат всем участникам - отдаем продавцу
            pendingWithdrawals[offer.seller] += residue;
        } else {
            // если не с кем делиться, то весь доход себе
            pendingWithdrawals[offer.seller] += msg.value;
        }
        // записываем по какой цене полотно было куплено
        canvas.lastPrice = msg.value;
        // снимаем с продажи
        canvas.isForSale = false;
        // геренируем событие покупки токена
        CanvasBoughtEvent(_tokenId, msg.value, offer.seller, msg.sender);

        Bid storage bid = bids[_tokenId];
        // если покупатель выставлял bid, то необходимо его ему вернуть
        if (bid.bidder == msg.sender) {
            pendingWithdrawals[msg.sender] += bid.value;
            // и бид для токена заполняем пустышкой
            bids[_tokenId] = Bid(_tokenId, false, address(0), 0);
        }
    }

    // функции продавца

    // 1. сделать offer для своего полотна
    // 2. принять bid

    // общие функции для продавца и покупателя

    // 1. вывод средств на свой кошелек

}
