pragma solidity ^0.4.24;

import "./SnarkBase.sol";


contract SnarkOfferBid is SnarkBase {

    /*** EVENTS ***/

    // New offer event
    event OfferCreatedEvent(uint256 offerId);
    // Approved profit share by participant event
    event NeedApproveOfferEvent(uint256 offerId, address indexed _participant, uint8 _percentAmount);
    // Declined profit share by participant event
    event DeclineApproveOfferEvent(uint256 _offerId, address indexed _offerOwner, address indexed _participant);
    // Offer deleted event
    event OfferDeletedEvent(uint256 _offerId);
    // Offer ended (artworks sold) event
    event OfferEndedEvent(uint256 _offerId);
    // New bid event
    event BidSettedUpEvent(uint256 _bidId, address indexed _bidder, uint256 _value);
    // Canceled bid event
    event BidCanceledEvent(uint256 _artworkId);

    // There are 4 states for an Offer and an Auction:
    // Preparing -recently created and not approved by participants
    // NotActive - created and approved by participants, but is not yet active (auctions only) 
    // Active - created, approved, and active 
    // Finished - finished when the artwork has sold 
    enum SaleStatus { Preparing, NotActive, Active, Finished }

    // Sale type (none, offer sale, auction, art loan)
    enum SaleType { None, Offer, Auction, Loan }

    struct Offer {
        uint256 price;                                              // Proposed sale price in Ether for all artworks
        uint256 countOfArtworks;                                // Number of artworks offered. Decrease with every succesful sale.
        address[] participants;                                     // Profit sharing participants' addresses
        SaleStatus saleStatus;                                      // Offer status (3 possible states: Preparing, Active, Finished)
        mapping (address => uint8) participantToPercentageAmountMap;// Mapping of participants to their profit share
        mapping (address => bool) participantToApproveMap;          // Mapping of participants to their approval indicators
    }

    struct Bid {
        uint artworkId;     // Artwork ID
        uint price;             // Offered price for the digital artwork
        SaleStatus saleStatus;  // Offer status (2 possible states: Active, Finished)
    }

    Offer[] internal offers;    // List of all offers
    Bid[] internal bids;        // List of all bids

    mapping (uint256 => uint256) internal tokenToOfferMap;      // Mapping of artwork to offers
    mapping (uint256 => uint256[]) internal offerToTokensMap;   // Mapping of offer to tokens
    mapping (uint256 => address) internal offerToOwnerMap;      // Mapping of offers to owner
    mapping (address => uint256[]) internal ownerToOffersMap;   // Mapping of owner to offers
    mapping (uint8 => uint256[]) internal saleStatusToOffersMap;// Mapping status to offers
    mapping (uint256 => address) internal bidToOwnerMap;        // Mapping of bids to owner
    mapping (address => uint256[]) internal ownerToBidsMap;     // Mapping of owner to bids
    mapping (uint256 => uint256) internal tokenToBidMap;        // Mapping of artwork to bid
    mapping (uint256 => bool) internal tokenToIsExistBidMap;    // Mapping of artwork to an indicator of an existing bid
    mapping (address => uint256) public pendingWithdrawals;     // Mapping of an address with its balance

    // Artwork can only be in one of four states:
    // 1. Not being sold
    // 2. Offered for sale at an offer price
    // 3. Auction sale
    // 4. Art loan
    // Must avoid any possibility of a double sale
    mapping (uint256 => SaleType) internal tokenToSaleTypeMap;

    /// @dev Modifier that permits only the revenue sharing participants
    /// @param _offerId Offer ID
    modifier onlyOfferParticipator(uint256 _offerId) {
        bool isItParticipant = false;
        address[] storage p = offers[_offerId].participants;
        for (uint8 i = 0; i < p.length; i++) {
            if (msg.sender == p[i]) isItParticipant = true;
        }
        require(isItParticipant);
        _;
    }

    /// @dev Modifier that allows only the owner of the offer
    /// @param _offerId Id of offer
    modifier onlyOfferOwner(uint256 _offerId) {
        require(msg.sender == offerToOwnerMap[_offerId]);
        _;
    }
    
    /// @dev Modifier that checks the artwork is not involved in a sale somewhere else
    /// @param _tokenIds Array of tokens
    modifier onlyNoneStatus(uint256[] _tokenIds) {
        bool isStatusNone = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isStatusNone = (isStatusNone && (tokenToSaleTypeMap[_tokenIds[i]] == SaleType.None));
        }
        require(isStatusNone);
        _;
    }

    /// @dev Modifier that checks that the artworks had a primary sale
    /// @param _tokenIds Array of tokens
    modifier onlyFirstSale(uint256[] _tokenIds) {
        bool isFistSale = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isFistSale = (isFistSale && artworks[_tokenIds[i]].isFirstSale);
        }
        require(isFistSale);
        _;
    }

    /// @dev Modifier that checks that the artworks had a secondary sale 
    /// @param _tokenIds Array of tokens
    modifier onlySecondSale(uint256[] _tokenIds) {
        bool isSecondSale = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isSecondSale = (isSecondSale && !artworks[_tokenIds[i]].isFirstSale);
        }
        require(isSecondSale);
        _;
    }    

    /// @dev Modifier checks that the offer ID is in the offer interval 
    /// @param _offerId Offer ID 
    modifier correctOfferId(uint256 _offerId) {
        require(offers.length > 0);
        require(_offerId < offers.length);
        _;
    }

    /// @dev Modifier that permits only the owner of the Bid 
    /// @param _bidId Bid ID
    modifier onlyBidOwner(uint256 _bidId) {
        require(msg.sender == bidToOwnerMap[_bidId]);
        _;
    }

    /// @dev Function returns the offer count with a specific status 
    /// @param _status Sale status
    function getCountOfOffers(uint8 _status) public view returns (uint256) {        
        require(uint8(SaleStatus.Finished) >= _status);
        return saleStatusToOffersMap[_status].length;
    }

    /// @dev Function returns a list of offers which belong to a specific owner
    /// @param _owner Owner address
    function getOwnerOffersList(address _owner) public view returns (uint256[]) {
        return ownerToOffersMap[_owner];
    }

    /// @dev Function returns all artworks that belong to a specific offer 
    /// @param _offerId Offer ID 
    function getArtworksOffersList(uint256 _offerId) public view correctOfferId(_offerId) returns (uint256[]) {
        return offerToTokensMap[_offerId];
    }

    /// @dev Function to create an offer for the primary sale.  Requires approval of profit sharing participants. 
    /// @param _price The price for all artworks included in the offer
    /// @param _tokenIds List of artwork IDs included in the offer
    /// @param _participants List of profit sharing participants
    /// @param _percentAmounts List of profit share % of participants
    function createOffer(
        uint256 _price, 
        uint256[] _tokenIds, 
        address[] _participants,
        uint8[] _percentAmounts
    ) 
        public 
        onlyOwnerOfMany(_tokenIds)
        // onlyNoneStatus(_tokenIds)
        // onlyFirstSale(_tokenIds)
    {
        // Due to a problem during code compilation, placed the check of 2 modifiers into the function 
        bool isStatusNone = true;
        bool isFistSale = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isStatusNone = (isStatusNone && (tokenToSaleTypeMap[_tokenIds[i]] == SaleType.None));
            isFistSale = (isFistSale && artworks[_tokenIds[i]].isFirstSale);
        }
        require(isStatusNone);
        require(isFistSale);

        // Offer creation and return of the offer ID
        Offer memory _offer = Offer({
            price: _price,
            countOfArtworks: _tokenIds.length,
            participants: new address[](0),
            saleStatus: SaleStatus.Preparing
        });
        uint256 offerId = offers.push(_offer) - 1;
        // apply new profit sharing schedule
        _applyNewSchemaOfProfitDivisionForOffer(offerId, _participants, _percentAmounts);
        // count offers with saleType = Offer
        saleStatusToOffersMap[uint8(SaleStatus.Preparing)].push(offerId);
        // enter the owner of the offer
        offerToOwnerMap[offerId] = msg.sender;
        // increase the number of offers owned by the offer owner
        ownerToOffersMap[msg.sender].push(offerId);
        // for all artworks perform the following:
        for (i = 0; i < _tokenIds.length; i++) {
            // for each artwork mark that is part of an offer
            tokenToSaleTypeMap[_tokenIds[i]] = SaleType.Offer;
            // mark also which specific offer it belongs to
            tokenToOfferMap[_tokenIds[i]] = offerId;
            // add token to an offer list
            offerToTokensMap[offerId].push(_tokenIds[i]);
            // move token to Snark
            _lockOffersToken(offerId, _tokenIds[i]);
        }
        // Generate an event for all profit sharing participants that includes:
        // offer ID, to give the ability to receive and view the offered
        // artworks and their price
        for (i = 0; i < _participants.length; i++) {
            // emit the event to each participant
            emit NeedApproveOfferEvent(offerId, _participants[i], _percentAmounts[i]);
        }
    }

    /// @dev Create an offer for the secondary sale
    /// @param _tokenIds List of artwork token IDs to be included in the offer
    /// @param _price Offer price for all artworks in the offer
    function createOffer(
        uint256[] _tokenIds, 
        uint256 _price
    ) 
        public 
        onlyOwnerOfMany(_tokenIds)
        onlyNoneStatus(_tokenIds)
        onlySecondSale(_tokenIds)
    {
        // Offer creation and return of the offer ID
        Offer memory _offer = Offer({
            price: 0,
            participants: new address[](0),
            countOfArtworks: 0,
            saleStatus: SaleStatus.Preparing
        });
        _offer.price = _price;
        _offer.countOfArtworks = _tokenIds.length;
        uint256 offerId = offers.push(_offer) - 1;
        // count offers with saleType = Offer
        saleStatusToOffersMap[uint8(SaleStatus.Preparing)].push(offerId);
        // enter the owner of the offer
        offerToOwnerMap[offerId] = msg.sender;
        // increase the number of offers owned by the offer owner
        ownerToOffersMap[msg.sender].push(offerId);
        // for all artworks perform the following:
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            // for each artwork mark that is part of an offer
            uint256 _t = _tokenIds[i];
            tokenToSaleTypeMap[_t] = SaleType.Offer;
            // mark also which specific offer it belongs to
            tokenToOfferMap[_t] = offerId;
            // add token to offer list
            offerToTokensMap[offerId].push(_t);
            // move token to Snark
            _lockOffersToken(offerId, _t);            
        }
        // emit an event that a new offer was created
        emit OfferCreatedEvent(offerId);
    }

    /// @dev Profit sharing participants confirm consent to offer terms
    /// @param _offerId Offer ID
    function approveOffer(uint256 _offerId) public onlyOfferParticipator(_offerId) {
        Offer storage offer = offers[_offerId];
        // mark the current participant as approving offer terms
        offer.participantToApproveMap[msg.sender] = true;
        // check whether all participants consented to and offer and form an array with profit sharing %
        bool isAllApproved = true;
        uint8[] memory parts = new uint8[](offer.participants.length);
        for (uint8 i = 0; i < offer.participants.length; i++) {
            isAllApproved = isAllApproved && offer.participantToApproveMap[offer.participants[i]];
            parts[i] = offer.participantToPercentageAmountMap[offer.participants[i]];
        }
        // if all participants consent to the offer, copy the offer terms into the artwork tokens so that each token can contain
        // information on profit sharing %
        if (isAllApproved) {
            uint256[] memory tokens = getArtworksOffersList(_offerId);
            for (i = 0; i < tokens.length; i++) {
                _applyProfitShare(tokens[i], offer.participants, parts);
            }
        }
        // now mark the offer as having been created
        if (isAllApproved) _moveOfferToNextStatus(_offerId);
        emit OfferCreatedEvent(_offerId);
    }

    /// @dev Profit sharing participant declines the offered terms 
    /// @param _offerId Offer ID
    function declineOfferApprove(uint256 _offerId) public onlyOfferParticipator(_offerId) {
        // in this case we only can inform the owner about the refusal
        emit DeclineApproveOfferEvent(_offerId, offerToOwnerMap[_offerId], msg.sender);
    }
    
    /// @dev Delete offer. This is also done during the sale of the last artwork in the offer.  
    /// @param _offerId Offer ID
    function deleteOffer(uint256 _offerId) public onlyOfferOwner(_offerId) {
        // clear all data in the artwork
        uint256[] memory tokens = getArtworksOffersList(_offerId);
        for (uint8 i = 0; i < tokens.length; i++) {
            // change sale status to None
            tokenToSaleTypeMap[tokens[i]] = SaleType.None;
            // delete the artwork from the offer
            delete tokenToOfferMap[tokens[i]];
            // unlock token
            _unlockOffersToken(_offerId, tokens[i]);
        }
        address offerOwner = offerToOwnerMap[_offerId];
        // remove the connection of the offer from the owner
        delete offerToOwnerMap[_offerId];
        // delete the offer from owner
        uint256[] storage ownerOffers = ownerToOffersMap[offerOwner];
        for (i = 0; i < ownerOffers.length; i++) {
            if (ownerOffers[i] == _offerId) {
                ownerOffers[i] = ownerOffers[ownerOffers.length - 1];
                ownerOffers.length--;
                break;
            }
        }
        // mark the offer as finished
        _moveOfferToNextStatus(_offerId);
        // emit event that the offer has been deleted
        emit OfferDeletedEvent(_offerId);
    }

    /// @dev Get a list of all active offers (which are Approved)
    /// @param _status Offer sale status
    function getOffersListByStatus(uint8 _status) public view returns(uint256[]) {
        return saleStatusToOffersMap[_status];
    }

    /// @dev Function of modification of profit sharing participants and their %, in case of rejection of an offer by one of the participants
    /// @param _offerId Offer ID
    /// @param _participants Address array of profit sharing participants
    /// @param _percentAmounts Array of profit share %
    function setNewSchemaOfProfitDivisionForOffer(
        uint256 _offerId,
        address[] _participants,
        uint8[] _percentAmounts
    )
        public
        onlyOfferOwner(_offerId)
    {
        // array length must match
        require(_participants.length == _percentAmounts.length);
        // apply new profit sharing schedule
        _applyNewSchemaOfProfitDivisionForOffer(_offerId, _participants, _percentAmounts);
        // since change of profit shares applied to all participants, need to notify all profit sharing participants for their approval
        for (uint256 i = 0; i < _participants.length; i++) {
            // emit the norification to each participant
            emit NeedApproveOfferEvent(_offerId, _participants[i], _percentAmounts[i]);
        }
    }
 
    /// @dev Function to set bid for an artwork
    /// @param _tokenId Artwork token ID
    function setBid(uint256 _tokenId) public payable {
        // it does not matter if the token is available for sale
        // it is possible to accept a bid unless
        // the artwork is part of an auction
        require(tokenToSaleTypeMap[_tokenId] != SaleType.Auction);
        // Artwork token cannot belong to the bidder
        require(tokenToOwnerMap[_tokenId] != msg.sender);
        require(msg.sender != address(0));

        uint256 bidId;
        if (tokenToIsExistBidMap[_tokenId]) {
            // if the bid has already been specified for the selected artwork, retrieve its bid ID
            bidId = tokenToBidMap[_tokenId];
            // get the bid by its bid ID
            Bid storage bid = bids[bidId];
            // bid must be greater than an earlier bid by at least 5%
            require(msg.value >= bid.price + (bid.price * 5 / 100));
            // earlier bidder needs to get back his bid
            if (bid.price > 0) {
                // write the bid amount to the previous bidder to allow them to later withdraw
                pendingWithdrawals[bidToOwnerMap[bidId]] += bid.price;
                // delete the bid from the bidder
                for (uint8 i = 0; i < ownerToBidsMap[msg.sender].length; i++) {
                    if (ownerToBidsMap[msg.sender][i] == bidId) {
                        ownerToBidsMap[msg.sender][i] = ownerToBidsMap[msg.sender][ownerToBidsMap[msg.sender].length - 1];
                        ownerToBidsMap[msg.sender].length--;
                        break;
                    }
                }
            }
            // establish new bid price
            bid.price = msg.value;
        } else {
            // in the event there was no prior bid for the artwork, we form a new bid
            bidId = bids.push(Bid({
                artworkId: _tokenId,
                price: msg.value,
                saleStatus: SaleStatus.Active
            })) - 1;
            // since there can only be 1 bid for an artwork, we add the new bid to the artwork token ID
            tokenToBidMap[_tokenId] = bidId;
            // mark that a new bid was created for the artwork
            tokenToIsExistBidMap[_tokenId] = true;
        }
        // enter the new owner of the bid
        bidToOwnerMap[bidId] = msg.sender;
        ownerToBidsMap[msg.sender].push(bidId);
        // emit the bid creation event
        emit BidSettedUpEvent(bidId, msg.sender, msg.value);
    }
    
    /// @dev Function to allow the bidder to cancel their own bid
    /// @param _bidId Bid ID
    function cancelBid(uint256 _bidId) public onlyBidOwner(_bidId) {
        address bidder = bidToOwnerMap[_bidId];
        uint256 bidValue = bids[_bidId].price;
        uint256 artworkId = bids[_bidId].artworkId;
        _deleteBid(_bidId);
        bidder.transfer(bidValue);
        emit BidCanceledEvent(artworkId);
    }

    /// @dev Function to view bids by an address
    /// @param _owner Address
    function getBidList(address _owner) public view returns (uint256[]) {
        return ownerToBidsMap[_owner];
    }

    /// @dev Function to view the balance in our contract that an owner can withdraw 
    /// @param _owner Address
    function getWithdrawBalance(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return pendingWithdrawals[_owner];
    }

    /// @dev Function to withdraw funds to the owners wallet 
    /// @param _owner Address
    function withdrawFunds(address _owner) public {
        require(_owner != address(0));
        uint256 balance = pendingWithdrawals[_owner];
        delete pendingWithdrawals[_owner];
        _owner.transfer(balance);
    }

    /// @dev Function to change sale status 
    /// @param _offerId Offer ID
    function _moveOfferToNextStatus(uint256 _offerId) internal {
        uint8 prevStatus = uint8(offers[_offerId].saleStatus);
        if (prevStatus < uint8(SaleStatus.Finished)) {
            for (uint8 i = 0; i < saleStatusToOffersMap[prevStatus].length; i++) {
                if (saleStatusToOffersMap[prevStatus][i] == _offerId) {
                    saleStatusToOffersMap[prevStatus][i] = saleStatusToOffersMap[prevStatus][saleStatusToOffersMap[prevStatus].length - 1];
                    saleStatusToOffersMap[prevStatus].length--;
                    break;
                }
            }
            uint8 newStatus = (prevStatus == 0) ? prevStatus + 2 : prevStatus + 1;
            saleStatusToOffersMap[newStatus].push(_offerId);
            offers[_offerId].saleStatus = SaleStatus(newStatus);
        }
    }

    /// @dev Function to delete bid from the bid array 
    /// @param _bidId Bid ID
    function _deleteBid(uint256 _bidId) internal {
        // delete the bid from the bidder
        address bidder = bidToOwnerMap[_bidId];
        for (uint8 i = 0; i < ownerToBidsMap[bidder].length; i++) {
            if (ownerToBidsMap[bidder][i] == _bidId) {
                ownerToBidsMap[bidder][i] = ownerToBidsMap[bidder][ownerToBidsMap[bidder].length - 1];
                ownerToBidsMap[bidder].length--;
                break;
            }
        }
        // delete the mapping between the artwork and the bid
        delete tokenToBidMap[bids[_bidId].artworkId];
        // delete the mapping between the bid and the owner
        delete bidToOwnerMap[_bidId];
        // mark that the artwork contains no bids
        tokenToIsExistBidMap[bids[_bidId].artworkId] = false;
        // mark bid status as finished
        bids[_bidId].saleStatus = SaleStatus.Finished;
    }

    /// @dev Function to distribute the profits to participants
    /// @param _price Price at which artwork is sold
    /// @param _tokenId Artwork token ID
    /// @param _from Seller Address
    function _incomeDistribution(uint256 _price, uint256 _tokenId, address _from) internal {
        // distribute the profit according to the schedule contained in the artwork token
        Artwork storage artwork = artworks[_tokenId];
        // calculate profit, in primary sale the lastPrice should be 0 while in a secondary it should be a prior sale price
        if (artwork.lastPrice < _price && (_price - artwork.lastPrice) >= 100) {
            uint256 profit = _price - artwork.lastPrice;
            // check whether this sale is primary or secondary
            if (artwork.isFirstSale) { 
                // if it is a primary sale, then mark that the primary sale is over
                artwork.isFirstSale = false;
            } else {
                // if it is a secondary sale, reduce the profit by the profit sharing % specified by the artist 
                // the remaining amount goes back to the seller
                uint256 amountToSeller = _price;
                // the amount to be distributed
                profit = profit * artwork.profitShareFromSecondarySale / 100;
                // the amount that will go to the seller
                amountToSeller -= profit;
                pendingWithdrawals[_from] += amountToSeller;
            }
            uint256 residue = profit; // hold any uncollected amount in residue after paying out all of the participants
            for (uint8 i = 0; i < artwork.participants.length; i++) { // one by one go through each profit sharing participant
                // calculate the payout amount
                uint256 payout = profit * artwork.participantToPercentMap[artwork.participants[i]] / 100;
                pendingWithdrawals[artwork.participants[i]] += payout; // move the payout amount to each participant
                residue -= payout; // recalculate the uncollected amount after the payout
            }
            // if there is any uncollected amounts after distribution, move the amount to the seller
            pendingWithdrawals[_from] += residue;
        } else {
            // if there is no profit, then all goes back to the seller
            pendingWithdrawals[_from] += _price; 
        }
        // mark the price for which the artwork sold
        artwork.lastPrice = _price;
        // mark the sale type to None after sale
        tokenToSaleTypeMap[_tokenId] = SaleType.None;
    }

    /// @dev Lock Token
    /// @param _offerId Offer Id
    /// @param _tokenId Token Id
    function _lockOffersToken(uint256 _offerId, uint256 _tokenId) private {
        address realOwner = offerToOwnerMap[_offerId];
        // move token from artwork Owner to Snark
        _transfer(realOwner, owner, _tokenId);
    }

    /// @dev Unlock Token
    /// @param _offerId Offer Id
    /// @param _tokenId Token Id
    function _unlockOffersToken(uint256 _offerId, uint256 _tokenId) private {
        address realOwner = offerToOwnerMap[_offerId];
        // move token from Snark to artwork Owner
        _transfer(owner, realOwner, _tokenId);
    }
}
