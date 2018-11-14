var SnarkOfferBid = artifacts.require("SnarkOfferBid");
var SnarkBase = artifacts.require("SnarkBase");
var SnarkStorage = artifacts.require("SnarkStorage");

contract('SnarkOfferBid', async (accounts) => {

    let instance = null;

    before(async () => {
        instance = await SnarkOfferBid.deployed();
        instance_snarkbase = await SnarkBase.deployed();
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

        await instance.addBid(tokenId, {from: bidOwner, value: bidPrice});

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
        assert.equal(retval.toNumber(), 0, "error on step 14");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 15");

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

        let gasPrice = 2000000000;//await web3.eth.getGasPrice();
        console.log('Gas Price: ', gasPrice);

        let gasInWei = gasNeeded * gasPrice;
        console.log('Gas in Wei: ', gasInWei);

        await instance_snarkbase.withdrawFunds({ from: owner });

        const wallet_balance_after = web3.eth.getBalance(owner).toNumber();
        console.log(`Balance on wallet of owner after withdraw: ${ wallet_balance_after }`);
        assert.notEqual(wallet_balance_after, wallet_balance_before, "Balance of wallet has to be different");
        // alert.equal(wallet_balance_after, withdraw_balance_before + wallet_balance_before - gasInWei);

        retval = await instance_snarkbase.getWithdrawBalance(owner);
        console.log(`Withdraw balance of after after withdraw: ${ retval.toNumber() }`);
    });

    it("4. test addBid and deleteBid functions", async () => {
        const tokenOwner = accounts[1];
        const bidOwner = accounts[2];
        const tokenId = 1;
        const bidPrice = web3.toWei(0.5, 'ether');
        const LowestPrice = web3.toWei(0.4, 'ether');
        const highestPrice = web3.toWei(0.6, 'ether');
        const sumPrice = web3.toWei(0.5 + 0.6, 'ether');
        const platformProfitShare = await instance_snarkbase.getPlatformProfitShare();
        
        const profit = highestPrice *  platformProfitShare / 100;

        let retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 1");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 3");

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
        assert.equal(retval.toNumber(), 0, "error on step 5");

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        assert.equal(retval.toNumber(), bidPrice, "error on step 6");

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), 0, "error on step 7");

        retval = await instance_snarkbase.getTokensCount();
        assert.equal(retval.toNumber(), 1, "error on step 8");

        await instance.addBid(tokenId, {from: bidOwner, value: bidPrice});

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), bidPrice, "error on step 9");

        try { await instance.addBid(tokenId, {from: bidOwner, value: LowestPrice}); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Price of new bid has to be bigger than previous one');
        }

        await instance.addBid(tokenId, {from: bidOwner, value: highestPrice});

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 3, "error on step 10");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 2, "error on step 12");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 2, "error on step 11");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), web3.toWei(0, 'ether'), "error on step 13");

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        assert.equal(retval.toNumber(), bidPrice, "error on step 14");

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), sumPrice, "error on step 15");

        await instance.acceptBid(3, { from: tokenOwner });

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, bidOwner, "error on step 16");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 3, "error on step 17");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 18");

        let balanceOfTokenOwner = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        balanceOfTokenOwner = balanceOfTokenOwner.toNumber();
        assert.equal(balanceOfTokenOwner, highestPrice - profit, "error on step 19");
        console.log(`tokenOwner's balance before addBid: ${ balanceOfTokenOwner }`);

        let balanceOfBidOwner = await instance_snarkbase.getWithdrawBalance(bidOwner);
        balanceOfBidOwner = balanceOfBidOwner.toNumber();
        assert.equal(balanceOfBidOwner, bidPrice * 2, "error on step 20");
        console.log(`bidOwner's balance before addBid: ${ balanceOfBidOwner }`);
        
        balanceOfContract = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        balanceOfContract = balanceOfContract.toNumber();
        assert.equal(balanceOfContract, 0, "error on step 21");
        console.log(`contract's balance before addBid: ${ balanceOfContract }`);

        await instance.addBid(tokenId, {from: tokenOwner, value: web3.toWei(0.67, 'ether')});

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log(`tokenOwner's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        console.log(`bidOwner's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`contract's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 4, "error on step 22");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 23");

        retval = await instance.getNumberBidsOfOwner(tokenOwner);
        assert.equal(retval.toNumber(), 1, "error on step 24");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 25");

        try { await instance.cancelBid(1, { from: tokenOwner }); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert it\'s not a bid owner');
        }

        await instance.cancelBid(4, { from: tokenOwner });

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log(`tokenOwner's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        console.log(`bidOwner's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`contract's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 4, "error on step 26");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 27");

        retval = await instance.getNumberBidsOfOwner(tokenOwner);
        assert.equal(retval.toNumber(), 0, "error on step 28");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 29");

    });

    it("5. test issue #31 on github", async () => {
        console.log("********************************************");
        console.log("Scenario:");
        console.log("********************************************");
        console.log("1. Create an offer.");
        console.log("2. Create two bids to this offer.");
        console.log("3. Cancel an offer.");
        console.log("********************************************");
        console.log("Wrong behaviour:");
        console.log("********************************************");
        console.log("It will fail with error message:");
        console.log("Error: VM Exception while processing transaction: revert bid is already excluded from the list");
        console.log("********************************************");

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

        retval = await instance.getTotalNumberOfOffers();
        const offerId = retval.toNumber();

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 10");

        // 3. Create 4 bids to this token
        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 4, "error on step 11");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 12");

        retval = await instance.getNumberBidsOfOwner(bidder1);
        assert.equal(retval.toNumber(), 0, "error on step 13");

        retval = await instance.getNumberBidsOfOwner(bidder2);
        assert.equal(retval.toNumber(), 0, "error on step 14");

        await instance.addBid(tokenId, {from: bidder1, value: costOfBid1 });
        // retval = await instance.getTotalNumberOfBids();

        await instance.addBid(tokenId, {from: bidder2, value: costOfBid2 });
        // retval = await instance.getTotalNumberOfBids();

        await instance.addBid(tokenId, {from: bidder1, value: costOfBid3 });
        // retval = await instance.getTotalNumberOfBids();
        
        await instance.addBid(tokenId, {from: bidder2, value: costOfBid4 });
        // retval = await instance.getTotalNumberOfBids();

        retval = await instance.getNumberBidsOfOwner(bidder1);
        assert.equal(retval.toNumber(), 2, "error on step 15");

        retval = await instance.getNumberBidsOfOwner(bidder2);
        assert.equal(retval.toNumber(), 2, "error on step 16");

        // get list of bids for token and print all of them
        retval = await instance.getListOfBidsForToken(tokenId);
        console.log(retval);

        // 4. Cancel the offer
        retval = await instance_snarkbase.getWithdrawBalance(bidder1);
        const balanceOfBidder1 = retval.toNumber();

        retval = await instance_snarkbase.getWithdrawBalance(bidder2);
        const balanceOfBidder2 = retval.toNumber();

        await instance.cancelOffer(offerId);

        retval = await instance_snarkbase.getWithdrawBalance(bidder1);
        const balanceOfBidder1_afterCancelOffer = retval.toNumber();
        assert.notEqual(balanceOfBidder1_afterCancelOffer, balanceOfBidder1, "error on step 17")
        
        retval = await instance_snarkbase.getWithdrawBalance(bidder2);
        const balanceOfBidder2_afterCancelOffer = retval.toNumber();
        assert.notEqual(balanceOfBidder2_afterCancelOffer, balanceOfBidder2, "error on step 18")

        retval = await instance.getNumberBidsOfOwner(bidder1);
        assert.equal(retval.toNumber(), 0, "error on step 19");

        retval = await instance.getNumberBidsOfOwner(bidder2);
        assert.equal(retval.toNumber(), 0, "error on step 20");

        retval = await instance.getBidIdMaxPrice(tokenId);
        console.log("Max Bid and Price: ", retval);
        assert.equal(retval[0], 0, "error on step 21");
        assert.equal(retval[1], 0, "error on step 22");
    });

});
