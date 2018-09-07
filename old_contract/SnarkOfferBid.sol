pragma solidity ^0.4.24;

import "./SnarkBase.sol";


contract SnarkOfferBid is SnarkBase {

    /*** EVENTS ***/

    // New offer event
    event OfferCreatedEvent(uint256 offerId, uint tokenId);
    // Offer deleted event
    event OfferDeletedEvent(uint256 _offerId);
    // Offer ended (artworks sold) event
    event OfferEndedEvent(uint256 _offerId);
    // New bid event
    event BidSettedUpEvent(uint256 _bidId, address indexed _bidder, uint256 _value);
    // Canceled bid event
    event BidCanceledEvent(uint256 _artworkId, uint256 _bidId);

    /// @dev Modifier that allows only the owner of the offer
    /// @param _offerId Id of offer
    modifier onlyOfferOwner(uint256 _offerId) {
        require(msg.sender == _storage.get_offerToOwnerMap(_offerId));
        _;
    }
    
    /// @dev Modifier that permits only the owner of the Bid 
    /// @param _bidId Bid ID
    modifier onlyBidOwner(uint256 _bidId) {
        require(msg.sender == _storage.get_bidToOwnerMap(_bidId));
        _;
    }

    constructor(address _storageAddress) public SnarkBase(_storageAddress) {
    }

    /// @dev Function returns the offer count with a specific status 
    /// @param _status Sale status
    function getOffersCount(uint8 _status) public view returns (uint256) {        
        require(_status <= uint8(SaleStatus.Finished));
        return _storage.get_saleStatusToOffersMap_length(_status);
    }

    /// @dev Function returns a count of offers which belong to a specific owner
    /// @param _owner Owner address
    function getOwnerOffersCount(address _owner) public view returns (uint256 offersCount) {
        return _storage.get_ownerToOffersMap_length(_owner);
    }

    function getOwnerOfferByIndex(address _owner, uint256 _index) public view returns (uint256 offerId) {
        return _storage.get_ownerToOffersMap(_owner, _index);
    }

    /// @dev Function to create an offer for the secondary sale.
    /// @param _tokenId Artwork IDs included in the offer
    /// @param _price The price for all artworks included in the offer
    function createSaleOffer(
        uint256 _tokenId,
        uint256 _price
    ) 
        public 
        onlyOwnerOf(_tokenId)
    {
        bool isStatusNone = true;
        bool isSecondSale = true;
        uint256 lastPrice = 0;
        isStatusNone = (isStatusNone && (_storage.get_tokenToSaleTypeMap(_tokenId) == uint8(SaleType.None)));
        (, , , lastPrice) = _storage.get_artwork_description(_tokenId);
        isSecondSale = (isSecondSale && (lastPrice != 0));

        require(isStatusNone && isSecondSale);

        // Offer creation and return of the offer ID
        uint256 offerId = _storage.add_offer(_price, _tokenId);
        // count offers with saleType = Offer
        _storage.add_saleStatusToOffersMap(uint8(SaleStatus.Active), offerId);
        // enter the owner of the offer
        _storage.set_offerToOwnerMap(offerId, msg.sender);
        // increase the number of offers owned by the offer owner
        _storage.add_ownerToOffersMap(msg.sender, offerId);
        // for each artwork mark that is part of an offer
        _storage.set_tokenToSaleTypeMap(_tokenId, uint8(SaleType.Offer));
        // mark also which specific offer it belongs to
        _storage.set_tokenToOfferMap(_tokenId, offerId);
        // move token to Snark
        _lockOffersToken(offerId, _tokenId);
        // Emit an event that returns token id and offer id as well
        emit OfferCreatedEvent(offerId, _tokenId);
    }

    /// @dev Delete offer. This is also done during the sale of the last artwork in the offer.  
    /// @param _offerId Offer ID
    function deleteSaleOffer(uint256 _offerId) public onlyOfferOwner(_offerId) {
        // mark the offer as finished
        _storage.finish_offer(_offerId);
        // clear all data in the artwork
        uint256 tokenId;
        (tokenId, , ) = _storage.get_offer(_offerId);
        // change sale status to None
        _storage.set_tokenToSaleTypeMap(tokenId, uint8(SaleType.None));
        // delete the artwork from the offer
        _storage.delete_tokenToOfferMap(tokenId);
        // unlock token
        _unlockOffersToken(_offerId, tokenId);
            
        address offerOwner = _storage.get_offerToOwnerMap(_offerId);
        // remove the connection of the offer from the owner
        _storage.delete_offerToOwnerMap(_offerId);
        // delete the offer from owner
        uint256 offersCount = _storage.get_ownerToOffersMap_length(offerOwner);
        for (uint256 i = 0; i < offersCount; i++) {
            if (_storage.get_ownerToOffersMap(offerOwner, i) == _offerId) {
                _storage.delete_ownerToOffersMap(offerOwner, i);
                break;
            }
        }
        // emit event that the offer has been deleted
        emit OfferDeletedEvent(_offerId);
    }

    /// @dev Function to set bid for an artwork
    /// @param _tokenId Artwork token ID
    function setBid(uint256 _tokenId) public payable {
        require(msg.sender != address(0));
        // it does not matter if the token is available for sale
        // it is possible to accept a bid unless
        // the artwork is part of an auction or a loan
        SaleType currentSaleType = SaleType(_storage.get_tokenToSaleTypeMap(_tokenId));
        require(currentSaleType == SaleType.Offer || currentSaleType == SaleType.None);
        address currentOwner;
        uint256 offerId;
        uint256 price;
        if (currentSaleType == SaleType.Offer) {
            offerId = _storage.get_tokenToOfferMap(_tokenId);
            currentOwner = _storage.get_offerToOwnerMap(offerId);
            (, price, ) = _storage.get_offer(offerId);
            // If an OFFER exists for an artwork, ANY collector can BID for the artwork at a price LOWER 
            // than the OFFER price.  If a BID is made at the OFFER price or HIGHER, than the platform should 
            // notify the bidder that they must BUY the artwork at an OFFER price or revise the BID to something 
            // lower than the OFFER price.
            require(msg.value < price);
        } else {
            currentOwner = _storage.get_tokenToOwnerMap(_tokenId);
        }
        // Artwork token cannot belong to the bidder
        require(currentOwner != msg.sender);

        // If there is NO OFFER made for an artwork by the owner, ANY collector can BID for the artwork at ANY price.
        // If there is a BID outstanding that has not been accepted by the artwork owner, another collector can make 
        // a BID at a ANY price higher than the highest outstanding BID. 
        uint256 bidsCount = _storage.get_tokenToBidsMap_length(_tokenId);
        uint256 maxBidsPrice = 0;
        uint256 bidId;
        for (uint256 i = 0; i < bidsCount; i++) {
            bidId = _storage.get_tokenToBidsMap(_tokenId, i);
            (, price, ) = _storage.get_bid(bidId);
            if (price > maxBidsPrice) maxBidsPrice = price;
        }
        require(msg.value > maxBidsPrice);

        bidId = _storage.add_bid(_tokenId, msg.value);
        _storage.add_tokenToBidsMap(_tokenId, bidId);
        _storage.set_bidToOwnerMap(bidId, msg.sender);
        _storage.add_ownerToBidsMap(msg.sender, bidId);

        // adding an amount of this bid to a contract balance
        _storage.add_pendingWithdrawals(address(this), msg.value);

        // emit the bid creation event
        emit BidSettedUpEvent(bidId, msg.sender, msg.value);
    }

    /// @dev Function to accept bid
    /// @param _bidId Id of bid
    function acceptBid(uint256 _bidId) public {
        // To persuade if this function called a token owner
        uint256 tokenId;
        uint256 price;
        (tokenId, price,) = _storage.get_bid(_bidId);
        SaleType saleType = SaleType(_storage.get_tokenToSaleTypeMap(tokenId));
        // it's forbidden to accept the Bid when it has a Loan Status
        require(saleType == SaleType.Offer || saleType == SaleType.None);
        address tokenOwner;
        address mediator;
        uint256 offerId;
        if (saleType == SaleType.Offer) {
            // in this case the token is blocked and we can get a real address via an offer
            offerId = _storage.get_tokenToOfferMap(tokenId);
            tokenOwner = _storage.get_offerToOwnerMap(offerId);
            mediator = _storage.get_tokenToOwnerMap(tokenId);
        } else {
            tokenOwner = _storage.get_tokenToOwnerMap(tokenId);
            mediator = tokenOwner;
        }
        // Only token's owner can accept the bid
        require(msg.sender == tokenOwner);

        address bidOwner = _storage.get_bidToOwnerMap(_bidId);
        _storage.sub_pendingWithdrawals(address(this), price);
        uint256 profit;
        (profit, price) = _calculatePlatformProfitShare(price);
        _takePlatformProfitShare(price);

        _buy(tokenId, price, tokenOwner, bidOwner, mediator);
        _deleteBid(_bidId, tokenId, bidOwner);

        // deleting all bids relating with the token
        // but we have to take back bid amounts to their owners as well
        _takeBackBidAmountsAndDeleteAllTokenBids(tokenId);
    }
    
    /// @dev Function to allow the bidder to cancel their own bid
    /// @param _bidId Bid ID
    function cancelBid(uint256 _bidId) public onlyBidOwner(_bidId) {
        address bidder = _storage.get_bidToOwnerMap(_bidId);
        uint256 tokenId;
        uint256 price;
        (tokenId, price,) = _storage.get_bid(_bidId);
        _deleteBid(_bidId, tokenId, bidder);
        bidder.transfer(price);
        emit BidCanceledEvent(tokenId, _bidId);
    }

    /// @dev Accepting the artist's offer
    /// @param _offerId Offer ID
    function buyOffer(uint256 _offerId) public payable {
        uint256 tokenId;
        uint256 price;
        uint8 saleStatus;
        (tokenId, price, saleStatus) = _storage.get_offer(_offerId);
        require(saleStatus == uint8(SaleStatus.Active));
        require(msg.value >= price);

        address tokenOwner = _storage.get_offerToOwnerMap(_offerId);
        address mediator = _storage.get_tokenToOwnerMap(tokenId);

        require(msg.sender != tokenOwner);

        price = _takePlatformProfitShare(price);
        _buy(tokenId, price, tokenOwner, msg.sender, mediator);
        _storage.finish_offer(_offerId);

        // If there are bids for the offer than we takes back an amount to their owners. 
        // After that we can delete bids.
        _takeBackBidAmountsAndDeleteAllTokenBids(tokenId);
    }

    function _takeBackBidAmountsAndDeleteAllTokenBids(uint256 _tokenId) internal {
        uint256 bidsCount = _storage.get_tokenToBidsMap_length(_tokenId);
        uint256 bidId;
        address bidder;
        uint256 bidPrice;
        for (uint256 i = 0; i < bidsCount; i++) {
            bidId = _storage.get_tokenToBidsMap(_tokenId, 0);
            bidder = _storage.get_bidToOwnerMap(bidId);
            (, bidPrice, ) = _storage.get_bid(bidId);
            // Moving these amount from contract's balance to the bid's one
            _storage.sub_pendingWithdrawals(address(this), bidPrice);
            _storage.add_pendingWithdrawals(bidder, bidPrice);
            // Delete the bid
            _deleteBid(bidId, _tokenId, bidder);
        }
    }

    /// @dev Function to delete bid from the bid array 
    /// @param _bidId Bid ID
    /// @param _tokenId Artwork ID
    /// @param _bidder Address of bidder
    function _deleteBid(uint256 _bidId, uint256 _tokenId, address _bidder) internal {
        uint256 bidsCount = _storage.get_ownerToBidsMap_length(_bidder);
        for (uint256 i = 0; i < bidsCount; i++) {
            if (_storage.get_ownerToBidsMap(_bidder, i) == _bidId) {
                _storage.delete_ownerToBidsMap(_bidder, i);
                break;
            }
        }
        // delete the mapping between the artwork and the bid
        bidsCount = _storage.get_tokenToBidsMap_length(_tokenId);
        for (i = 0; i < bidsCount; i++) {
            if (_storage.get_tokenToBidsMap(_tokenId, i) == _bidId) {
                _storage.delete_tokenToBidsMap(_tokenId, i);
                break;
            }
        }
        // delete the mapping between the bid and the owner
        _storage.delete_bidToOwnerMap(_bidId);
        // mark bid status as finished
        _storage.finish_bid(_bidId);
    }

    /// @dev Lock Token
    /// @param _offerId Offer Id
    /// @param _tokenId Token Id
    function _lockOffersToken(uint256 _offerId, uint256 _tokenId) private {
        address realOwner = _storage.get_offerToOwnerMap(_offerId);
        // move token from artwork Owner to Snark
        _transfer(realOwner, owner, _tokenId);
    }

    /// @dev Unlock Token
    /// @param _offerId Offer Id
    /// @param _tokenId Token Id
    function _unlockOffersToken(uint256 _offerId, uint256 _tokenId) private {
        address realOwner = _storage.get_offerToOwnerMap(_offerId);
        // move token from Snark to artwork Owner
        _transfer(owner, realOwner, _tokenId);
    }

    // /// @dev Function to view bids by an address
    // /// @param _owner Address
    // function getBidList(address _owner) public view returns (uint256[]) {
    //     return ownerToBidsMap[_owner];
    // }

    // /// @dev Function to create an offer for the secondary sale.
    // /// @param _price The price for all artworks included in the offer
    // /// @param _tokenIds List of artwork IDs included in the offer
    // function createOffer(
    //     uint256 _price, 
    //     uint256[] _tokenIds
    // ) 
    //     public 
    //     onlyOwnerOfMany(_tokenIds)
    // {
    //     bool isStatusNone;
    //     bool isSecondSale;
    //     uint256 lastPrice;
    //     uint256 offerId;

    //     for (uint8 i = 0; i < _tokenIds.length; i++) {
    //         isStatusNone = true;
    //         isSecondSale = true;
    //         lastPrice = 0;
    //         isStatusNone = (isStatusNone && (_storage.get_tokenToSaleTypeMap(_tokenIds[i]) == SaleType.None));
    //         (,,,lastPrice) = _storage.get_artwork_description(_tokenIds[i]);
    //         isSecondSale = (isSecondSale && (lastPrice != 0));

    //         if (isStatusNone && isSecondSale) {
    //             // Offer creation and return of the offer ID
    //             offerId = _storage.add_offer(_price, _tokenIds[i]);
    //             // count offers with saleType = Offer
    //             _storage.add_saleStatusToOffersMap(uint8(SaleStatus.Active), offerId);
    //             // enter the owner of the offer
    //             _storage.set_offerToOwnerMap(offerId, msg.sender);
    //             // increase the number of offers owned by the offer owner
    //             _storage.add_ownerToOffersMap(msg.sender, offerId);
    //             // for each artwork mark that is part of an offer
    //             _storage.set_tokenToSaleTypeMap(_tokenIds[i], SaleType.Offer);
    //             // mark also which specific offer it belongs to
    //             // _storage.set_tokenToOfferMap(_tokenIds[i], offerId);
    //             // move token to Snark
    //             _lockOffersToken(offerId, _tokenIds[i]);
    //             emit OfferCreatedEvent(offerId, _tokenIds[i]);
    //         } else {
    //             emit OfferDeclinedForTokens(_tokenIds[i]);
    //         }
    //     }
    // }

}
