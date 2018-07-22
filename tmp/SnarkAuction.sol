pragma solidity ^0.4.24;

import "./SnarkOfferBid.sol";


contract SnarkAuction is SnarkOfferBid {

    /*** EVENTS ***/
    
    // Event notifying that the Auction participant does not agree with the terms of the Auction
    event DeclineApproveAuctionEvent(uint256 _auctionId, address indexed _offerOwner, address indexed _participant);
    // Event notifying of a new Auction
    event AuctionCreatedEvent(uint256 _auctionId);
    // Event notifying the Auction participant to approve his share in the sale of artwork
    event NeedApproveAuctionEvent(uint256 _auctionId, address indexed _participant, uint8 _percentAmount);
    // Event notifying that the Auction has ended (all artworks sold)
    event AuctonEnded(uint256 _auctionId);
    // Event notifying that the Auction price has changed
    event AuctionPriceChanged(uint256 _auctionId, uint256 newPrice);
    // Event notifying that the Auction has finished
    event AuctionFinishedEvent(uint256 _auctionId);


    // List of all auctions    
    Auction[] internal auctions;

    mapping (uint256 => uint256) internal tokenToAuctionMap;        // Mapping of the digital artwork to the auction in which it is participating
    mapping (uint256 => uint256[]) internal auctionToTokensMap;     // Mapping of an auction to tokens
    mapping (uint256 => address) internal auctionToOwnerMap;        // Mapping of an auction with its owner
    mapping (address => uint256) internal ownerToCountAuctionsMap;  // Count of auctions belonging to the same owner

    /// @dev Modifier that allows only the Auction owner
    /// @param _auctionId Auction Id
    modifier onlyAuctionOwner(uint256 _auctionId) {
        require(msg.sender == auctionToOwnerMap[_auctionId]);
        _;
    }

    /// @dev Modifier that checks that the Auction ID is inside the Auction interval
    /// @param _auctionId Auction Id
    modifier correctAuctionId(uint256 _auctionId) {
        require(auctions.length > 0);
        require(_auctionId < auctions.length);
        _;        
    }

    /// @dev Modifier that allows only the profit sharing participants 
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

    /// @dev Function to create an Auction for the primary sale.  Calls for an approval event from profit sharing participants. 
    /// @param _tokenIds List of artwork token IDs included in the Auction
    /// @param _startingPrice Auction start price
    /// @param _endingPrice Auction ending price
    /// @param _startingDate Date of Auction start (timestamp)
    /// @param _duration Auction duration (in days)
    /// @param _participants List of profit sharing participants
    /// @param _percentAmounts List of profit sharing %
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
        // onlyOwnerOfMany(_tokenIds)
        // onlyNoneStatus(_tokenIds)
        // onlyFirstSale(_tokenIds)
    {
        // Due to an error during code compilation, the modifier check is placed directly into the function
        bool isOwnerOfAll = true;
        bool isStatusNone = true;
        bool isFistSale = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && (msg.sender == tokenToOwnerMap[_tokenIds[i]]);
            isStatusNone = (isStatusNone && (tokenToSaleTypeMap[_tokenIds[i]] == SaleType.None));
            isFistSale = (isFistSale && artworks[_tokenIds[i]].isFirstSale);
        }
        require(isOwnerOfAll);
        require(isStatusNone);
        require(isFistSale);

        uint256 auctionId = auctions.push(Auction({
            startingPrice: _startingPrice,
            endingPrice: _endingPrice,
            workingPrice: _startingPrice,
            startingDate: _startingDate,
            duration: _duration,
            participants: new address[](0),
            countOfArtworks: _tokenIds.length,
            saleStatus: SaleStatus.Preparing
        })) - 1;
        // Apply profit sharing schedule to the auction (not to digital artworks)
        _applyNewSchemaOfProfitDivisionForAuction(auctionId, _participants, _percentAmounts);
        // Assign the owner for the Auction
        auctionToOwnerMap[auctionId] = msg.sender;
        // Increase the number of auctions assigned to the owner
        ownerToCountAuctionsMap[msg.sender]++;
        // Perform the following for all digital artworks included in the Auction:
        for (i = 0; i < _tokenIds.length; i++) {
            // Mark each artwork as participating in an auction
            tokenToSaleTypeMap[_tokenIds[i]] = SaleType.Auction;
            // Mark to which auction the artwork belongs
            tokenToAuctionMap[_tokenIds[i]] = auctionId;
            // Mapping of auction to tokens
            auctionToTokensMap[auctionId].push(_tokenIds[i]);
            // Move token to Snark
            _lockAuctionsToken(auctionId, _tokenIds[i]);
        }
        // Emit approval notification for all participants
        for (i = 0; i < _participants.length; i++) {
            emit NeedApproveAuctionEvent(auctionId, _participants[i], _percentAmounts[i]);
        }
    }

    /// @dev Function to create an Auction for Secondary Sale. 
    /// @param _tokenIds List of artwork token IDs to be included in the Auction
    /// @param _startingPrice Auction start price
    /// @param _endingPrice Auction ending price
    /// @param _startingDate Date of Auction start (timestamp)
    /// @param _duration Auction duration (in days)
    function createAuction(
        uint256[] _tokenIds,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint64 _startingDate,
        uint16 _duration
    ) 
        public
        onlyOwnerOfMany(_tokenIds)
        // onlyNoneStatus(_tokenIds)
        // onlySecondSale(_tokenIds)
    {
        // Due to an error during code compilation, the modifier check is placed directly into the function
        bool isStatusNone = true;
        bool isSecondSale = true;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            isStatusNone = (isStatusNone && (tokenToSaleTypeMap[_tokenIds[i]] == SaleType.None));
            isSecondSale = (isSecondSale && !artworks[_tokenIds[i]].isFirstSale);
        }
        require(isStatusNone);
        require(isSecondSale);

        uint256 auctionId = auctions.push(Auction({
            startingPrice: _startingPrice,
            endingPrice: _endingPrice,
            workingPrice: _startingPrice,
            startingDate: _startingDate,
            duration: _duration,
            participants: new address[](0),
            countOfArtworks: _tokenIds.length,
            saleStatus: SaleStatus.NotActive
        })) - 1;
        // Assign the owner for the Auction
        auctionToOwnerMap[auctionId] = msg.sender;
        // Increase the number of auctions assigned to the owner
        ownerToCountAuctionsMap[msg.sender]++;
        // Perform the following for all digital artworks included in the Auction:
        for (i = 0; i < _tokenIds.length; i++) {
            // Mark each artwork as participating in an auction
            tokenToSaleTypeMap[_tokenIds[i]] = SaleType.Auction;
            // Mark to which auction the artwork belongs
            tokenToAuctionMap[_tokenIds[i]] = auctionId;
            // Mapping of auction to tokens
            auctionToTokensMap[auctionId].push(_tokenIds[i]);
            // Move token to Snark
            _lockAuctionsToken(auctionId, _tokenIds[i]);
        }
        // Emit notification that Auction was created
        emit AuctionCreatedEvent(auctionId);
    }

    /// @dev Function of modifying profit sharing schedule for the auction, in the event of a decline by one of the participants
    /// @param _auctionId Auction ID
    /// @param _participants Array of profit sharing participants
    /// @param _percentAmounts Array of participants' profit share %
    function setNewSchemaOfProfitDivisionForAuction(
        uint256 _auctionId,
        address[] _participants,
        uint8[] _percentAmounts
    )
        public
        onlyAuctionOwner(_auctionId)
    {
        // Length of arrays must match
        require(_participants.length == _percentAmounts.length);
        // Apply new profit sharing schedule
        _applyNewSchemaOfProfitDivisionForAuction(_auctionId, _participants, _percentAmounts);
        // Since a change in the profit share for one participant affects all other participants, everyone needs to be notified again
        for (uint256 i = 0; i < _participants.length; i++) {
            // Emit approval notification for all participants
            emit NeedApproveAuctionEvent(_auctionId, _participants[i], _percentAmounts[i]);
        }
    }

    /// @dev Profit sharing participant must approve Auction terms
    /// @param _auctionId Auction id
    function approveAuction(uint256 _auctionId) public onlyAuctionParticipator(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        // Mark approval of Auction terms by the current participant
        auction.participantToApproveMap[msg.sender] = true;
        // Check that all participants approved Auction terms
        bool isAllApproved = true;
        uint8[] memory parts = new uint8[](auction.participants.length);
        for (uint8 i = 0; i < auction.participants.length; i++) {
            isAllApproved = isAllApproved && auction.participantToApproveMap[auction.participants[i]];
            parts[i] = auction.participantToPercentageAmountMap[auction.participants[i]];
        }
        // If all participants approved the terms, pass the Auction terms to the artworks, so that each artwork will contain
        // the terms for the profit sharing
        if (isAllApproved) {
            uint256[] memory tokens = getArtworksAuctionsList(_auctionId);
            for (i = 0; i < tokens.length; i++) {
                _applyProfitShare(tokens[i], auction.participants, parts);
            }
        }
        // Now mark the auction as active for sale
        if (isAllApproved) auction.saleStatus = SaleStatus.NotActive;
        // Emit a notification that the Auction was created
        emit AuctionCreatedEvent(_auctionId);
    }

    /// @dev Function to decline the Auction terms by the profit sharing participant
    /// @param _auctionId Auction ID
    function declineAuctionApprove(uint256 _auctionId) public onlyAuctionParticipator(_auctionId) {
        // Notify the Auction owner that the Auction terms were declined
        emit DeclineApproveAuctionEvent(_auctionId, auctionToOwnerMap[_auctionId], msg.sender);
    }

    /// @dev Function that returns all artworks belonging to the auction
    /// @param _auctionId Auction ID
    function getArtworksAuctionsList(uint256 _auctionId) 
        public 
        view 
        correctAuctionId(_auctionId) 
        returns (uint256[]) 
    {
        return auctionToTokensMap[_auctionId];
    }

    /// @dev Function to delete an Auction
    /// @param _auctionId Auction ID
    function _deleteAuction(uint256 _auctionId) internal {
        uint256[] memory tokens = auctionToTokensMap[_auctionId];
        for (uint256 i = 0; i < tokens.length; i++) {
            // Release all artworks
            if (tokenToSaleTypeMap[tokens[i]] == SaleType.Auction)
                tokenToSaleTypeMap[tokens[i]] = SaleType.None;
            delete tokenToAuctionMap[tokens[i]];
            _unlockAuctionsToken(_auctionId, tokens[i]);
        }
        // Delete an array of tokens from current auction
        delete auctionToTokensMap[_auctionId];
        // Get a aucton owner
        address auctionOwner = auctionToOwnerMap[_auctionId];
        // Delete the auction from the owner
        delete auctionToOwnerMap[_auctionId];
        // Reduce the auction counter for the owner
        ownerToCountAuctionsMap[auctionOwner]--;
        // Mark the auction as finished
        auctions[_auctionId].saleStatus = SaleStatus.Finished;
        // Emit a notification that the auction was deleted
        emit AuctionFinishedEvent(_auctionId);
    }

    /// @dev Apply the new profit sharing schedule to the auction
    /// @param _auctionId Auction ID
    /// @param _participants Array of profit sharing participants
    /// @param _percentAmounts Array of participants' profit share %
    function _applyNewSchemaOfProfitDivisionForAuction(
        uint256 _auctionId,
        address[] _participants,
        uint8[] _percentAmounts
    ) 
        private
    {
        // Delete everything as some participants could have been removed and some new participants added
        Auction storage auction = auctions[_auctionId];
        for (uint8 i = 0; i < auction.participants.length; i++) {
            // Delete profit sharing %
            delete auction.participantToPercentageAmountMap[auction.participants[i]];
            // Delete all approval consents since their values have already changed
            delete auction.participantToApproveMap[auction.participants[i]];
        }
        auction.participants.length = 0;
        // Apply new profit sharing schedule
        bool isSnarkDelivered = false;
        // Fill in the list of profit sharing participants
        for (i = 0; i < _participants.length; i++) {
            // Save the addresses of the profit sharing participants
            auction.participants.push(_participants[i]);
            // Save the profit share % of the participants
            auction.participantToPercentageAmountMap[_participants[i]] = _percentAmounts[i];
            // In the event that the client already receives information about Snark's share
            if (_participants[i] == owner) isSnarkDelivered = true;
        }
        // Enter Snark information, if it was not transmitted and processed above
        if (isSnarkDelivered == false) {
            // Save Snark's address
            auction.participants.push(owner); 
            // Save Snark's revenue share %
            auction.participantToPercentageAmountMap[owner] = platformProfitShare;
        }
        // Issue Snark's approval
        auction.participantToApproveMap[owner] = true;
    }

    /// @dev Lock Token
    /// @param _auctionId Auction Id
    /// @param _tokenId Token Id
    function _lockAuctionsToken(uint256 _auctionId, uint256 _tokenId) private {
        address realOwner = auctionToOwnerMap[_auctionId];
        // move token from realOwner to Snark
        _transfer(realOwner, owner, _tokenId);
    }

    /// @dev Unlock Token
    /// @param _auctionId Auction Id
    /// @param _tokenId Token Id
    function _unlockAuctionsToken(uint256 _auctionId, uint256 _tokenId) private {
        address realOwner = auctionToOwnerMap[_auctionId];
        // move token from Snark to realOwner
        _transfer(owner, realOwner, _tokenId);
    }

    /// WE SHOULD PROBABLY PERFORM THIS STEP ON THE BACKEND TO REDUCE COST
    /// @dev Call the function from the outside in order to: 
    /// launch or end and auction, or lower the price
    // function processingOfAuctions() external {
    //     uint256 currentTimestamp = block.timestamp;
    //     uint256 endDay = 0;
    //     for (uint256 i = 0; i < auctions.length; i++) {
    //         // figure out the end date when the auction finishes 
    //         // start date in timestamp + (duration in days + 1)* 86400 (timestamp in 1 day approximately)
    //         endDay = auctions[i].startingDate + (auctions[i].duration + 1) * 86400;
    //         if (auctions[i].saleStatus == SaleStatus.NotActive) {
    //             // launch those that are ready
    //             if (auctions[i].startingDate <= currentTimestamp &&
    //                 currentTimestamp < endDay) {
    //                 auctions[i].saleStatus == SaleStatus.Active;
    //             }
    //         } else if (auctions[i].saleStatus == SaleStatus.Active) {
    //             // end those that should finish
    //             if (currentTimestamp >= endDay) {
    //                 auctions[i].saleStatus == SaleStatus.Finished;
    //                 // release the auction and all remaining artworks
    //                 _deleteAuction(i);
    //             } else {
    //                 // if we are here, the auction is still active and lower the price, if needed 
    //                 // step = (higher start price  - lower ending price) / duration
    //                 uint256 step = (auctions[i].startingPrice - auctions[i].endingPrice) / auctions[i].duration;
    //                 // figure out auction duration in days
    //                 uint8 auctionLasts = uint8((block.timestamp - auctions[i].startingDate) / 86400);
    //                 // figure out what should be the current price
    //                 uint256 newPrice = uint256(auctions[i].startingPrice - step * auctionLasts);
    //                 if (auctions[i].workingPrice > newPrice) {
    //                     auctions[i].workingPrice = newPrice;
    //                     emit AuctionPriceChanged(i, newPrice);
    //                 }
    //             }
    //         }
    //     }
    // }
}
