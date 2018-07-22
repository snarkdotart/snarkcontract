pragma solidity ^0.4.24;

import "./SnarkLoan.sol";


contract SnarkTrade is SnarkLoan {

    // Modifier that filters the token ownership to one
    modifier onlyOwnerOfMany(uint256[] _tokenIds) {
        bool isSenderOwner = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isSenderOwner = (isSenderOwner && (msg.sender == tokenToOwnerMap[_tokenIds[i]]));
        }
        require(isSenderOwner);
        _;
    }

    /// @dev Transfer function of artwork token ownership to a new owner if the previous owner approved this transfer to the new owner
    /// @param _tokenId Token ID (artwork token for transfer to the new owner)
    function takeOwnership(uint256 _tokenId) public {
        require(tokenToApprovalsMap[_tokenId] == msg.sender);
        address owner = tokenToOwnerMap[_tokenId];
        _transfer(owner, msg.sender, _tokenId);
    }

    /// @dev Function returns the count of artwork tokens in the system
    function getCountOfTokens() public view returns(uint256) {
        return artworks.length;
    }

    /// @dev Function returns the list of artwork tokens belonging to a specific owner
    /// @param _owner Owner address
    function getOwnerTokenList(address _owner) public view returns (uint256[]) {
        return ownerToTokensMap[_owner];
    }

    /// @dev Function to accept a bid and sale of the artwork to the bidder.  At the end removes all outstanding offers and bids.
    function acceptBid(uint256 _bidId) public onlyOwnerOf(_tokenId) {
        // Retrieve the artwork token ID that the owner is willing to sell at the bid price
        uint256 _tokenId = bids[_bidId].artworkId;
        // Record from whom and to whom the artwork has moved
        address _from = msg.sender;
        address _to = bidToOwnerMap[_bidId];
        // Record the new price based on the bid
        uint256 _price = bids[_bidId].price;
        // Record the new owner in the token to owner mapping
        tokenToOwnerMap[_tokenId] = _to;
        // Since the money has already been transfered for accepted bid, move the token to the new owner
        _transfer(_from, _to, _tokenId);
        // Check if there was an offer
        bool containsOffer = (tokenToSaleTypeMap[_tokenId] == SaleType.Offer);
        // Distribute the profit
        _incomeDistribution(_price, _tokenId, _from);
        // Delete the bid
        _deleteBid(_bidId);
        // If there was an offer, delete it
        if (containsOffer) {
            uint256 offerId = tokenToOfferMap[_tokenId];
            // Delete offer only if there are no more artworks contained in the offer
            if (getArtworksOffersList(offerId).length == 0)
                deleteOffer(offerId);
        }
    }

    /// Function for artwork sale.  Remove all outstanding offers and bids after sale.
    /// @dev Function to complete the artwork sale.Фукнция совершения покупки полотна
    /// @param _tokenId Artwork Token ID
    function buyToken(address _from, address _to, uint256 _tokenId) internal {
        require(tokenToSaleTypeMap[_tokenId] == SaleType.Offer || tokenToSaleTypeMap[_tokenId] == SaleType.Auction);
        bool isTypeOffer = (tokenToSaleTypeMap[_tokenId] == SaleType.Offer);
        uint256 _price;
        if (isTypeOffer) {
            uint256 offerId = tokenToOfferMap[_tokenId];
            require(_from == offerToOwnerMap[offerId]);
            _price = offers[offerId].price;
        } else {
            uint256 auctionId = tokenToAuctionMap[_tokenId];
            require(_from == auctionToOwnerMap[auctionId]);
            _price = auctions[auctionId].workingPrice;
        }
        require(msg.value >= _price); 
        require(_from != _to);
        // Record the new owner
        tokenToOwnerMap[_tokenId] = _to;
        // Move the token to the new owner
        _transfer(_from, _to, _tokenId); 
        // Distribute the profit
        _incomeDistribution(msg.value, _tokenId, _from);
        // Delete bid if there is a bid
        if (tokenToIsExistBidMap[_tokenId]) {
            uint256 bidId = tokenToBidMap[_tokenId];
            uint256 bidValue = bids[bidId].price;
            address bidder = bidToOwnerMap[bidId];
            _deleteBid(bidId);
            bidder.transfer(bidValue);
        }
        // Delete Offer and Auction if there are offers and auctions for the artwork
        if (isTypeOffer) {
            offers[offerId].countOfArtworks--;
            if (offers[offerId].countOfArtworks == 0)
                deleteOffer(offerId);
        } else {
            auctions[auctionId].countOfArtworks--;
            if (auctions[auctionId].countOfArtworks == 0)
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
    //         offers[offerId].countOfArtworks--;
    //         if (offers[offerId].countOfArtworks == 0)
    //             deleteOffer(offerId);
    //     } else {
    //         auctions[auctionId].countOfArtworks--;
    //         if (auctions[auctionId].countOfArtworks == 0)
    //             _deleteAuction(auctionId);
    //     }
    // }

}
