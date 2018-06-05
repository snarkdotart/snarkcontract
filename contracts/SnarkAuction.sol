pragma solidity ^0.4.24;

import "./SnarkOfferBid.sol";


contract SnarkAuction is SnarkOfferBid {

    // событие, оповещающее, что участник прибыли не согласен с условиями
    event DeclineApproveAuctionEvent(uint256 _auctionId, address indexed _offerOwner, address indexed _participant);
    // событие, оповещающее, что был создан новый аукцион
    event AuctionCreatedEvent(uint256 _auctionId);
    // оповещает участника о необходимости подтвердить согласие на его долю в продаже картины
    event NeedApproveAuctionEvent(uint256 _auctionId, address indexed _participant, uint8 _percentAmount);
    // события, оповещающие, что закончился аукцион (продались все картины)
    event AuctonEnded(uint256 _auctionId);
    // событие, оповещающее, что произошла переоценка аукциона
    event AuctionPriceChanged(uint256 _auctionId, uint256 newPrice);
    // событие, оповещающее, что аукцион был завершен
    event AuctionFinishedEvent(uint256 _auctionId);

    struct Auction {
        // начальная цена в wei
        uint256 startingPrice;
        // конечная цена в wei
        uint256 endingPrice;
        // будет содержать "суточную" текущую цену - надо ли, не проще ли вычислять на лету?
        uint256 workingPrice;
        // дата и время начала аукциона
        uint64 startingDate;
        // продолжительность аукциона в сутках
        uint16 duration;
        // список картин, участвующих в аукционе
        address[] participants;
        // содержит связь участника с размером его доли
        mapping(address => uint8) participantToPercentageAmountMap;
        // содержит связь участника с его подтверждением
        mapping(address => bool) participantToApproveMap;
        // количество работ в данном предложении. Уменьшаем при продаже картины
        uint256 countOfDigitalWorks;
        // статус предложения (используем все 4 состояния)
        SaleStatus saleStatus;
    }

    // список всех аукционов
    Auction[] internal auctions;

    // содержит связь цифровой работы с аукционом, в котором она участвует
    mapping(uint256 => uint256) internal tokenToAuctionMap;
    // содержит связь аукциона с его владельцем
    mapping(uint256 => address) internal auctionToOwnerMap;
    // содержит счетчик аукционов, принадлежащих одному владельцу
    mapping(address => uint256) internal ownerToCountAuctionsMap;

    /// @dev Модификатор, пропускающий только владельца аукциона
    /// @param _auctionId Auction Id
    modifier onlyAuctionOwner(uint256 _auctionId) {
        require(msg.sender == auctionToOwnerMap[_auctionId]);
        _;
    }

    /// @dev Модификатор, проверяющий переданный id аукциона на попадание в интервал
    /// @param _auctionId Auction Id
    modifier correctAuctionId(uint256 _auctionId) {
        require(auctions.length > 0);
        require(_auctionId < auctions.length);
        _;        
    }

    /// @dev Модификатор, пропускающий только участников дохода для этого аукциона
    /// @param _auctionId Auction Id
    modifier onlyAuctionParticipator(uint256 _auctionId) {
        bool isItParticipant = false;
        address[] storage p = auctions[_auctionId].participants;
        for (uint8 i = 0; i < p.length; i++) {
            if (msg.sender == p[i]) isItParticipant = true;
        }
        require(isItParticipant);
        _;        
    }

    /// @dev Дергаем функцию из-вне, для того, чтобы: 
    /// СКОРЕЕ ВСЕГО ЭТУ ФУНКЦИЮ НАДО ДЕЛАТЬ НА BACKEND-е, т.к. будет дешевле
    /// либо запустить, либо остановить аукционы, либо цену снизить
    function processingOfAuctions() external {
        uint256 currentTimestamp = block.timestamp;
        uint256 endDay = 0;
        for (uint256 i = 0; i < auctions.length; i++) {
            if (auctions[i].saleStatus == SaleStatus.NotActive) {
                // вычисляем конечную дату, когда должен аукцион закончится
                // начальная дата в timestamp + (продолжительность в сутках + 1 
                // т.к. надо будет выждать) * 86400 (timestamp одних суток)
                endDay = auctions[i].startingDate + (auctions[i].duration + 1) * 86400;
                // запускаем те, которым уже пора
                if (auctions[i].startingDate <= currentTimestamp &&
                    currentTimestamp < endDay) {
                    auctions[i].saleStatus == SaleStatus.Active;
                }
            } else if (auctions[i].saleStatus == SaleStatus.Active) {
                // останавливаем те, которым уже пора
                if (currentTimestamp >= endDay) {
                    auctions[i].saleStatus == SaleStatus.Finished;
                    // и тут надо бы распустить удалить аукцион и "освободить" оставшиеся картины
                    _deleteAuction(i);
                } else {
                    // если мы тут, то аукцион еще работает и опускаем цену, если надо
                    // шаг = (начальная цена, большая  - конечная цена, меньшая) / продолжительность
                    uint256 step = (auctions[i].startingPrice - auctions[i].endingPrice) / auctions[i].duration;
                    // вычисляем сколько длится аукцион, в сутках
                    uint8 auctionLasts = uint8((block.timestamp - auctions[i].startingDate) / 86400);
                    // вычисляем, какая на данный момент должна быть цена
                    uint256 newPrice = uint256(auctions[i].startingPrice - step * auctionLasts);
                    if (auctions[i].workingPrice > newPrice) {
                        auctions[i].workingPrice = newPrice;
                        emit AuctionPriceChanged(i, newPrice);
                    }
                }
            }
        }
    }

    /// @dev Функция создания аукциона для картин ПЕРВИЧНОЙ продажи. Вызывает событие апрува для участников
    /// @param _tokenIds Список id-шников цифровых работ, которые будут включены в это предложение
    /// @param _startingPrice Стартовая цена картин
    /// @param _endingPrice Конечная цена картин
    /// @param _startingDate Дата начала аукциона (timestamp)
    /// @param _duration Продолжительность аукциона (в сутках)
    /// @param _participants Список участников прибыли
    /// @param _percentAmounts Список процентных долей участников
    function createAuction(
        uint256[] _tokenIds,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint64 _startingDate,
        uint16 _duration,
        address[] _participants,
        uint8[] _percentAmounts
    ) 
        public
        onlyOwnerOfMany(_tokenIds)
        onlyNoneStatus(_tokenIds)
        onlyFirstSale(_tokenIds)
    {
        uint256 auctionId = auctions.push(Auction({
            startingPrice: _startingPrice,
            endingPrice: _endingPrice,
            workingPrice: _startingPrice,
            startingDate: _startingDate,
            duration: _duration,
            participants: new address[](0),
            countOfDigitalWorks: _tokenIds.length,
            saleStatus: SaleStatus.Preparing
        })) - 1;
        // применяем схему распределения пока для самого аукциона (не для цифровых работ)
        _applyNewSchemaOfProfitDivisionForAuction(auctionId, _participants, _percentAmounts);
        // для всех цифровых работ выполняем следующее:
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            // в самой работе помечаем, что она участвует в аукционе
            tokenToSaleTypeMap[_tokenIds[i]] = SaleType.Auction;
            // помечаем к какому аукциону она принадлежит
            tokenToAuctionMap[_tokenIds[i]] = auctionId;
        }
        // записываем владельца данного аукциона
        auctionToOwnerMap[auctionId] = msg.sender;
        // увеличиваем количество аукционов, принадлежащих овнеру
        ownerToCountAuctionsMap[msg.sender]++;

        for (i = 0; i < _participants.length; i++) {
            // адресно оповещаем каждого из участиков
            emit NeedApproveAuctionEvent(auctionId, _participants[i], _percentAmounts[i]);
        }
    }

    /// @dev Функция создания аукциона для картин ВТОРИЧНОЙ продажи.
    /// @param _tokenIds Список id-шников цифровых работ, которые будут включены в это предложение
    /// @param _startingPrice Стартовая цена картин
    /// @param _endingPrice Конечная цена картин
    /// @param _startingDate Дата начала аукциона (timestamp)
    /// @param _duration Продолжительность аукциона (в сутках)
    function createAuction(
        uint256[] _tokenIds,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint64 _startingDate,
        uint16 _duration
    ) 
        public
        onlyOwnerOfMany(_tokenIds)
        onlyNoneStatus(_tokenIds)
        onlySecondSale(_tokenIds)
    {
        uint256 auctionId = auctions.push(Auction({
            startingPrice: _startingPrice,
            endingPrice: _endingPrice,
            workingPrice: _startingPrice,
            startingDate: _startingDate,
            duration: _duration,
            participants: new address[](0),
            countOfDigitalWorks: _tokenIds.length,
            saleStatus: SaleStatus.NotActive
        })) - 1;
        // для всех цифровых работ выполняем следующее:
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            // в самой работе помечаем, что она участвует в аукционе
            tokenToSaleTypeMap[_tokenIds[i]] = SaleType.Auction;
            // помечаем к какому аукциону она принадлежит
            tokenToAuctionMap[_tokenIds[i]] = auctionId;
        }
        // записываем владельца данного аукциона
        auctionToOwnerMap[auctionId] = msg.sender;
        // увеличиваем количество аукционов, принадлежащих овнеру
        ownerToCountAuctionsMap[msg.sender]++;
        // сообщаем, что был создан аукцион
        emit AuctionCreatedEvent(auctionId);
    }

    /// @dev Функция модификации участников и их долей для аукциона, в случае отклонения одним из участников
    /// @param _auctionId Id-шник аукциона
    /// @param _participants Массив адресов участников прибыли
    /// @param _percentAmounts Массив долей участников прибыли
    function setNewSchemaOfProfitDivisionForAuction(
        uint256 _auctionId,
        address[] _participants,
        uint8[] _percentAmounts
    )
        public
        onlyAuctionOwner(_auctionId)
    {
        // длины массивов должны совпадать
        require(_participants.length == _percentAmounts.length);
        // применяем новую схему
        _applyNewSchemaOfProfitDivisionForAuction(_auctionId, _participants, _percentAmounts);
        // т.к. изменения доли для одного затрагивает всех, то заново всех надо оповещать
        for (uint256 i = 0; i < _participants.length; i++) {
            // оповещаем адресно
            emit NeedApproveAuctionEvent(_auctionId, _participants[i], _percentAmounts[i]);
        }
    }

    /// @dev Участник прибыли подтверждает свое согласие на выставленные условия
    /// @param _auctionId id-шник аукциона
    function approveAuction(uint256 _auctionId) public onlyAuctionParticipator(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        // отмечаем текущего участники, как согласного с условиями
        auction.participantToApproveMap[msg.sender] = true;
        // проверяем все ли участники согласились или нет
        bool isAllApproved = true;
        uint8[] memory parts = new uint8[](auction.participants.length);
        for (uint8 i = 0; i < auction.participants.length; i++) {
            isAllApproved = isAllApproved && auction.participantToApproveMap[auction.participants[i]];
            parts[i] = auction.participantToPercentageAmountMap[auction.participants[i]];
        }
        // если все согласны, то копируем условия в сами картины, дабы каждая картина имела возможность,
        // в последствие, знать условия распределения прибыли
        if (isAllApproved) {
            uint256[] memory tokens = getDigitalWorksAuctionsList(_auctionId);
            for (i = 0; i < tokens.length; i++) {
                _applySchemaOfProfitDivision(tokens[i], auction.participants, parts);
            }
        }
        // и только теперь помечаем, что аукцион может выставляться на продажу
        if (isAllApproved) auction.saleStatus = SaleStatus.NotActive;
        // сообщаем, что был создан аукцион
        emit AuctionCreatedEvent(_auctionId);
    }

    /// @dev Отказ участника прибыли с предложенными условиями
    /// @param _auctionId Id-шник offer-а
    function declineAuctionApprove(uint256 _auctionId) public view onlyAuctionParticipator(_auctionId) {
        // уведомляем создателя аукциона, что народ не хочет на такие условия подписываться
        emit DeclineApproveAuctionEvent(_auctionId, auctionToOwnerMap[_auctionId], msg.sender);
    }

    /// @dev Функция получения всех картин, принадлежащих аукциону
    /// @param _auctionId Id-шник аукциона
    function getDigitalWorksAuctionsList(uint256 _auctionId) 
        public 
        view 
        correctAuctionId(_auctionId) 
        returns (uint256[]) 
    {
        // выделяем массив размерности, заданной в аукционе
        uint256[] memory auctionDigitalWorksList = new uint256[](auctions[_auctionId].countOfDigitalWorks);
        uint256 index = 0;
        for (uint256 i = 0; i < digitalWorks.length; i++) {
            // если текущая работа принадлежит уже какому-то аукциону и этот аукцион тот, 
            // что нас инетересует, то добавляем его индекс в возвращаемую таблицу
            if (tokenToAuctionMap[i] == _auctionId &&
                tokenToSaleTypeMap[i] == SaleType.Auction) {
                auctionDigitalWorksList[index++] = i;
            }
        }
        return auctionDigitalWorksList;
    }

    /// @dev Применяем схему к аукциону
    /// @param _auctionId Id-шник аукциона
    /// @param _participants Массив адресов участников прибыли
    /// @param _percentAmounts Массив долей участников прибыли
    function _applyNewSchemaOfProfitDivisionForAuction(
        uint256 _auctionId,
        address[] _participants,
        uint8[] _percentAmounts
    ) 
        private
    {
        // удаляем все, ибо могли исключить кого-то из участников и добавить новых
        Auction storage auction = auctions[_auctionId];
        for (uint8 i = 0; i < auction.participants.length; i++) {
            // удаляем процентные доли
            delete auction.participantToPercentageAmountMap[auction.participants[i]];
            // удаляем "согласия", ибо уже изменились значения для всех
            delete auction.participantToApproveMap[auction.participants[i]];
        }
        auction.participants.length = 0;
        // применяем новую схему
        bool isSnarkDelivered = false;
        // заполняем список участников прибыли
        for (i = 0; i < _participants.length; i++) {
            // сначала сохраняем адрес участника
            auction.participants.push(_participants[i]);
            // а затем его долю
            auction.participantToPercentageAmountMap[_participants[i]] = _percentAmounts[i];
            // на тот случай, если с клиента уже будет приходить информация о доле Snark
            if (_participants[i] == owner) isSnarkDelivered = true;
        }
        // ну и не забываем про себя любимых, т.е. Snark, если он чуть выше не был передан и обработан
        if (isSnarkDelivered == false) {
            // записываем адрес Snark
            auction.participants.push(owner); 
            // записываем долю Snark
            auction.participantToPercentageAmountMap[owner] = snarkPercentageAmount;
        }
        // и сразу апруваем Snark
        auction.participantToApproveMap[owner] = true;
    }

    /// @dev Удаляет аукцион
    /// @param _auctionId Id-шник аукциона
    function _deleteAuction(uint256 _auctionId) private {
        uint256[] memory tokens = getDigitalWorksAuctionsList(_auctionId);
        for (uint256 i = 0; i < tokens.length; i++) {
            // освобождаем все картины
            if (tokenToSaleTypeMap[tokens[i]] == SaleType.Auction)
                tokenToSaleTypeMap[tokens[i]] = SaleType.None;
            delete tokenToAuctionMap[tokens[i]];
        }
        address owner = auctionToOwnerMap[_auctionId];
        // удаляем связь аукциона с владельцем
        delete auctionToOwnerMap[_auctionId];
        // уменьшаем счетчик аукционов у владельца
        ownerToCountAuctionsMap[owner]--;
        // помечаем аукцион, как завершившийся
        auctions[_auctionId].saleStatus = SaleStatus.Finished;
        // генерим событие о том, что удален аукцион
        emit AuctionFinishedEvent(_auctionId);
    }

    /// @dev Lock Token
    /// @param _offerId Offer Id
    /// @param _tokenId Token Id
    function _lockAuctionsToken(uint256 _auctionId, uint256 _tokenId) private {
        address realOwner = auctionToOwnerMap[_auctionId];
        tokenToOwnerMap[_tokenId] = owner;
        for (uint8 i = 0; i < ownerToTokensMap[realOwner].length; i++) {
            if (ownerToTokensMap[realOwner][i] == _tokenId) {
                ownerToTokensMap[realOwner][i] = 
                    ownerToTokensMap[realOwner][ownerToTokensMap[realOwner].length - 1];
                ownerToTokensMap[realOwner].length--;    
                break;
            }
        }
        ownerToTokensMap[owner].push(_tokenId);        
    }

    /// @dev Unlock Token
    /// @param _offerId Offer Id
    /// @param _tokenId Token Id
    function _unlockAuctionsToken(uint256 _auctionId, uint256 _tokenId) private {
        address realOwner = auctionToOwnerMap[_auctionId];
        tokenToOwnerMap[_tokenId] = realOwner;
        for (uint256 i = 0; i < ownerToTokensMap[owner].length; i++) {
            if (ownerToTokensMap[owner][i] == _tokenId) {
                ownerToTokensMap[owner][i] = 
                    ownerToTokensMap[owner][ownerToTokensMap[owner].length - 1];
                ownerToTokensMap[owner].length--;    
                break;
            }
        }
        ownerToTokensMap[realOwner].push(_tokenId);        
    }
}


