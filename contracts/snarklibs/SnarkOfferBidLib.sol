pragma solidity ^0.4.24;

import "../SnarkStorage.sol";
import "../openzeppelin/SafeMath.sol";


library SnarkOfferBidLib {
    using SafeMath for uint256;

    /*************************************************************/
    /********************** OFFER FUNCTIONS **********************/
    /*************************************************************/
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
    /*************************************************************/
    /*********************** BID FUNCTIONS ***********************/
    /*************************************************************/
    function addBid(address _storageAddress, address _bidOwner, uint256 _tokenId, uint256 _price)
        public 
        returns (uint256 bidId) 
    {
        bidId = increaseTotalNumberOfBids(_storageAddress);
        setMaxBidPriceForToken(_storageAddress, _tokenId, _price);
        setMaxBidForToken(_storageAddress, _tokenId, bidId);
        setOwnerOfBid(_storageAddress, bidId, _bidOwner);
        setTokenToBid(_storageAddress, bidId, _tokenId);
        setBidPrice(_storageAddress, bidId, _price);
        setBidSaleStatus(_storageAddress, bidId, 2); // 2 - Active
        addBidToTokenBidsList(_storageAddress, _tokenId, bidId);
        addBidToOwnerBidsList(_storageAddress, _bidOwner, bidId);
    }

    function deleteBid(address _storageAddress, uint256 _bidId) public {
        deleteBidFromTokenBidsList(_storageAddress, _bidId);
        deleteBidFromOwnerBidsList(_storageAddress, _bidId);
        setBidSaleStatus(_storageAddress, _bidId, 3); // 3 - Finished

        uint256 tokenId = getTokenByBid(_storageAddress, _bidId);
        uint256 maxBid = getMaxBidForToken(_storageAddress, tokenId);
        if (_bidId == maxBid) {
            setMaxBidPriceForToken(_storageAddress, tokenId, 0);
            setMaxBidForToken(_storageAddress, tokenId, 0);
        }
    }

    function getBidPrice(address _storageAddress, uint256 _bidId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("bidPrice", _bidId)));
    }

    function setBidPrice(address _storageAddress, uint256 _bidId, uint256 _price) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidPrice", _bidId)), _price);
    }

    function getBidSaleStatus(address _storageAddress, uint256 _bidId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("bidSaleStatus", _bidId)));
    }

    function setBidSaleStatus(address _storageAddress, uint256 _bidId, uint256 _saleStatus) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("bidSaleStatus", _bidId)), _saleStatus);
    }

    function getMaxBidForToken(address _storageAddress, uint256 _tokenId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("maxBidIdForToken", _tokenId)));
    }

    function setMaxBidForToken(address _storageAddress, uint256 _tokenId, uint256 _bidId) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("maxBidIdForToken", _tokenId)), _bidId);
    }

    function getMaxBidPriceForToken(address _storageAddress, uint256 _tokenId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("maxBidPriceForToken", _tokenId)));
    }

    function setMaxBidPriceForToken(address _storageAddress, uint256 _tokenId, uint256 _price) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("maxBidPriceForToken", _tokenId)), _price);
    }

    function getOwnerOfBid(address _storageAddress, uint256 _bidId) public view returns (address) {
        return SnarkStorage(_storageAddress).addressStorage(
            keccak256(abi.encodePacked("ownerToBid", _bidId))
        );
    }

    function setOwnerOfBid(address _storageAddress, uint256 _bidId, address _bidOwner) public {
        SnarkStorage(_storageAddress).setAddress(keccak256(abi.encodePacked("ownerToBid", _bidId)), _bidOwner);
    }

    function getTokenByBid(address _storageAddress, uint256 _bidId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256(abi.encodePacked("tokenIdToBidId", _bidId)));
    }

    function setTokenToBid(address _storageAddress, uint256 _bidId, uint256 _tokenId) public {
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("tokenIdToBidId", _bidId)), _tokenId);
    }

    function getTotalNumberOfBids(address _storageAddress) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfBids"));
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

    // Bids list for Token functions
    function addBidToTokenBidsList(address _storageAddress, uint256 _tokenId, uint256 _bidId) public {
        require(!getBidActivityForToken(_storageAddress, _bidId, _tokenId), "bid is already included in the list");
        setBidActivityForToken(_storageAddress, _bidId, _tokenId, true);
        uint256 index = increaseNumberBidsOfToken(_storageAddress, _tokenId).sub(1);
        setBidOfTokenByIndex(_storageAddress, _tokenId, index, _bidId);
        setBidIndexInListForToken(_storageAddress, _tokenId, _bidId, index);
    }

    function deleteBidFromTokenBidsList(address _storageAddress, uint256 _bidId) public {
        uint256 tokenId = getTokenByBid(_storageAddress, _bidId);
        require(getBidActivityForToken(_storageAddress, _bidId, tokenId), "bid is already excluded from the list");
        setBidActivityForToken(_storageAddress, _bidId, tokenId, false);
        uint256 index = getBidIndexInListForToken(_storageAddress, tokenId, _bidId);
        uint256 maxIndex = getNumberBidsOfToken(_storageAddress, tokenId).sub(1);
        if (index < maxIndex) {
            uint256 tmpBid = getBidOfTokenByIndex(_storageAddress, tokenId, maxIndex);
            setBidOfTokenByIndex(_storageAddress, tokenId, index, tmpBid);
        }
        decreaseNumberBidsOfToken(_storageAddress, tokenId);
    }

    function getBidActivityForToken(address _storageAddress, uint256 _bidId, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return SnarkStorage(_storageAddress).boolStorage(
            keccak256(abi.encodePacked("isBidActiveForToken", _bidId, _tokenId))
        );
    }

    function setBidActivityForToken(address _storageAddress, uint256 _bidId, uint256 _tokenId, bool _isActive) public {
        SnarkStorage(_storageAddress).setBool(
            keccak256(abi.encodePacked("isBidActiveForToken", _bidId, _tokenId)), _isActive);
    }

    function getBidOfTokenByIndex(address _storageAddress, uint256 _tokenId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenBidsList", _tokenId, _index))
        );
    }

    function setBidOfTokenByIndex(address _storageAddress, uint256 _tokenId, uint256 _index, uint256 _bidId)
        public
    {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("tokenBidsList", _tokenId, _index)),
            _bidId
        );
    }

    function getListOfBidsForToken(address _storageAddress, uint256 _tokenId) public view returns (uint256[]) {
        uint256 countOfBids = getNumberBidsOfToken(_storageAddress, _tokenId);
        uint256[] memory bidsList = new uint256[](countOfBids);
        for (uint256 i = 0; i < countOfBids; i++) {
            bidsList[i] = getBidOfTokenByIndex(_storageAddress, _tokenId, i);
        }
        return bidsList;
    }

    function getNumberBidsOfToken(address _storageAddress, uint256 _tokenId) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfToken", _tokenId))
        );
    }

    function getBidIndexInListForToken(address _storageAddress, uint256 _tokenId, uint256 _bidId)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("bidIndexInListForToken", _tokenId, _bidId))
        );
    }

    function setBidIndexInListForToken(address _storageAddress, uint256 _tokenId, uint256 _bidId, uint256 _index) 
        public 
    {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("bidIndexInListForToken", _tokenId, _bidId)),
            _index
        );
    }

    function increaseNumberBidsOfToken(address _storageAddress, uint256 _tokenId) 
        public 
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfToken", _tokenId)));
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfToken", _tokenId)), newAmount);
    }

    function decreaseNumberBidsOfToken(address _storageAddress, uint256 _tokenId) 
        public
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfToken", _tokenId)));
        newAmount = amount.sub(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfToken", _tokenId)), newAmount);
    }

    // Bids list for Owner functions
    function addBidToOwnerBidsList(address _storageAddress, address _bidOwner, uint256 _bidId) public {
        require(!getBidActivityForOwner(_storageAddress, _bidId, _bidOwner), "bid is already included in the list");
        setBidActivityForOwner(_storageAddress, _bidId, _bidOwner, true);
        uint256 index = increaseNumberBidsOfOwner(_storageAddress, _bidOwner).sub(1);
        setBidOfOwnerByIndex(_storageAddress, _bidOwner, index, _bidId);
        setBidIndexInListForOwner(_storageAddress, _bidOwner, _bidId, index);
    }

    function deleteBidFromOwnerBidsList(address _storageAddress, uint256 _bidId) public {
        address bidOwner = getOwnerOfBid(_storageAddress, _bidId);
        require(getBidActivityForOwner(_storageAddress, _bidId, bidOwner), "bid is already excluded from the list");
        setBidActivityForOwner(_storageAddress, _bidId, bidOwner, false);
        uint256 index = getBidIndexInListForOwner(_storageAddress, bidOwner, _bidId);
        uint256 maxIndex = getNumberBidsOfOwner(_storageAddress, bidOwner).sub(1);
        if (index < maxIndex) {
            uint256 tmpBid = getBidOfOwnerByIndex(_storageAddress, bidOwner, maxIndex);
            setBidOfOwnerByIndex(_storageAddress, bidOwner, index, tmpBid);
        }
        decreaseNumberBidsOfOwner(_storageAddress, bidOwner);
    }

    function getBidActivityForOwner(address _storageAddress, uint256 _bidId, address _bidOwner)
        public
        view
        returns (bool)
    {
        return SnarkStorage(_storageAddress).boolStorage(
            keccak256(abi.encodePacked("isBidActiveForOwner", _bidId, _bidOwner))
        );
    }

    function setBidActivityForOwner(address _storageAddress, uint256 _bidId, address _bidOwner, bool _isActive) public {
        SnarkStorage(_storageAddress).setBool(
            keccak256(abi.encodePacked("isBidActiveForOwner", _bidId, _bidOwner)),
            _isActive
        );
    }

    function getBidOfOwnerByIndex(address _storageAddress, address _bidOwner, uint256 _index)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, _index)));
    }

    function setBidOfOwnerByIndex(address _storageAddress, address _bidOwner, uint256 _index, uint256 _bidId) public {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("ownerBidsList", _bidOwner, _index)),
            _bidId
        );
    }

    function getListOfBidsForOwner(address _storageAddress, address _bidOwner) public view returns (uint256[]) {
        uint256 countOfBids = getNumberBidsOfOwner(_storageAddress, _bidOwner);
        uint256[] memory bidsList = new uint256[](countOfBids);
        for (uint256 i = 0; i < countOfBids; i++) {
            bidsList[i] = getBidOfOwnerByIndex(_storageAddress, _bidOwner, i);
        }
        return bidsList;
    }

    function getNumberBidsOfOwner(address _storageAddress, address _bidOwner) public view returns (uint256) {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
    }

    function getBidIndexInListForOwner(address _storageAddress, address _bidOwner, uint256 _bidId)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("bidIndexInListForOwner", _bidOwner, _bidId))
        );
    }

    function setBidIndexInListForOwner(address _storageAddress, address _bidOwner, uint256 _bidId, uint256 _index)
        public
    {
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("bidIndexInListForOwner", _bidOwner, _bidId)),
            _index
        );
    }

    function increaseNumberBidsOfOwner(address _storageAddress, address _bidOwner) 
        public 
        returns (uint256 newAmount) 
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        newAmount = amount.add(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newAmount);
    }

    function decreaseNumberBidsOfOwner(address _storageAddress, address _bidOwner)
        public
        returns (uint256 newAmount)
    {
        uint256 amount = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)));
        newAmount = amount.sub(1);
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("numberBidsOfOwner", _bidOwner)), newAmount);
    }


}
