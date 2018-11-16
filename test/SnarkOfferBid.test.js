var SnarkOfferBid = artifacts.require("SnarkOfferBid");
var SnarkBase = artifacts.require("SnarkBase");
var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkERC721 = artifacts.require("SnarkERC721");

contract('SnarkOfferBid', async (accounts) => {

    let instance = null;

    before(async () => {
        instance = await SnarkOfferBid.deployed();
        instance_snarkbase = await SnarkBase.deployed();
        instance_erc721 = await SnarkERC721.deployed();
    });

    it("1. get size of the SnarkOfferBid library", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("2. test addOffer and cancelOffer functions", async () => {
        const owner = accounts[0];
        const tokenId = 1;
        const offerId = 1;
        const price = web3.toWei(4, 'ether');

        const tokenHash = web3.sha3("tokenHash");
        const limitedEdition = 1;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7Eni";
        const participants = [
            '0xC04691B99EB731536E35F375ffC85249Ec713597', 
            '0xB94691B99EB731536E35F375ffC85249Ec717233'
        ];
        const profits = [ 20, 80 ];

        let retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 0, "error on step getTokensCountByOwner before addSnark");

        await instance_snarkbase.createProfitShareScheme(owner, participants, profits);

        retval = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 5");

        const profitShareSchemeId = await instance_snarkbase.getProfitShareSchemeIdForOwner(owner, 0);

        await instance_snarkbase.addToken(
            owner,
            tokenHash,
            limitedEdition,
            profitShareFromSecondarySale,
            tokenUrl,
            profitShareSchemeId,
            true,
            true
        );

        retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step getTokensCountByOwner after addSnark");

        ////////////////////        

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        const eventOfferAdded = instance.OfferAdded({ fromBlock: 'latest' });
        eventOfferAdded.watch(function (error, result) {
            if (!error) {
                retOfferId = result.args._offerId.toNumber();
                retOfferOwner = result.args._offerOwner;
                console.log(`event OfferAdded: owner - ${retOfferOwner}, offer Id - ${retOfferId}`);
            }
        });

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        console.log("*************************");
        console.log('Input param of addOffer - Token Id: ', tokenId);
        console.log('Input param of addOffer - Offer Price: ', price);

        await instance.addOffer(tokenId, price, { from: owner });

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 5");

        retval = await instance.getOfferDetail(1);
        console.log("*************************");
        console.log("Offer Detail:");
        console.log("Offer Id: ", retval[0].toNumber());
        assert.equal(retval[0].toNumber(), offerId, "wrong OfferId after addOffer");
        console.log("Offer Price: ", retval[1].toNumber());
        assert.equal(retval[1].toNumber(), price, "wrong Offer price after addOffer");
        console.log("Offer Status: ", retval[2].toNumber());
        assert.equal(retval[2].toNumber(), 2, "wrong Offer status after addOffer");
        console.log("Token Id: ", retval[3].toNumber());
        console.log("Token Owner: ", retval[4]);
        assert.equal(retval[4].toUpperCase(), owner.toUpperCase(), "wrong Offer status after addOffer");
        console.log("*************************");

        try { await instance.addOffer(tokenId, price + 200); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Token should not be involved in sales');
        }

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 1, "error on step 6");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 2, "error on step 7");

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 1, "error on step 8");

        retval = await instance.getOwnerOfferByIndex(owner, 0);
        assert.equal(retval.toNumber(), 1, "error on step 9");

        const eventOfferDeleted = instance.OfferDeleted({ fromBlock: 'latest' });
        eventOfferDeleted.watch(function (error, result) {
            if (!error) {
                retOfferId = result.args._offerId.toNumber();
                console.log(`event OfferDeleted: offer Id - ${retOfferId}`);
            }
        });

        await instance.cancelOffer(1);

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 10");
    });

    it("3. test buyOffer function", async () => {
        const owner = accounts[0];
        const buyer = accounts[1];
        const bidOwner = accounts[2];
        const tokenId = 1;
        const offerId = 2;
        const price = web3.toWei(1, 'ether');
        const bidPrice = web3.toWei(0.5, 'ether');

        const platformProfitShare = await instance_snarkbase.getPlatformProfitShare();
        
        const profit = price *  platformProfitShare / 100;
        
        console.log(`Price: ${price}`);
        console.log(`getPlatformProfitShare = ${platformProfitShare}`);
        console.log(`Profit 5%: ${profit}`);

        let retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 1, "error on step 2");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 0, "error on step 4");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 5");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 6");

        await instance.addOffer(tokenId, price);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`Storage Ether Balance befor addBid: ${ retval.toNumber() } `);

        await instance.addBid(tokenId, {from: bidOwner, value: bidPrice});

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`Storage Ether Balance after addBid: ${ retval.toNumber() } `);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 5");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 6");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 7");

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 2, "error on step 8");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 2, "error on step 9");
        
        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 1, "error on step 10");

        retval = await instance_snarkbase.getWithdrawBalance(owner);
        assert.equal(retval.toNumber(), 0, "error on step 11");

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, owner, "error on step 12");

        await instance.buyOffer(offerId, { from: buyer, value: web3.toWei(2, 'ether') });

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 13");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 14");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 15");

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, buyer, "error on step 16");

        retval = await instance_snarkbase.getWithdrawBalance(owner);
        assert.equal(retval.toNumber(), price - profit, "error on step 17");

        const withdraw_balance_before = retval.toNumber();
        const wallet_balance_before = web3.eth.getBalance(owner).toNumber();

        console.log(`Balance on wallet of owner before withdraw: ${ wallet_balance_before }`);
        console.log(`Withdraw balance of owner before withdraw: ${ withdraw_balance_before }`);

        let gasNeeded = await instance_snarkbase.withdrawFunds.estimateGas();
        console.log('Estimate Gas: ', gasNeeded);

        // let gasPrice = 2000000000;//await web3.eth.getGasPrice();
        // console.log('Gas Price: ', gasPrice);

        // let gasInWei = gasNeeded * gasPrice;
        // console.log('Gas in Wei: ', gasInWei);

        await instance_snarkbase.withdrawFunds({ from: owner });

        const wallet_balance_after = web3.eth.getBalance(owner).toNumber();
        console.log(`Balance on wallet of owner after withdraw: ${ wallet_balance_after }`);
        // assert.notEqual(wallet_balance_after, wallet_balance_before, "Balance of wallet has to be different");
        // alert.equal(wallet_balance_after, withdraw_balance_before + wallet_balance_before - gasInWei);

        retval = await instance_snarkbase.getWithdrawBalance(owner);
        console.log(`Withdraw balance of after after withdraw: ${ retval.toNumber() }`);
    });

    it("4. test addBid and deleteBid functions", async () => {
        const tokenOwner = accounts[1];
        const bidOwner = accounts[2];
        const bidOwner2 = accounts[3];
        const tokenId = 1;
        const bidPrice = web3.toWei(0.5, 'ether');
        const highestPrice = web3.toWei(0.6, 'ether');
        const sumPrice = web3.toWei(0.5 + 0.6, 'ether');
        const platformProfitShare = await instance_snarkbase.getPlatformProfitShare();
        
        const profit = highestPrice *  platformProfitShare / 100;

        let retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 1");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 2");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 3_1");
        retval = await instance.getNumberBidsOfOwner(bidOwner2);
        assert.equal(retval.toNumber(), 0, "error on step 3_2");

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, tokenOwner, "error on step 4");

        const event = instance.BidAdded({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                retBidId = result.args._bidId.toNumber();
                retBidOwner = result.args._bidder;
                console.log(`event BidAdded: owner - ${retBidOwner}, bid Id - ${retBidId}`);
            }
        });

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), web3.toWei(1, 'ether'), "error on step 5");

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 6");

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), bidPrice, "error on step 7");

        retval = await instance_snarkbase.getTokensCount();
        assert.equal(retval.toNumber(), 1, "error on step 8");

        try { await instance.addBid(tokenId, {from: bidOwner, value: bidPrice}); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert You already have a bid for this token. Please cancel it before add a new one.');
        }

        try { await instance.addBid(tokenId, {from: bidOwner2, value: bidPrice}); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Price of new bid has to be bigger than previous one');
        }
        
        await instance.addBid(tokenId, {from: bidOwner2, value: highestPrice});
        
        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), sumPrice, "error on step 9");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 2, "error on step 10");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 2, "error on step 12");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 11");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), web3.toWei(1, 'ether'), "error on step 13");

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner2);
        assert.equal(retval.toNumber(), 0, "error on step 14");

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), sumPrice, "error on step 15");

        await instance.acceptBid(2, { from: tokenOwner });

        retval = await instance.getBidIdMaxPrice(tokenId);
        assert.equal(retval[0], 0, "error: getBidIdMaxPrice returns wrong bidId");
        assert.equal(retval[1], 0, "error: getBidIdMaxPrice returns wrong maxPrice");

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, bidOwner2, "error on step 16");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 2, "error on step 17");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 18");

        let balanceOfTokenOwner = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        balanceOfTokenOwner = balanceOfTokenOwner.toNumber();
        assert.equal(balanceOfTokenOwner, web3.toDecimal(web3.toWei(1,'ether')) + web3.toDecimal(highestPrice - profit), "error on step 19");
        console.log(`tokenOwner's balance before addBid: ${ balanceOfTokenOwner }`);

        let balanceOfBidOwner = await instance_snarkbase.getWithdrawBalance(bidOwner2);
        balanceOfBidOwner = balanceOfBidOwner.toNumber();
        assert.equal(balanceOfBidOwner, 0, "error on step 20");
        console.log(`bidOwner's balance before addBid: ${ balanceOfBidOwner }`);
        
        balanceOfContract = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        balanceOfContract = balanceOfContract.toNumber();
        assert.equal(balanceOfContract, 0, "error on step 21");
        console.log(`contract's balance before addBid: ${ balanceOfContract }`);

        await instance.addBid(tokenId, {from: tokenOwner, value: web3.toWei(0.4, 'ether')});

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log(`tokenOwner's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        console.log(`bidOwner's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`contract's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 3, "error on step 22");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 23");

        retval = await instance.getNumberBidsOfOwner(tokenOwner);
        assert.equal(retval.toNumber(), 1, "error on step 24");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 25");

        try { await instance.cancelBid(1, { from: tokenOwner }); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert it\'s not a bid owner');
        }

        await instance.cancelBid(3, { from: tokenOwner });

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log(`tokenOwner's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        console.log(`bidOwner's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`contract's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 3, "error on step 26");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 27");

        retval = await instance.getNumberBidsOfOwner(tokenOwner);
        assert.equal(retval.toNumber(), 0, "error on step 28");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 29");

    });

    it("5. test issue #31 on github", async () => {
        // ********************************************
        // Scenario
        // ********************************************
        // 1. Create an offer.
        // 2. Create two bids to this offer.
        // 3. Cancel an offer.
        // ********************************************
        // Result
        // ********************************************
        // It will fail with error message:
        // Error: VM Exception while processing transaction: revert bid is already excluded from the list
        // ********************************************

        const owner = accounts[0];
        const bidder1 = accounts[1];
        const bidder2 = accounts[2];
        const costOfBid1 = web3.toWei(0.1, "Ether");
        const costOfBid2 = web3.toWei(0.2, "Ether");
        const costOfBid3 = web3.toWei(0.22, "Ether");
        const costOfBid4 = web3.toWei(0.24, "Ether");

        let retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 3");

        const profitShareSchemeId = await instance_snarkbase.getProfitShareSchemeIdForOwner(owner, 0);

        // 1. Create token
        await instance_snarkbase.addToken(
            owner, 
            web3.sha3("QmTa69PvuAn65brzc4UodfdgvfXDey2sf7a1ivNgnkCPwN"),
            1, 0, "http://ipfs.io/ipfs/QmTa69PvuAn65brzc4UodfdgvfXDey2sf7a1ivNgnkCPwN",
            profitShareSchemeId, true, true, { from: owner }
        );

        let tokenId = await instance_snarkbase.getTokensCount();
        tokenId = tokenId.toNumber();

        retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 4");

        retval = await instance_snarkbase.getTokenListForOwner(owner);
        assert.equal(retval.length, 1, "error on ster 5");
        assert.equal(retval[0].toNumber(), tokenId, "error on step 6");

        // 2. Create offer for token
        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 7");

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 8");

        await instance.addOffer(tokenId, web3.toWei(0.3, "Ether"), { from: owner });

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 10");

        // 3. Create 4 bids to this token
        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 3, "error on step 11");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 12");

        retval = await instance.getNumberBidsOfOwner(bidder1);
        assert.equal(retval.toNumber(), 0, "error on step 13");

        retval = await instance.getNumberBidsOfOwner(bidder2);
        assert.equal(retval.toNumber(), 0, "error on step 14");

        await instance.addBid(tokenId, {from: bidder1, value: costOfBid1 });
        retval = await instance.getTotalNumberOfBids();
        const bid1 = retval.toNumber();

        await instance.addBid(tokenId, {from: bidder2, value: costOfBid2 });
        retval = await instance.getTotalNumberOfBids();
        const bid2 = retval.toNumber();

        try { await instance.addBid(tokenId, {from: bidder1, value: costOfBid3 }); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert You already have a bid for this token. Please cancel it before add a new one.');
        }
        
        try { await instance.addBid(tokenId, {from: bidder2, value: costOfBid4 }); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert You already have a bid for this token. Please cancel it before add a new one.');
        }
        
        retval = await instance.getNumberBidsOfOwner(bidder1);
        assert.equal(retval.toNumber(), 1, "error on step 15");

        retval = await instance.getNumberBidsOfOwner(bidder2);
        assert.equal(retval.toNumber(), 1, "error on step 16");
        
        // get list of bids for token and print all of them
        retval = await instance.getListOfBidsForToken(tokenId);
        assert.lengthOf(retval, 2, "error on ster 17");
        assert.equal(retval[0], bid1, "error on step 18");
        assert.equal(retval[1], bid2, "error on step 19");

        retval = await instance.getBidIdMaxPrice(tokenId);
        assert.equal(retval[0], bid2, "error in step 25");
        assert.equal(retval[1], costOfBid2, "error in step 26");

        retval = await instance_snarkbase.getWithdrawBalance(bidder1);
        let balanceOfBidder1 = retval.toNumber();
        console.log(`Balance of bidder 1 before cancel bid: ${ balanceOfBidder1 }`)
        
        retval = await instance_snarkbase.getWithdrawBalance(bidder2);
        let balanceOfBidder2 = retval.toNumber();
        console.log(`Balance of bidder 2 before cancel bid: ${ balanceOfBidder2 }`)
        
        // cancel bid with wrong bid id
        try { await instance.cancelBid(bid2 + 2, { from: bidder1 }); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Bid id is wrong');
        }

        // cancel bid on befalf of other's address
        try { await instance.cancelBid(bid2, { from: bidder2 }); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert it\'s not a bid owner');
        }

        // cancel bid and check id maxBidId changes and check balance of bid owners
        await instance.cancelBid(bid1, { from: bidder1 });

        retval = await instance.getNumberBidsOfOwner(bidder1);
        assert.equal(retval.toNumber(), 0, "error on step 27");

        retval = await instance_snarkbase.getWithdrawBalance(bidder1);
        let sum = parseInt(balanceOfBidder1) + parseInt(costOfBid1);
        assert.equal(retval.toNumber(), sum, "error on step 28");
        balanceOfBidder1 = retval.toNumber();
        console.log(`Balance of bidder 1 after cancel bid: ${ balanceOfBidder1 }`)

        retval = await instance.getBidIdMaxPrice(tokenId);
        assert.equal(retval[0], 0, "error in step 29");
        assert.equal(retval[1], 0, "error in step 30"); 
        
        retval = await instance_snarkbase.getWithdrawBalance(bidder2);
        sum = parseInt(balanceOfBidder2) + parseInt(costOfBid2);
        assert.equal(retval.toNumber(), sum, "error on step 34");
        balanceOfBidder2 = retval.toNumber();
        console.log(`Balance of bidder 2 after cancel bid: ${ balanceOfBidder2 }`)

        // 4. Cancel the offer
        retval = await instance_snarkbase.getWithdrawBalance(bidder1);
        balanceOfBidder1 = retval.toNumber();
        console.log(`Balance of bidder 1: ${ balanceOfBidder1 }`)
        
        retval = await instance_snarkbase.getWithdrawBalance(bidder2);
        balanceOfBidder2 = retval.toNumber();
        console.log(`Balance of bidder 2: ${ balanceOfBidder2 }`)
    });

    it("6. test issue #25 on github", async () => {
        const owner = accounts[0];
        const bidder = accounts[1];
        const bidCostRight = web3.toWei(0.2, "Ether");
        const bidCostWrong = web3.toWei(0.8, "Ether");
        const offerCost = web3.toWei(0.3, "Ether");

        let retval = await instance.getTotalNumberOfOffers();
        const offerId = retval.toNumber();

        let tokenId = await instance_snarkbase.getTokensCount();
        tokenId = tokenId.toNumber();

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        // добавляем новый бид. читаем количество = id bid 
        try {
            await instance.addBid(tokenId, {from: bidder, value: bidCostWrong });
        } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Bid amount must be less than the offer price');
        }

        await instance.addBid(tokenId, {from: bidder, value: bidCostRight });

        retval = await instance.getTotalNumberOfBids();
        const bidId = retval.toNumber();

        // проверяем чтобы он был max Bid и Price
        retval = await instance.getBidIdMaxPrice(tokenId);
        assert.equal(retval[0], bidId, "error on step 2");
        assert.equal(retval[1], bidCostRight, "error on step 3");

        // check if it's possible to call freeTransfer while exist Offer
        // issue #19
        const tokenOwner = await instance_snarkbase.getOwnerOfToken(tokenId);
        try {
            await instance_erc721.freeTransfer(tokenOwner, accounts[5], tokenId);
        } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert');
        }

        // после cancelOffer бид должен удалиться и maxBid и Price должны обнулиться
        await instance.cancelOffer(offerId);

        retval = await instance.getNumberBidsOfOwner(bidder);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        retval = await instance.getBidIdMaxPrice(tokenId);
        assert.equal(retval[0], 0, "error on step 5");
        assert.equal(retval[1], 0, "error on step 6");
    });

    it("7. test issue #35 on github", async () => {
        // ********************************************
        // Scenario
        // ********************************************
        // 1. Create a bid without offer for a token without offer for 1.5 ETH.
        // 2. Accept this bid.
        // 3. Previous owner creates a bid for same token for 1 ETH. ( after the bid was accepted ).
        // ********************************************
        // Result
        // ********************************************
        // It gets rejected with error message: revert Price of new bid has to be bigger than previous one.
        // ********************************************

        const bidder = accounts[1];
        const bidCost = web3.toWei(1.5, "Ether");
        const bidCost2 = web3.toWei(1, "Ether");

        let tokenId = await instance_snarkbase.getTokensCount();
        tokenId = tokenId.toNumber();

        const owner = await instance_snarkbase.getOwnerOfToken(tokenId);

        let retval = await instance.getOfferByToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        await instance.addBid(tokenId, { from: bidder, value: bidCost });
        const bidId = await instance.getTotalNumberOfBids();

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 3");

        await instance.acceptBid(bidId, { from: owner });

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, bidder, "error on step 4");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 5");

        await instance.addBid(tokenId, { from: owner, value: bidCost2 });
        // const bidId2 = await instance.getTotalNumberOfBids();

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 6");

    });
});
