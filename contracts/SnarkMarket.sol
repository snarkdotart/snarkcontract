pragma solidity ^0.4.19;


import "./SnarkBase.sol";


contract SnarkMarket {

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
        uint canvasIndex;
        // адрес, выставившего bid
        address bidder;
        // предложенная цена за полотно
        uint prise;
    }

}
