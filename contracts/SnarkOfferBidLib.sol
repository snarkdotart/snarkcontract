pragma solidity ^0.4.24;

import "./SnarkStorage.sol";


library SnarkOfferBidLib {
    /*** SET ***/
    function setPriceForOffer(address _storageAddress, uint256 _offerId, uint256 _price) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("priceForOfferId", _offerId)), _price);
    }

    function setArtworkIdForOffer(address _storageAddress, uint256 _offerId, uint256 _artworkId) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artworkIdForOfferId", _offerId)), _artworkId);
    }

    function setOfferIdForArtworkId(address _storageAddress, uint256 _artworkId, uint256 _offerId) external {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("offerIdIdForArtworkId", _artworkId)), _offerId);
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

    function setArtworkToBid(address _storageAddress, uint256 _bidId, uint256 _artworkId) external {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("artworkIdToBidId", _bidId)), _artworkId);
    }

    function setPriceToBid(address _storageAddress, uint256 _bidId, uint256 _price) external {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidPrice", _bidId)), _price);
    }

    function setSaleStatusForBid(address _storageAddress, uint256 _bidId, uint256 _saleStatus) external {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidSaleStatus", _bidId)), _saleStatus);
    }

    /*** DELETE ***/
    function deleteOffer(address _storageAddress, uint256 _offerId) external {

        uint256 artworkId = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkIdForOfferId", _offerId)));

        SnarkStorage(_storageAddress).deleteUint(
            keccak256(abi.encodePacked("offerIdIdForArtworkId", artworkId)));

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
        // изменяем статус saleType = 'None' для artwork id: 
        // 0 - None, 1 - Offer, 2 - Auction, 3 - Loan
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleTypeToArtwork", artworkId)), 0);
        // изменяем статус saleStatus = Finished:
        // 0 - Preparing, 1 - NotActive, 2 - Active, 3 - Finished
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToOffer", _offerId)), 3);
    }

    function deleteBid(address _storageAddress, uint256 _bidId) external {
        // getting an artworkId
        uint256 artworkId = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkIdToBidId", _bidId)));
        // it's not neccesary to delete artworkIdToBidId
        // SnarkStorage(_storageAddress).deleteUint(
        //     keccak256(abi.encodePacked("artworkIdToBidId", _bidId)));

        // delete bid from the artwork's list
        uint256 numberOfArtworkBids = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfArtworkBids", artworkId)));
        for (uint256 i = 0; i < numberOfArtworkBids; i++) {
            uint256 currentBidId = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("artworkBidsList", artworkId, i)));
            if (currentBidId == _bidId) {
                if (i < numberOfArtworkBids - 1) {
                    // get the bidId from the last element of array
                    uint256 lastBidId = SnarkStorage(_storageAddress).uintStorage(
                        keccak256(abi.encodePacked("artworkBidsList", artworkId, numberOfArtworkBids - 1)));
                    // save it to the current position
                    SnarkStorage(_storageAddress).setUint(
                        keccak256(abi.encodePacked("artworkBidsList", artworkId, i)), lastBidId);
                }
                // delete the last bidId in array
                SnarkStorage(_storageAddress).deleteUint(
                        keccak256(abi.encodePacked("artworkBidsList", artworkId, numberOfArtworkBids - 1)));
                // reduce a number of artwork bids
                SnarkStorage(_storageAddress).setUint(
                    keccak256(abi.encodePacked("numberOfArtworkBids", artworkId)), numberOfArtworkBids - 1);
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
        uint256 _artworkId, 
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
        // bind an artwork id to the offer id to get the artwork id by means the offer id
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artworkIdForOfferId", offerId)), _artworkId);
        // and vice versa: binding the offer id to the artwork id to get the offer id by means the artwork id
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("offerIdIdForArtworkId", _artworkId)), offerId);
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
        // изменяем статус saleType = 'Offer' для artwork id: 
        // 0 - None, 1 - Offer, 2 - Auction, 3 - Loan
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleTypeToArtwork", _artworkId)), 1);
        // изменяем статус офера saleStatus = Active:
        // 0 - Preparing, 1 - NotActive, 2 - Active, 3 - Finished
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("saleStatusToOffer", offerId)), 2);
    }

    function addBid(
        address _storageAddress, 
        address _bidOwner, 
        uint256 _artworkId, 
        uint256 _price
    ) 
        external 
        returns (uint256 bidId) 
    {
        // get new bid id and increase a value of total number of bids
        bidId = SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids")) + 1;
        SnarkStorage(_storageAddress).setUint(keccak256("totalNumberOfBids"), bidId);
        
        // mapping owner to the Bid
        SnarkStorage(_storageAddress).setAddress(
            keccak256(abi.encodePacked("ownerToBid", bidId)),
            _bidOwner
        );

        // increase amount of artwork's bids
        uint256 numberOfArtworkBids = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId)));
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId)), numberOfArtworkBids + 1);
        
        // add bidId to a list of artworkId
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artworkBidsList", _artworkId, numberOfArtworkBids)), bidId);
        
        // тоже самое, но для owner-а... нужно знать список его бидов
        uint256 numberBidsOfOwner = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        uint256 newNumberOfOwnerBids = numberBidsOfOwner + 1;
        assert(newNumberOfOwnerBids >= numberBidsOfOwner);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newNumberOfOwnerBids);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, numberBidsOfOwner)), bidId);

        // binding the bidId with the artworkId
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("artworkIdToBidId", bidId)), _artworkId);
        
        // binding the bidId to the price
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidPrice", bidId)), _price);

        // set a bid saleStatus
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidSaleStatus", bidId)), 2);
    }

    function addBidToArtworkBidsList(address _storageAddress, uint256 _artworkId, uint256 _bidId) external {
        uint256 index = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId)));

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("artworkBidsList", _artworkId, index)), _bidId);

        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId)), index + 1);
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

    function increaseNumberOfArtworkBids(address _storageAddress, uint256 _artworkId) 
        external 
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId)));
        newAmount = amount + 1;
        assert(newAmount >= amount);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId)), newAmount);
    }

    function decreaseNumberOfArtworkBids(address _storageAddress, uint256 _artworkId) 
        external
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId)));
        assert(1 <= amount);
        newAmount = amount - 1;
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId)), newAmount);
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

    function getArtworkIdByOfferId(address _storageAddress, uint256 _offerId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkIdForOfferId", _offerId))
        );
    }

    function getOfferIdByArtworkId(address _storageAddress, uint256 _artworkId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("offerIdIdForArtworkId", _artworkId))
        );
    }

    function getSaleStatusForOffer(address _storageAddress, uint256 _offerId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("saleStatusToOffer", _offerId)));
    }

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

    function getOfferOwner(address _storageAddress, uint256 _offerId) external view returns (address) {
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

    function getNumberOfArtworkBids(address _storageAddress, uint256 _artworkId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfArtworkBids", _artworkId))
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

    function getBidIdForArtwork(address _storageAddress, uint256 _artworkId, uint256 _index) 
        external view returns (uint256) 
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkBidsList", _artworkId, _index))
        );
    }

    function getArtworkIdByBidId(address _storageAddress, uint256 _bidId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("artworkIdToBidId", _bidId)));
    }

    function getBidPrice(address _storageAddress, uint256 _bidId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("bidPrice", _bidId)));
    }

    function getBidSaleStatus(address _storageAddress, uint256 _bidId) external view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("bidSaleStatus", _bidId)));
    }
}