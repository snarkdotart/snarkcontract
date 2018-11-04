pragma solidity ^0.4.24;

import "../SnarkStorage.sol";
import "../openzeppelin/SafeMath.sol";


library SnarkOfferBidLib {
    using SafeMath for uint256;

    /*** SET ***/
    function setPriceForOffer(address _storageAddress, uint256 _offerId, uint256 _price) public {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("priceForOfferId", _offerId)), _price);
    }

    function setTokenIdForOffer(address _storageAddress, uint256 _offerId, uint256 _tokenId) public {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("tokenIdForOfferId", _offerId)), _tokenId);
    }

    function setOfferIdForTokenId(address _storageAddress, uint256 _tokenId, uint256 _offerId) public {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("offerIdIdForTokenId", _tokenId)), _offerId);
    }

    function setSaleStatusForOffer(address _storageAddress, uint256 _offerId, uint256 _saleStatus) public {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToOffer", _offerId)), _saleStatus);
    }

    function setOwnerForOffer(address _storageAddress, uint256 _offerId, address _offerOwner) public {
        SnarkStorage(_storageAddress).setAddress(keccak256(abi.encodePacked("ownerToOffer", _offerId)), _offerOwner);
    }

    function setOwnerOfBid(address _storageAddress, uint256 _bidId, address _bidOwner) public {
        SnarkStorage(_storageAddress).setAddress(keccak256(abi.encodePacked("ownerToBid", _bidId)), _bidOwner);
    }

    function setTokenToBid(address _storageAddress, uint256 _bidId, uint256 _tokenId) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("tokenIdToBidId", _bidId)), _tokenId);
    }

    function setPriceToBid(address _storageAddress, uint256 _bidId, uint256 _price) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidPrice", _bidId)), _price);
    }

    function setSaleStatusForBid(address _storageAddress, uint256 _bidId, uint256 _saleStatus) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidSaleStatus", _bidId)), _saleStatus);
    }

    /*** DELETE ***/
    function cancelOffer(address _storageAddress, uint256 _offerId) public {

        uint256 tokenId = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenIdForOfferId", _offerId)));

        SnarkStorage(_storageAddress).deleteUint(
            keccak256(abi.encodePacked("offerIdIdForTokenId", tokenId)));

        address offerOwner = SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("ownerToOffer", _offerId)));

        uint256 amountOfOwnerOffers = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", offerOwner)));

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", offerOwner)),
            amountOfOwnerOffers.sub(1));

        for (uint256 i = 0; i < amountOfOwnerOffers; i++) {
            uint256 currentOfferId = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("ownerOffersList", offerOwner, i)));
            if (currentOfferId == _offerId) {
                if (i < amountOfOwnerOffers.sub(1)) {
                    uint256 lastOfferId = SnarkStorage(_storageAddress).uintStorage(
                        keccak256(abi.encodePacked("ownerOffersList", offerOwner, amountOfOwnerOffers.sub(1))));
                    SnarkStorage(_storageAddress).setUint(
                        keccak256(abi.encodePacked("ownerOffersList", offerOwner, i)), lastOfferId);
                }
                SnarkStorage(_storageAddress).deleteUint(
                    keccak256(abi.encodePacked("ownerOffersList", offerOwner, amountOfOwnerOffers.sub(1))));
                break;
            }
        }

        // change status saleType = 'None' for token id:
        // 0 - None, 1 - Offer, 2 - Loan
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleTypeToToken", tokenId)), 0);
        // change status saleStatus = Finished:
        // 0 - Preparing, 1 - NotActive, 2 - Active, 3 - Finished
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToOffer", _offerId)), 3);

        // delete offer with a previous status from list and reduce their count
        // add to list with a new status
    }

    // FIXME: НЕЛЬЗЯ УДАЛЯТЬ БИД В РЕАЛЕ. НАДО ТОЛЬКО ИЗМЕНИТЬ ЕГО СТАТУС
    // ТАКЖЕ НАДО ВЕСТИ СПИСОК БИДОВ ПО СТАТУСАМ ПО ПОЛЬЗОВАТЕЛЯМ
    function deleteBid(address _storageAddress, uint256 _bidId) public {
        // getting an tokenId
        uint256 tokenId = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenIdToBidId", _bidId)));
        // it's not neccesary to delete tokenIdToBidId
        // SnarkStorage(_storageAddress).deleteUint(
        //     keccak256(abi.encodePacked("tokenIdToBidId", _bidId)));

        // delete bid from the token's list
        uint256 numberOfTokenBids = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", tokenId)));
        for (uint256 i = 0; i < numberOfTokenBids; i++) {
            uint256 currentBidId = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("tokenBidsList", tokenId, i)));
            if (currentBidId == _bidId) {
                if (i < numberOfTokenBids.sub(1)) {
                    // get the bidId from the last element of array
                    uint256 lastBidId = SnarkStorage(_storageAddress).uintStorage(
                        keccak256(abi.encodePacked("tokenBidsList", tokenId, numberOfTokenBids.sub(1))));
                    // save it to the current position
                    SnarkStorage(_storageAddress).setUint(
                        keccak256(abi.encodePacked("tokenBidsList", tokenId, i)), lastBidId);
                }
                // delete the last bidId in array
                SnarkStorage(_storageAddress).deleteUint(
                    keccak256(abi.encodePacked("tokenBidsList", tokenId, numberOfTokenBids.sub(1))));
                // reduce a number of token bids
                SnarkStorage(_storageAddress).setUint(
                    keccak256(abi.encodePacked("numberOfTokenBids", tokenId)), numberOfTokenBids.sub(1));
                // set a salae status of bid to "Finish"
                SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidSaleStatus", _bidId)), 3);
                break;
            }
        }
        // delete a price of the bid - it not neccesary to remove
        // SnarkStorage(_storageAddress).deleteUint(keccak256(abi.encodePacked("bidPrice", _bidId)));
        // we don't reduce a value of totalNumberOfBids because it will dublicate the bidId
    }

    /*** ADD ***/
    function addOffer(
        address _storageAddress, 
        address _offerOwner, 
        uint256 _tokenId, 
        uint256 _price
    ) 
        public 
        returns (uint256 offerId) 
    {
        // get an Id for this new offer
        offerId = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfOffers")).add(1);
        // save a new value of total number of offers
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfOffers"), offerId);
        // binding a price to the offer id
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("priceForOfferId", offerId)), _price);
        // bind an token id to the offer id to get the token id by means the offer id
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("tokenIdForOfferId", offerId)), _tokenId);
        // and vice versa: binding the offer id to the token id to get the offer id by means the token id
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("offerIdIdForTokenId", _tokenId)), offerId);
        // увеличиваем общее количество офферов, принадлежащих владельцу
        uint256 amountOfOwnerOffers = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)));
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)),
            amountOfOwnerOffers.add(1));
        // добавляем offer id в список offers владельцу _offerOwner
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerOffersList", _offerOwner, amountOfOwnerOffers)),
            offerId);
        // mapping owner to the offer
        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("ownerToOffer", offerId)),
            _offerOwner);
        // изменяем статус saleType = 'Offer' для token id: 
        // 0 - None, 1 - Offer, 2 - Loan
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleTypeToToken", _tokenId)), 1);
        // изменяем статус офера saleStatus = Active:
        // 0 - Preparing, 1 - NotActive, 2 - Active, 3 - Finished
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToOffer", offerId)), 2);

        // uint256 numberOfOffersBySaleStatus = SnarkStorage(_storageAddress).uintStorage(
        //     keccak256(abi.encodePacked("numberOfOffersBySaleStatus", uint256(2))));
        // uint256 newNumberOfOffersBySaleStatus = numberOfOffersBySaleStatus.add(1);
        // assert(newNumberOfOffersBySaleStatus >= numberOfOffersBySaleStatus);
        // SnarkStorage(_storageAddress).setUint(
        //     keccak256(abi.encodePacked("numberOfOffersBySaleStatus", uint256(2))), newNumberOfOffersBySaleStatus);
        // SnarkStorage(_storageAddress).setUint(
        //     keccak256(abi.encodePacked("OffersListBySaleStatus", uint256(2), numberOfOffersBySaleStatus)), offerId);
    }

    function addBid(
        address _storageAddress, 
        address _bidOwner, 
        uint256 _tokenId, 
        uint256 _price
    ) 
        public 
        returns (uint256 bidId) 
    {
        bidId = increaseTotalNumberOfBids(_storageAddress);
        setMaxBidPriceForToken(_storageAddress, _tokenId, _price);
        setMaxBidIdForToken(_storageAddress, _tokenId, bidId);
        setOwnerOfBid(_storageAddress, bidId, _bidOwner);
        setTokenToBid(_storageAddress, bidId, _tokenId);
        setPriceToBid(_storageAddress, bidId, _price);
        setSaleStatusForBid(_storageAddress, bidId, 2); // 2 - Active
        
        // add bid into a list of owner's active bids and increase a number of owner's active bids
        uint256 numberOfActiveBids = getNumberOfActiveBidsForOwner(_storageAddress, _bidOwner);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("activeBidsOfOwner", _bidOwner, numberOfActiveBids)), bidId);
        increaseNumberOfActiveBidsForOwner(_storageAddress, _bidOwner);


        // В списках уже будут удаляться bid-ы или только изменяться статус??? Или будут проблемы при их удалении?
        // -----------------------------------------
        // 1. токен может содержать много бидов. поэтому, чтобы получить все биды для токена нужно
        // а) bids list for token;
        // б) bid true or false for token.
        // -----------------------------------------
        // 2. у бид-овнера тоже может быть много бидов. поэтому, чтобы получить все биды для бид-овнера нужно
        // а) active bids list for bid owner;
        // б) bid true or false for owner - чтобы можно было сразу проверить принадлежность токена к owner-у. 
        // Или достаточно проверять статус Active | Finished
        // -----------------------------------------
        // increase amount of token's bids
        uint256 numberOfTokenBids = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)));
        
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)), numberOfTokenBids.add(1));
        
        // add bidId to a list of tokenId
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("tokenBidsList", _tokenId, numberOfTokenBids)), bidId);
        
        // the same but for the owner ... need to know the list of their bids
        uint256 numberBidsOfOwner = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        uint256 newNumberOfOwnerBids = numberBidsOfOwner.add(1);
        assert(newNumberOfOwnerBids >= numberBidsOfOwner);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newNumberOfOwnerBids);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, numberBidsOfOwner)), bidId);

    }

    function addBidToTokenBidsList(address _storageAddress, uint256 _tokenId, uint256 _bidId) public {
        uint256 index = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)));

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("tokenBidsList", _tokenId, index)), _bidId);

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)), index.add(1));
    }

    function increaseTotalNumberOfOffers(address _storageAddress) public returns (uint256 newAmount) {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfOffers"));
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfOffers"), newAmount);
    }

    function decreaseTotalNumberOfOffers(address _storageAddress) public returns (uint256 newAmount) {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfOffers"));
        newAmount = amount.sub(1);
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfOffers"), newAmount);
    }

    function increaseTotalNumberOfOwnerOffers(address _storageAddress, address _offerOwner) 
        public 
        returns (uint256 newAmount) 
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)));
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)), newAmount);
    }

    function decreaseTotalNumberOfOwnerOffers(address _storageAddress, address _offerOwner) 
        public
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)));
        newAmount = amount.sub(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)), newAmount);
    }

    function increaseTotalNumberOfBids(address _storageAddress) public returns (uint256 newAmount) {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids"));
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfBids"), newAmount);
    }

    function decreaseTotalNumberOfBids(address _storageAddress) public returns (uint256 newAmount) {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids"));
        newAmount = amount.sub(1);
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfBids"), newAmount);
    }

    function increaseNumberOfTokenBids(address _storageAddress, uint256 _tokenId) 
        public 
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)));
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)), newAmount);
    }

    function decreaseNumberOfTokenBids(address _storageAddress, uint256 _tokenId) 
        public
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)));
        newAmount = amount.sub(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)), newAmount);
    }

    function increaseNumberOfOwnerBids(address _storageAddress, address _bidOwner) 
        public 
        returns (uint256 newAmount) 
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newAmount);
    }

    function decreaseNumberOfOwnerBids(address _storageAddress, address _bidOwner)
        public
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        newAmount = amount.sub(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newAmount);
    }

    function addOfferToOwnerOffersList(address _storageAddress, address _offerOwner, uint256 _offerId)
        public
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)));
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerOffersList", _offerOwner, amount)), _offerId);
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)), newAmount);
    }

    function addBidToOwnerBidsList(address _storageAddress, address _bidOwner, uint256 _bidId)
        public
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newAmount);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, amount)), _bidId);
    }

    /*** GET ***/
    function getTotalNumberOfOffers(address _storageAddress) public view returns (uint256 numberOfOffers) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfOffers"));
    }

    function getOfferPrice(address _storageAddress, uint256 _offerId) public view returns (uint256 price) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("priceForOfferId", _offerId)));
    }

    function getTokenIdByOfferId(address _storageAddress, uint256 _offerId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenIdForOfferId", _offerId))
        );
    }

    function getOfferIdByTokenId(address _storageAddress, uint256 _tokenId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("offerIdIdForTokenId", _tokenId))
        );
    }

    function getSaleStatusForOffer(address _storageAddress, uint256 _offerId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("saleStatusToOffer", _offerId)));
    }
    
    // function getNumberOfOffersBySaleStatus(address _storageAddress, uint256 _saleStatus) 
    //     public view returns (uint256) 
    // {
    //     return SnarkStorage(_storageAddress).uintStorage(
    //         keccak256(abi.encodePacked("numberOfOffersBySaleStatus", _saleStatus)));
    // }
    // function getOfferBySaleStatus(address _storageAddress, uint256 _saleStatus, uint256 _index)
    //     public view returns (uint256)
    // {
    //     return SnarkStorage(_storageAddress).uintStorage(
    //         keccak256(abi.encodePacked("OffersListBySaleStatus", _saleStatus, _index)));
    // }
    function getTotalNumberOfOwnerOffers(address _storageAddress, address _offerOwner) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner))
        );
    }

    function getOfferIdOfOwner(address _storageAddress, address _offerOwner, uint256 _index)
        public view returns (uint256)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("ownerOffersList", _offerOwner, _index))
        );
    }

    function getOwnerOfOffer(address _storageAddress, uint256 _offerId) public view returns (address) {
        return SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("ownerToOffer", _offerId))
        );
    }

    function getTotalNumberOfBids(address _storageAddress) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids"));
    }

    function getOwnerOfBid(address _storageAddress, uint256 _bidId) public view returns (address) {
        return SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("ownerToBid", _bidId))
        );
    }

    function getNumberOfTokenBids(address _storageAddress, uint256 _tokenId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId))
        );
    }

    function getNumberBidsOfOwner(address _storageAddress, address _bidOwner) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
    }

    function getBidOfOwner(address _storageAddress, address _bidOwner, uint256 _index) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, _index)));
    }

    function getBidIdForToken(address _storageAddress, uint256 _tokenId, uint256 _index) 
        public view returns (uint256) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenBidsList", _tokenId, _index))
        );
    }

    function getTokenIdByBidId(address _storageAddress, uint256 _bidId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("tokenIdToBidId", _bidId)));
    }

    function getBidPrice(address _storageAddress, uint256 _bidId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("bidPrice", _bidId)));
    }

    function getBidSaleStatus(address _storageAddress, uint256 _bidId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("bidSaleStatus", _bidId)));
    }

    function setMaxBidPriceForToken(address _storageAddress, uint256 _tokenId, uint256 _price) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("maxBidPriceForToken", _tokenId)), _price);
    }

    function getMaxBidPriceForToken(address _storageAddress, uint256 _tokenId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("maxBidPriceForToken", _tokenId)));
    }

    function setMaxBidIdForToken(address _storageAddress, uint256 _tokenId, uint256 _bidId) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("maxBidIdForToken", _tokenId)), _bidId);
    }

    function getMaxBidIdForToken(address _storageAddress, uint256 _tokenId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("maxBidIdForToken", _tokenId)));
    }

    function getNumberOfActiveBidsForOwner(address _storageAddress, address _bidOwner) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberActiveBidsOfOwner", _bidOwner))
        );
    }

    function increaseNumberOfActiveBidsForOwner(address _storageAddress, address _bidOwner) public {
        uint256 numberOfActiveBids = getNumberOfActiveBidsForOwner(_storageAddress, _bidOwner);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberActiveBidsOfOwner", _bidOwner)), numberOfActiveBids.add(1));
    }

    function decreaseNumberOfActiveBidsForOwner(address _storageAddress, address _bidOwner) public {
        uint256 numberOfActiveBids = getNumberOfActiveBidsForOwner(_storageAddress, _bidOwner);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberActiveBidsOfOwner", _bidOwner)), numberOfActiveBids.sub(1));
    }

    function getActiveBidOfOwnerByIndex(address _storageAddress, address _bidOwner, uint256 _index)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("activeBidsOfOwner", _bidOwner, _index))
        );
    }

}
