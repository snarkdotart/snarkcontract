pragma solidity ^0.4.24;

import "./SnarkRenting.sol";


contract SnarkTrade is SnarkRenting {

    // модификатор, фильтрующий по принадлежности токенов одному владельцу
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isSenderOwner = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isSenderOwner = (isSenderOwner && (msg.sender == tokenToOwnerMap[_tokenIds[i]]));
        }
        require(isSenderOwner);
        _;
    }

    /// @dev Передача токена новому владельцу, если предыдущий владелец утвердил нового владельца
    /// @param _tokenId Токен, который будет передан новому владельцу
    function takeOwnership(uint256 _tokenId) public {
        require(tokenToApprovalsMap[_tokenId] == msg.sender);
        address owner = tokenToOwnerMap[_tokenId];
        _transfer(owner, msg.sender, _tokenId);
    }

    /// @dev Возвращает общее количество цифровых работ в системе
    function getAmountOfTokens() public view returns(uint256) {
        return digitalWorks.length;
    }

    /// @dev Возвращает список токенов по адресу
    /// @param _owner Адрес, для которого хотим получить список токенов
    function getOwnerTokenList(address _owner) public view returns (uint256[]) {
        return ownerToTokensMap[_owner];
    }

    /// @dev Функция принятия бида и продажи предложившему. снять все оферы и биды.
    function acceptBid(uint256 _bidId) public onlyOwnerOf(_tokenId) {
        // получаем id цифровой работы, которую владелец согласен продать по цене бида
        uint256 _tokenId = bids[_bidId].digitalWorkId;
        // запоминаем от кого и куда должна уйти цифровая работа
        address _from = msg.sender;
        address _to = bidToOwnerMap[_bidId];
        // сохраняем сумму
        uint256 _price = bids[_bidId].price;
        // устанавливаем владельцем текущего пользователя
        tokenToOwnerMap[_tokenId] = _to;
        // т.к. деньги уже были перечислены за бид, то просто передаем токен новому владельцу
        _transfer(_from, _to, _tokenId);
        // был ли оффер?
        bool doesItHasOffer = (tokenToSaleTypeMap[_tokenId] == SaleType.Offer);
        // распределяем прибыль
        _incomeDistribution(_price, _tokenId, _from);
        // удаляем бид
        _deleteBid(_bidId);
        // если есть оффер, то его также надо удалить
        if (doesItHasOffer) {
            uint256 offerId = tokenToOfferMap[_tokenId];
            // удаляем только, если у него не осталось картин для продажи
            if (getDigitalWorksOffersList(offerId).length == 0)
                deleteOffer(offerId);
        }
    }

    // функция продажи картины. снять все оферы и биды для картины.
    /// @dev Фукнция совершения покупки полотна
    /// @param _tokenId Токен, который покупают
    function buyToken(address _from, address _to, uint256 _tokenId) internal {
        require(tokenToSaleTypeMap[_tokenId] == SaleType.Offer || 
            tokenToSaleTypeMap[_tokenId] == SaleType.Auction);
        bool isTypeOffer = (tokenToSaleTypeMap[_tokenId] == SaleType.Offer);
        uint256 _price;
        if (isTypeOffer) {
            uint256 offerId = tokenToOfferMap[_tokenId];
            require(_from == offerToOwnerMap[offerId]);
            _price = offers[offerId].price;
            require(offers[offerId].offerTo == address(0) || offers[offerId].offerTo == _to);
        } else {
            uint256 auctionId = tokenToAuctionMap[_tokenId];
            require(_from == auctionToOwnerMap[auctionId]);
            _price = auctions[auctionId].workingPrice;
        }
        require(msg.value >= _price); 
        require(_from != _to);
        // устанавливаем владельцем текущего пользователя
        tokenToOwnerMap[_tokenId] = _to;
        // производим передачу токена
        _transfer(_from, _to, _tokenId); 
        // распределяем прибыль
        _incomeDistribution(msg.value, _tokenId, _from);
        // удаляем бид, если есть
        if (tokenToIsExistBidMap[_tokenId]) {
            uint256 bidId = tokenToBidMap[_tokenId];
            uint256 bidValue = bids[bidId].price;
            address bidder = bidToOwnerMap[bidId];
            _deleteBid(bidId);
            bidder.transfer(bidValue);
        }

        if (isTypeOffer) {
            offers[offerId].countOfDigitalWorks--;
            if (offers[offerId].countOfDigitalWorks == 0)
                deleteOffer(offerId);
        } else {
            auctions[auctionId].countOfDigitalWorks--;
            if (auctions[auctionId].countOfDigitalWorks == 0)
                _deleteAuction(auctionId);
        }
    }

    // function buyToken(uint256 _tokenId) public payable {
    //     require(tokenToSaleTypeMap[_tokenId] == SaleType.Offer || 
    //         tokenToSaleTypeMap[_tokenId] == SaleType.Auction);
    //     bool isTypeOffer = (tokenToSaleTypeMap[_tokenId] == SaleType.Offer);
    //     address _from;
    //     address _to;
    //     uint256 _price;
    //     if (isTypeOffer) {
    //         uint256 offerId = tokenToOfferMap[_tokenId];
    //         _from = offerToOwnerMap[offerId];
    //         _to = msg.sender;
    //         _price = offers[offerId].price;
    //         require(offers[offerId].offerTo == address(0) || offers[offerId].offerTo == _to);
    //     } else {
    //         uint256 auctionId = tokenToAuctionMap[_tokenId];
    //         _from = auctionToOwnerMap[auctionId];
    //         _to = msg.sender;
    //         _price = auctions[auctionId].workingPrice;
    //     }
    //     require(msg.value >= _price); 
    //     require(_from != _to);
    //     // устанавливаем владельцем текущего пользователя
    //     tokenToOwnerMap[_tokenId] = _to;
    //     // производим передачу токена (смотри SnarkOwnership)
    //     _transfer(_from, _to, _tokenId); 
    //     // распределяем прибыль
    //     _incomeDistribution(msg.value, _tokenId, _from);
    //     // удаляем бид, если есть
    //     if (tokenToIsExistBidMap[_tokenId]) {
    //         uint256 bidId = tokenToBidMap[_tokenId];
    //         uint256 bidValue = bids[bidId].price;
    //         address bidder = bidToOwnerMap[bidId];
    //         _deleteBid(bidId);
    //         bidder.transfer(bidValue);
    //     }

    //     if (isTypeOffer) {
    //         offers[offerId].countOfDigitalWorks--;
    //         if (offers[offerId].countOfDigitalWorks == 0)
    //             deleteOffer(offerId);
    //     } else {
    //         auctions[auctionId].countOfDigitalWorks--;
    //         if (auctions[auctionId].countOfDigitalWorks == 0)
    //             _deleteAuction(auctionId);
    //     }
    // }

}
