pragma solidity ^0.4.24;

import "../SnarkStorage.sol";


library SnarkOfferBidLib {
    /*** SET ***/
    function setPriceForOffer(address _storageAddress, uint256 _offerId, uint256 _price) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("priceForOfferId", _offerId)), _price);
    }

    function setTokenIdForOffer(address _storageAddress, uint256 _offerId, uint256 _tokenId) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("tokenIdForOfferId", _offerId)), _tokenId);
    }

    function setOfferIdForTokenId(address _storageAddress, uint256 _tokenId, uint256 _offerId) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("offerIdIdForTokenId", _tokenId)), _offerId);
    }

    function setSaleStatusForOffer(address _storageAddress, uint256 _offerId, uint256 _saleStatus) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToOffer", _offerId)), _saleStatus);
    }

    function setOwnerForOffer(address _storageAddress, uint256 _offerId, address _offerOwner) external {
        SnarkStorage(_storageAddress).setAddress(keccak256(abi.encodePacked("ownerToOffer", _offerId)), _offerOwner);
    }

    function setOwnerOfBid(address _storageAddress, uint256 _bidId, address _bidOwner) external {
        SnarkStorage(_storageAddress).setAddress(keccak256(abi.encodePacked("ownerToBid", _bidId)), _bidOwner);
    }

    function setTokenToBid(address _storageAddress, uint256 _bidId, uint256 _tokenId) external {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("tokenIdToBidId", _bidId)), _tokenId);
    }

    function setPriceToBid(address _storageAddress, uint256 _bidId, uint256 _price) external {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidPrice", _bidId)), _price);
    }

    function setSaleStatusForBid(address _storageAddress, uint256 _bidId, uint256 _saleStatus) external {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidSaleStatus", _bidId)), _saleStatus);
    }

    /*** DELETE ***/
    function deleteOffer(address _storageAddress, uint256 _offerId) external {

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
            amountOfOwnerOffers - 1);

        for (uint256 i = 0; i < amountOfOwnerOffers; i++) {
            uint256 currentOfferId = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("ownerOffersList", offerOwner, i)));
            if (currentOfferId == _offerId) {
                if (i < amountOfOwnerOffers - 1) {
                    uint256 lastOfferId = SnarkStorage(_storageAddress).uintStorage(
                        keccak256(abi.encodePacked("ownerOffersList", offerOwner, amountOfOwnerOffers - 1)));
                    SnarkStorage(_storageAddress).setUint(
                        keccak256(abi.encodePacked("ownerOffersList", offerOwner, i)), lastOfferId);
                }
                SnarkStorage(_storageAddress).deleteUint(
                    keccak256(abi.encodePacked("ownerOffersList", offerOwner, amountOfOwnerOffers - 1)));
                break;
            }
        }

        // изменяем статус saleType = 'None' для token id: 
        // 0 - None, 1 - Offer, 2 - Auction, 3 - Loan
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleTypeToToken", tokenId)), 0);
        // изменяем статус saleStatus = Finished:
        // 0 - Preparing, 1 - NotActive, 2 - Active, 3 - Finished
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToOffer", _offerId)), 3);

        // удалить офер с предудщим статусом со списка и уменьшить их количетсво
        // добавить в список с новым статусом
    }

    function deleteBid(address _storageAddress, uint256 _bidId) external {
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
                if (i < numberOfTokenBids - 1) {
                    // get the bidId from the last element of array
                    uint256 lastBidId = SnarkStorage(_storageAddress).uintStorage(
                        keccak256(abi.encodePacked("tokenBidsList", tokenId, numberOfTokenBids - 1)));
                    // save it to the current position
                    SnarkStorage(_storageAddress).setUint(
                        keccak256(abi.encodePacked("tokenBidsList", tokenId, i)), lastBidId);
                }
                // delete the last bidId in array
                SnarkStorage(_storageAddress).deleteUint(
                    keccak256(abi.encodePacked("tokenBidsList", tokenId, numberOfTokenBids - 1)));
                // reduce a number of token bids
                SnarkStorage(_storageAddress).setUint(
                    keccak256(abi.encodePacked("numberOfTokenBids", tokenId)), numberOfTokenBids - 1);
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
        external 
        returns (uint256 offerId) 
    {
        // get an Id for this new offer
        offerId = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfOffers")) + 1;
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
            amountOfOwnerOffers + 1);
        // добавляем offer id в список offers владельцу _offerOwner
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerOffersList", _offerOwner, amountOfOwnerOffers)),
            offerId);
        // mapping owner to the offer
        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("ownerToOffer", offerId)),
            _offerOwner);
        // изменяем статус saleType = 'Offer' для token id: 
        // 0 - None, 1 - Offer, 2 - Auction, 3 - Loan
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleTypeToToken", _tokenId)), 1);
        // изменяем статус офера saleStatus = Active:
        // 0 - Preparing, 1 - NotActive, 2 - Active, 3 - Finished
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToOffer", offerId)), 2);

        // uint256 numberOfOffersBySaleStatus = SnarkStorage(_storageAddress).uintStorage(
        //     keccak256(abi.encodePacked("numberOfOffersBySaleStatus", uint256(2))));
        // uint256 newNumberOfOffersBySaleStatus = numberOfOffersBySaleStatus + 1;
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
        external 
        returns (uint256 bidId) 
    {
        // find the max bid price
        uint256 maxBidPrice = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("maxBidPriceForToken", _tokenId)));
        assert(_price > maxBidPrice);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("maxBidPriceForToken", _tokenId)), _price);

        // get new bid id and increase a value of total number of bids
        bidId = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids")) + 1;
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfBids"), bidId);
        
        // mapping owner to the Bid
        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("ownerToBid", bidId)),
            _bidOwner
        );

        // increase amount of token's bids
        uint256 numberOfTokenBids = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)));
        
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)), numberOfTokenBids + 1);
        
        // add bidId to a list of tokenId
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("tokenBidsList", _tokenId, numberOfTokenBids)), bidId);
        
        // тоже самое, но для owner-а... нужно знать список его бидов
        uint256 numberBidsOfOwner = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        uint256 newNumberOfOwnerBids = numberBidsOfOwner + 1;
        assert(newNumberOfOwnerBids >= numberBidsOfOwner);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newNumberOfOwnerBids);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, numberBidsOfOwner)), bidId);

        // binding the bidId with the tokenId
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("tokenIdToBidId", bidId)), _tokenId);
        
        // binding the bidId to the price
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidPrice", bidId)), _price);

        // set a bid saleStatus
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidSaleStatus", bidId)), 2);
    }

    function addBidToTokenBidsList(address _storageAddress, uint256 _tokenId, uint256 _bidId) external {
        uint256 index = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)));

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("tokenBidsList", _tokenId, index)), _bidId);

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)), index + 1);
    }

    function increaseTotalNumberOfOffers(address _storageAddress) external returns (uint256 newAmount) {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfOffers"));
        newAmount = amount + 1;
        assert(newAmount >= amount);
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfOffers"), newAmount);
    }

    function decreaseTotalNumberOfOffers(address _storageAddress) external returns (uint256 newAmount) {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfOffers"));
        assert(1 <= amount);
        newAmount = amount - 1;
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfOffers"), newAmount);
    }

    function increaseTotalNumberOfOwnerOffers(address _storageAddress, address _offerOwner) 
        external 
        returns (uint256 newAmount) 
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)));
        newAmount = amount + 1;
        assert(newAmount >= amount);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)), newAmount);
    }

    function decreaseTotalNumberOfOwnerOffers(address _storageAddress, address _offerOwner) 
        external
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)));
        assert(1 <= amount);
        newAmount = amount - 1;
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)), newAmount);
    }

    function increaseTotalNumberOfBids(address _storageAddress) external returns (uint256 newAmount) {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids"));
        newAmount = amount + 1;
        assert(newAmount >= amount);
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfBids"), newAmount);
    }

    function decreaseTotalNumberOfBids(address _storageAddress) external returns (uint256 newAmount) {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids"));
        assert(1 <= amount);
        newAmount = amount - 1;
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfBids"), newAmount);
    }

    function increaseNumberOfTokenBids(address _storageAddress, uint256 _tokenId) 
        external 
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)));
        newAmount = amount + 1;
        assert(newAmount >= amount);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)), newAmount);
    }

    function decreaseNumberOfTokenBids(address _storageAddress, uint256 _tokenId) 
        external
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)));
        assert(1 <= amount);
        newAmount = amount - 1;
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId)), newAmount);
    }

    function increaseNumberOfOwnerBids(address _storageAddress, address _bidOwner) 
        external 
        returns (uint256 newAmount) 
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        newAmount = amount + 1;
        assert(newAmount >= amount);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newAmount);
    }

    function decreaseNumberOfOwnerBids(address _storageAddress, address _bidOwner)
        external
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        assert(1 <= amount);
        newAmount = amount - 1;
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newAmount);
    }

    function addOfferToOwnerOffersList(address _storageAddress, address _offerOwner, uint256 _offerId)
        external
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)));

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerOffersList", _offerOwner, amount)), _offerId);

        newAmount = amount + 1;
        assert(newAmount >= amount);

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner)), newAmount);
    }

    function addBidToOwnerBidsList(address _storageAddress, address _bidOwner, uint256 _bidId)
        external
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        newAmount = amount + 1;
        assert(newAmount >= amount);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newAmount);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, amount)), _bidId);
    }

    /*** GET ***/
    function getTotalNumberOfOffers(address _storageAddress) external view returns (uint256 numberOfOffers) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfOffers"));
    }

    function getOfferPrice(address _storageAddress, uint256 _offerId) external view returns (uint256 price) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("priceForOfferId", _offerId)));
    }

    function getTokenIdByOfferId(address _storageAddress, uint256 _offerId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenIdForOfferId", _offerId))
        );
    }

    function getOfferIdByTokenId(address _storageAddress, uint256 _tokenId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("offerIdIdForTokenId", _tokenId))
        );
    }

    function getSaleStatusForOffer(address _storageAddress, uint256 _offerId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("saleStatusToOffer", _offerId)));
    }
    
    // function getNumberOfOffersBySaleStatus(address _storageAddress, uint256 _saleStatus) 
    //     external view returns (uint256) 
    // {
    //     return SnarkStorage(_storageAddress).uintStorage(
    //         keccak256(abi.encodePacked("numberOfOffersBySaleStatus", _saleStatus)));
    // }
    // function getOfferBySaleStatus(address _storageAddress, uint256 _saleStatus, uint256 _index)
    //     external view returns (uint256)
    // {
    //     return SnarkStorage(_storageAddress).uintStorage(
    //         keccak256(abi.encodePacked("OffersListBySaleStatus", _saleStatus, _index)));
    // }
    function getTotalNumberOfOwnerOffers(address _storageAddress, address _offerOwner) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfOwnerOffers", _offerOwner))
        );
    }

    function getOfferIdOfOwner(address _storageAddress, address _offerOwner, uint256 _index)
        external view returns (uint256)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("ownerOffersList", _offerOwner, _index))
        );
    }

    function getOwnerOfOffer(address _storageAddress, uint256 _offerId) external view returns (address) {
        return SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("ownerToOffer", _offerId))
        );
    }

    function getTotalNumberOfBids(address _storageAddress) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids"));
    }

    function getOwnerOfBid(address _storageAddress, uint256 _bidId) external view returns (address) {
        return SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("ownerToBid", _bidId))
        );
    }

    function getNumberOfTokenBids(address _storageAddress, uint256 _tokenId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokenBids", _tokenId))
        );
    }

    function getNumberBidsOfOwner(address _storageAddress, address _bidOwner) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
    }

    function getBidOfOwner(address _storageAddress, address _bidOwner, uint256 _index) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, _index)));
    }

    function getBidIdForToken(address _storageAddress, uint256 _tokenId, uint256 _index) 
        external view returns (uint256) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenBidsList", _tokenId, _index))
        );
    }

    function getTokenIdByBidId(address _storageAddress, uint256 _bidId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("tokenIdToBidId", _bidId)));
    }

    function getBidPrice(address _storageAddress, uint256 _bidId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("bidPrice", _bidId)));
    }

    function getBidSaleStatus(address _storageAddress, uint256 _bidId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("bidSaleStatus", _bidId)));
    }

    function getMaxBidPriceForToken(address _storageAddress, uint256 _tokenId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("maxBidPriceForToken", _tokenId)));
    }
}