pragma solidity ^0.4.19;


import "./SnarkBase.sol";


contract SnarkMarket is SnarkBase {

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
        // номер экземпляра
        // uint canvasIndex;
        // адрес, выставившего bid
        address bidder;
        // предложенная цена за полотно
        uint value;
    }

    // содержит связку token с bid
    mapping(uint256 => Bid) public bids;
    // содержит связку token с offer
    mapping(uint256 => Offer) public ffers;
    // содержит связку адреса с его балансом
    mapping(address => uint256) public pendingWithdrawals;

    // функции покупателя

    /// @dev Функция, выставляющая bid для выбранного токена
    /// @param _tokenId Токен, который хотят приобрести
    function setBid(uint256 _tokenId) payable {
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
        bids[_tokenId] = Bid(_tokenId, msg.sender, msg.value);
    }

    /// @dev Функция позволяет тказаться от bid и вернуть деньги себе на кошелек
    /// @param _tokenId Токен, от которого хотят отказаться
    function withdrawBid(uint256 _tokenId) {
    }

    /// @dev Фукнция совершения покупки полотна
    /// @param _tokenId Токен, который покупают
    function buyCanvas(uint256 _tokenId) payable {
    }

    // функции продавца

    // 1. сделать offer для своего полотна
    // 2. принять bid

    // общие функции для продавца и покупателя

    // 1. вывод средств на свой кошелек

}
