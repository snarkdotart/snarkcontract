var SnarkOfferBid = artifacts.require("SnarkOfferBid");
var SnarkBase = artifacts.require("SnarkBase");
var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkERC721 = artifacts.require("SnarkERC721");

const BigNumber = require('bignumber.js');

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
        const price = web3.utils.toWei('4', 'ether');

        const tokenHash = web3.utils.sha3("tokenHash");
        const limitedEdition = 1;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7Eni";
        const participants = [
            accounts[0], 
            accounts[2]
        ];
        const profits = [ 95, 5 ];

        let retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 0, "error on step getTokensCountByOwner before addSnark");

        await instance_snarkbase.createProfitShareScheme(owner, participants, profits);

        retval = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 5");

        const profitShareSchemeId = await instance_snarkbase.getProfitShareSchemeIdForOwner(owner, 0);

        await instance_snarkbase.addToken(
            owner,
            tokenHash,
            tokenUrl,
            'ipfs://decorator.io',
            'bla-blaa-blaaa',
            [
                limitedEdition,
                profitShareFromSecondarySale,
                profitShareSchemeId
            ],
            [true, true]
        );

        retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step getTokensCountByOwner after addSnark");

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        await instance.addOffer(tokenId, price, { from: owner });

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 5");

        retval = await instance.getOfferDetail(1);
        assert.equal(retval[0].toNumber(), offerId, "wrong OfferId after addOffer");        
        assert.equal(retval[1], price, "wrong Offer price after addOffer");
        assert.equal(retval[2].toNumber(), 2, "wrong Offer status after addOffer");
        assert.equal(retval[4].toUpperCase(), owner.toUpperCase(), "wrong Offer status after addOffer");

        try { await instance.addOffer(tokenId, price + 200); } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert Token should not be involved in sales -- Reason given: Token should not be involved in sales.');
        }

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 1, "error on step 6");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 2, "error on step 7");

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 1, "error on step 8");

        retval = await instance.getOwnerOfferByIndex(owner, 0);
        assert.equal(retval.toNumber(), 1, "error on step 9");

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
        const price = web3.utils.toWei('1', 'ether');
        const bidPrice = web3.utils.toWei('0.5', 'ether');

        const platformProfitShare = await instance_snarkbase.getPlatformProfitShare();
        
        const profit = new BigNumber(price).multipliedBy(platformProfitShare).dividedBy(100);
        const distributionAmount = new BigNumber(price).minus(profit);
        
        let retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 1, "error on step 2");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 0, "error on step 3");        

        retval = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 4");

        retval = await instance_snarkbase.getProfitShareSchemeIdForOwner(owner, 0);
        const schemeId = retval.toNumber();
        assert.equal(schemeId, 1, "error on step 5");

        retval = await instance_snarkbase.getNumberOfParticipantsForProfitShareScheme(schemeId);
        assert.equal(retval.toNumber(), 2, "error on step 6");

        retval = await instance_snarkbase.getParticipantOfProfitShareScheme(schemeId, 0);
        const amountForArtist =  distributionAmount.multipliedBy(retval[1]).dividedBy(100);

        retval = await instance_snarkbase.getParticipantOfProfitShareScheme(schemeId, 1);
        const snarkAddress = retval[0];

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 0, "error on step 7");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 8");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 9");

        await instance.addOffer(tokenId, price);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        const storageBalance = retval.toNumber();

        await instance.addBid(tokenId, {from: bidOwner, value: bidPrice});

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(new BigNumber(retval).toNumber(), new BigNumber(storageBalance).plus(bidPrice).toNumber(), "error on Storage balance");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 10");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 11");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 12");

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 2, "error on step 13");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 2, "error on step 14");
        
        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 1, "error on step 15");

        retval = await instance_snarkbase.getWithdrawBalance(owner);
        assert.equal(retval.toNumber(), 0, "error on step 16");

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, owner, "error on step 17");

        const ownerBalanceBeforeBuying = await web3.eth.getBalance(owner);
        const tokenDetail = await instance_snarkbase.getTokenDetail(tokenId);
        const numberParticipants = await instance_snarkbase.getNumberOfParticipantsForProfitShareScheme(tokenDetail.profitShareSchemeId);
        const balanceOfParticipantsBeforeTransfer = [];
        for (let i = 0; i < numberParticipants; i++) {
            const participant = await instance_snarkbase.getParticipantOfProfitShareScheme(tokenDetail.profitShareSchemeId, i);
            retval = await web3.eth.getBalance(participant[0]);
            balanceOfParticipantsBeforeTransfer.push(retval);
        }

        await instance.buyOffer([offerId], { from: buyer, value: web3.utils.toWei('2', 'ether') });

        const ownerBalanceAfterBuying = await web3.eth.getBalance(owner);
        assert.equal(ownerBalanceAfterBuying, new BigNumber(ownerBalanceBeforeBuying).plus(amountForArtist), "Balance of owner isn't correct");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 18");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 19");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 20");

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, buyer, "error on step 21");

        retval = await instance_snarkbase.getWithdrawBalance(owner);
        assert.equal(retval.toNumber(), 0, "error on step 22");

        retval = await instance_snarkbase.getWithdrawBalance(snarkAddress);
        assert.equal(retval.toNumber(), 0, "error on step 23");
    });

    it("4. test addBid and deleteBid functions", async () => {
        const tokenOwner = accounts[1];
        const bidOwner = accounts[2];
        const bidOwner2 = accounts[3];
        const tokenId = 1;
        const bidPrice = web3.utils.toWei('0.5', 'ether');
        const highestPrice = web3.utils.toWei('0.6', 'ether');
        const sumPrice = web3.utils.toWei(String(0.5 + 0.6), 'ether');
        
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

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), 0, "error on step 5");

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 6");

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(new BigNumber(retval).toNumber(), new BigNumber(bidPrice).toNumber(), "error on step 7");

        retval = await instance_snarkbase.getTokensCount();
        assert.equal(retval.toNumber(), 1, "error on step 8");

        try { await instance.addBid(tokenId, {from: bidOwner, value: bidPrice}); } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert You already have a bid for this token. Please cancel it before add a new one. -- Reason given: You already have a bid for this token. Please cancel it before add a new one..');
        }

        try { await instance.addBid(tokenId, {from: bidOwner2, value: bidPrice}); } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert Price of new bid has to be bigger than previous one -- Reason given: Price of new bid has to be bigger than previous one.');
        }
        
        await instance.addBid(tokenId, {from: bidOwner2, value: highestPrice});
        
        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(new BigNumber(retval).toNumber(), sumPrice, "error on step 9");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 2, "error on step 10");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 2, "error on step 12");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 11");

        let tokenDetail = await instance_snarkbase.getTokenDetail(tokenId);
        const snarkwalletandprofit = await instance_snarkbase.getSnarkWalletAddressAndProfit();
        balanceOfSnarkWalletBeforeBidAccept = await web3.eth.getBalance(snarkwalletandprofit.snarkWalletAddr);

        balanceOfTokenOwnerWalletBeforeBidAccept = await web3.eth.getBalance(tokenOwner);

        const numberParticipants = await instance_snarkbase.getNumberOfParticipantsForProfitShareScheme(tokenDetail.profitShareSchemeId);
        const balanceOfParticipantsBeforeTransfer = [];
        for (let i = 0; i < numberParticipants; i++) {
            const participant = await instance_snarkbase.getParticipantOfProfitShareScheme(tokenDetail.profitShareSchemeId, i);
            retval = await web3.eth.getBalance(participant[0]);
            balanceOfParticipantsBeforeTransfer.push(retval);
        }

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(new BigNumber(retval).toNumber(), sumPrice, "error on step 15");

        await instance.acceptBid(2, { from: tokenOwner });

        tokenDetail = await instance_snarkbase.getTokenDetail(tokenId);
        assert.equal(tokenDetail.lastPrice, highestPrice, "error: last price doen't match with highest price");

        const platform_profit = new BigNumber(highestPrice).multipliedBy(snarkwalletandprofit.platformProfit).dividedBy(100);

        balanceOfSnarkWalletAfterBidAccept = await web3.eth.getBalance(snarkwalletandprofit.snarkWalletAddr);
        assert.equal(balanceOfSnarkWalletAfterBidAccept, new BigNumber(balanceOfSnarkWalletBeforeBidAccept).plus(platform_profit), "error: snark wallet doen't match");

        balanceOfTokenOwnerWalletAfterBidAccept = await web3.eth.getBalance(tokenOwner);

        for (let i = 0; i < numberParticipants; i++) {
            const participant = await instance_snarkbase.getParticipantOfProfitShareScheme(tokenDetail.profitShareSchemeId, i);
            retval = await web3.eth.getBalance(participant[0]);
            if (i == 1) {
                assert.equal(new BigNumber(retval).toNumber(), new BigNumber(balanceOfParticipantsBeforeTransfer[i]).plus(web3.utils.toWei('0.5', 'ether')).toNumber(), `balance of participant ${ i + 1  } isn't correct`);
            } else {
                assert.equal(new BigNumber(retval).toNumber(), new BigNumber(balanceOfParticipantsBeforeTransfer[i]).toNumber(), `balance of participant ${ i + 1  } isn't correct`);
            }
        }

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

        assert.equal(balanceOfTokenOwner, 0, "error on step 19");

        let balanceOfBidOwner = await instance_snarkbase.getWithdrawBalance(bidOwner2);
        balanceOfBidOwner = balanceOfBidOwner.toNumber();
        assert.equal(balanceOfBidOwner, 0, "error on step 20");
        
        balanceOfContract = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        balanceOfContract = balanceOfContract.toNumber();
        assert.equal(balanceOfContract, 0, "error on step 21");

        await instance.addBid(tokenId, {from: tokenOwner, value: web3.utils.toWei('0.4', 'ether')});

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 3, "error on step 22");
        
        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 23");

        retval = await instance.getNumberBidsOfOwner(tokenOwner);
        assert.equal(retval.toNumber(), 1, "error on step 24");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 25");

        try { await instance.cancelBid(1, { from: tokenOwner }); } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert it\'s not a bid owner -- Reason given: it\'s not a bid owner.');
        }

        await instance.cancelBid(3, { from: tokenOwner });

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
        const costOfBid1 = web3.utils.toWei('0.1', "Ether");
        const costOfBid2 = web3.utils.toWei('0.2', "Ether");
        const costOfBid3 = web3.utils.toWei('0.22', "Ether");
        const costOfBid4 = web3.utils.toWei('0.24', "Ether");

        let retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 3");

        const profitShareSchemeId = await instance_snarkbase.getProfitShareSchemeIdForOwner(owner, 0);

        await instance_snarkbase.addToken(
            owner, 
            web3.utils.sha3("QmTa69PvuAn65brzc4UodfdgvfXDey2sf7a1ivNgnkCPwN"),
            "http://ipfs.io/ipfs/QmTa69PvuAn65brzc4UodfdgvfXDey2sf7a1ivNgnkCPwN",
            'ipfs://decorator.io',
            'bla-blaa-blaaa',
            [1, 0, profitShareSchemeId], [true, true], { from: owner }
        );

        let tokenId = await instance_snarkbase.getTokensCount();
        tokenId = tokenId.toNumber();

        retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 4");

        retval = await instance_snarkbase.getTokenListForOwner(owner);
        assert.equal(retval.length, 1, "error on ster 5");
        assert.equal(retval[0].toNumber(), tokenId, "error on step 6");

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 7");

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 8");

        await instance.addOffer(tokenId, web3.utils.toWei('0.3', "Ether"), { from: owner });

        retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 10");

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
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert You already have a bid for this token. Please cancel it before add a new one. -- Reason given: You already have a bid for this token. Please cancel it before add a new one..');
        }
        
        try { await instance.addBid(tokenId, {from: bidder2, value: costOfBid4 }); } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert You already have a bid for this token. Please cancel it before add a new one. -- Reason given: You already have a bid for this token. Please cancel it before add a new one..');
        }
        
        retval = await instance.getNumberBidsOfOwner(bidder1);
        assert.equal(retval.toNumber(), 1, "error on step 15");

        retval = await instance.getNumberBidsOfOwner(bidder2);
        assert.equal(retval.toNumber(), 1, "error on step 16");
        
        retval = await instance.getListOfBidsForToken(tokenId);
        assert.lengthOf(retval, 2, "error on ster 17");
        assert.equal(retval[0], bid1, "error on step 18");
        assert.equal(retval[1], bid2, "error on step 19");

        retval = await instance.getBidIdMaxPrice(tokenId);
        assert.equal(retval[0], bid2, "error in step 25");
        assert.equal(retval[1], costOfBid2, "error in step 26");
        
        try { await instance.cancelBid(bid2 + 2, { from: bidder1 }); } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert Bid id is wrong -- Reason given: Bid id is wrong.');
        }

        try { await instance.cancelBid(bid2, { from: bidder2 }); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert it\'s not a bid owner');
        }

        await instance.cancelBid(bid1, { from: bidder1 });

        retval = await instance.getNumberBidsOfOwner(bidder1);
        assert.equal(retval.toNumber(), 0, "error on step 27");

    });

    it("6. test issue #25 on github", async () => {
        const bidder = accounts[1];
        const bidCostRight = web3.utils.toWei('0.2', "Ether");
        const bidCostWrong = web3.utils.toWei('0.8', "Ether");

        let retval = await instance.getTotalNumberOfOffers();
        const offerId = retval.toNumber();

        let tokenId = await instance_snarkbase.getTokensCount();
        tokenId = tokenId.toNumber();

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        try {
            await instance.addBid(tokenId, {from: bidder, value: bidCostWrong });
        } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert Bid amount must be less than the offer price but bigger than zero -- Reason given: Bid amount must be less than the offer price but bigger than zero.');
        }

        await instance.addBid(tokenId, {from: bidder, value: bidCostRight });

        retval = await instance.getTotalNumberOfBids();
        const bidId = retval.toNumber();

        retval = await instance.getBidIdMaxPrice(tokenId);
        assert.equal(retval[0], bidId, "error on step 2");
        assert.equal(retval[1], bidCostRight, "error on step 3");

        const tokenOwner = await instance_snarkbase.getOwnerOfToken(tokenId);
        try {
            await instance_erc721.transferFrom(tokenOwner, accounts[5], tokenId);
        } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert Token has to be free from different obligations on Snark platform -- Reason given: Token has to be free from different obligations on Snark platform.');
        }

        await instance.cancelOffer(offerId);

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 3, "error on step 4");

        retval = await instance.getOfferByToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 5");
    });

    it("7. test issue #35 on github", async () => {
        const bidder2 = accounts[2];
        const bidCost = web3.utils.toWei('1.5', "Ether");
        const bidCost2 = web3.utils.toWei('1', "Ether");

        let tokenId = await instance_snarkbase.getTokensCount();
        tokenId = tokenId.toNumber();

        const owner = await instance_snarkbase.getOwnerOfToken(tokenId);

        let retval = await instance.getOfferByToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 2");

        await instance.addBid(tokenId, { from: bidder2, value: bidCost });
        const bidId = await instance.getTotalNumberOfBids();

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 2, "error on step 3");

        await instance.acceptBid(bidId, { from: owner });

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, bidder2, "error on step 4");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 5");

        await instance.addBid(tokenId, { from: owner, value: bidCost2 });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 6");

    });

    it("8. test github issue #26", async () => {
        const owner = accounts[2];
        const tokenHash = web3.utils.sha3("8. test github issue #26");
        const limitedEdition = 1;
        const profitShareFromSecondarySale = 0;
        const tokenUrl = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7Eni";
        const participants = [ accounts[2] ];
        const profits = [ 100 ];

        let retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 1");

        retval = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(owner);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        await instance_snarkbase.createProfitShareScheme(owner, participants, profits);

        retval = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(owner);
        assert.equal(retval.toNumber(), 1, "error on step 3");

        const profitShareSchemeId = await instance_snarkbase.getProfitShareSchemeIdForOwner(owner, 0);

        await instance_snarkbase.addToken(
            owner,
            tokenHash,
            tokenUrl,
            'ipfs://decorator.io',
            'bla-blaa-blaaa',
            [
                limitedEdition,
                profitShareFromSecondarySale,
                profitShareSchemeId
            ],
            [
                true,
                true
            ],
            { from: accounts[0] }
        );

        retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 2, "error on step 4");

        const tokenId = await instance_snarkbase.getTokensCount();

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 5");

        retval = await instance.getBidOfOwnerForToken(tokenId, { from: accounts[3] });
        assert.equal(retval.toNumber(), 0, "Owner's bid is not zero");

        await instance.addBid(tokenId, {from: accounts[3], value: web3.utils.toWei('0.1', 'ether') });

        const lastBidId = await instance.getTotalNumberOfBids();

        retval = await instance.getBidOfOwnerForToken(tokenId, { from: accounts[3] });
        assert.equal(retval.toNumber(), lastBidId, "Bid id has to be bigger then zero");

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 6");

        await instance.addBid(tokenId, {from: accounts[4], value: web3.utils.toWei('0.12', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 2, "error on step 7");

        await instance.addBid(tokenId, {from: accounts[5], value: web3.utils.toWei('0.14', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 3, "error on step 8");

        await instance.addBid(tokenId, {from: accounts[6], value: web3.utils.toWei('0.16', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 4, "error on step 9");

        await instance.addBid(tokenId, {from: accounts[7], value: web3.utils.toWei('0.18', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 5, "error on step 10");

        await instance.addBid(tokenId, {from: accounts[8], value: web3.utils.toWei('0.2', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 6, "error on step 11");

        await instance.addBid(tokenId, {from: accounts[9], value: web3.utils.toWei('0.22', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 7, "error on step 12");

        await instance.addBid(tokenId, {from: accounts[10], value: web3.utils.toWei('0.24', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 8, "error on step 13");

        await instance.addBid(tokenId, {from: accounts[11], value: web3.utils.toWei('0.26', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 9, "error on step 14");

        await instance.addBid(tokenId, {from: accounts[12], value: web3.utils.toWei('0.28', 'ether') });

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 10, "error on step 15");

        try {
            await instance.addBid(tokenId, {from: accounts[13], value: web3.utils.toWei('0.3', 'ether') });
        } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert Token can\'t have more than 10 bids -- Reason given: Token can\'t have more than 10 bids.', "error on step 16");
        }

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 10, "error on step 17");

        try {
            await instance.addBid(tokenId, {from: accounts[14], value: web3.utils.toWei('0.32', 'ether') });
        } catch(e) {
            assert.equal(e.message, 'Returned error: VM Exception while processing transaction: revert Token can\'t have more than 10 bids -- Reason given: Token can\'t have more than 10 bids.', "error on step 18");
        }

        retval = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(retval.toNumber(), 10, "error on step 19");
    });

    it("9. test secondary sale distribution", async () => {
        const tokenId = 1;

        let tokenDetail = await instance_snarkbase.getTokenDetail(tokenId);

        const tokenOwner = tokenDetail.currentOwner;
        const newTokenOwner = accounts[7];

        const old_price = new BigNumber(tokenDetail.lastPrice);
        const new_price = old_price.plus(web3.utils.toWei('1', "Ether"));

        const snarkWalletAndProfit = await instance_snarkbase.getSnarkWalletAddressAndProfit();

        let retval = await instance_snarkbase.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        await instance.addOffer(tokenId, new_price, { from: tokenOwner });

        const old_balance_snark = await web3.eth.getBalance(snarkWalletAndProfit.snarkWalletAddr);
        const old_balance_tokenOwner = await web3.eth.getBalance(tokenOwner);
        const numberParticipants = await instance_snarkbase.getNumberOfParticipantsForProfitShareScheme(tokenDetail.profitShareSchemeId);
        const old_balance_participants = [];
        const participantDetail = [];
        for (let i = 0; i < numberParticipants; i++) {
            const participant = await instance_snarkbase.getParticipantOfProfitShareScheme(tokenDetail.profitShareSchemeId, i);
            participantDetail.push(participant);
            retval = await web3.eth.getBalance(participant[0]);
            old_balance_participants.push(retval);
        }
        const sum_for_snark = new_price.multipliedBy(snarkWalletAndProfit.platformProfit).dividedBy(100);
        const amount_of_secondary_sale = new_price.minus(old_price).minus(sum_for_snark).multipliedBy(tokenDetail.profitShareFromSecondarySale).dividedBy(100);
        const sum_for_seller = new_price.minus(sum_for_snark).minus(amount_of_secondary_sale);
        const sum_for_participants = [];
        participantDetail.forEach((element, index) => {
            let sp = amount_of_secondary_sale.multipliedBy(element[1]).dividedBy(100);
            sum_for_participants.push(sp);
        });

        let sum_snark_seller_participants = sum_for_snark.plus(sum_for_seller);
        participantDetail.forEach((element, index) => {
            sum_snark_seller_participants = sum_snark_seller_participants.plus(sum_for_participants[index]);
        });
        assert.equal(sum_snark_seller_participants.toNumber(), new_price.toNumber(), "sum of parts should be equal of new price");

        const offerId = await instance.getTotalNumberOfOffers();
        await instance.buyOffer([offerId], { from: newTokenOwner, value: new_price });

        const new_balance_snark = await web3.eth.getBalance(snarkWalletAndProfit.snarkWalletAddr);
        assert.equal(
            new BigNumber(new_balance_snark).toNumber(), 
            new BigNumber(old_balance_snark).plus(sum_for_snark).toNumber(), 
            "Rusult balance of Snark is wrong");
        
        const new_balance_tokenOwner = await web3.eth.getBalance(tokenOwner);
        assert.equal(
            new BigNumber(new_balance_tokenOwner).toNumber(), 
            new BigNumber(old_balance_tokenOwner).plus(sum_for_seller).toNumber(),
            "Result balance of ex owner of token is wrong");
                
        for (let i = 0; i < numberParticipants; i++) {
            retval = await web3.eth.getBalance(participantDetail[i][0]);
            assert.equal(
                new BigNumber(retval).toNumber(),
                new BigNumber(old_balance_participants[i]).plus(sum_for_participants[i]).toNumber(),
                `Result balance of participant ${i+1} is wrong`
            );
        }

    });

    it("10. test toGiftToken function", async () => {
        const tokenId = 1;
        const token_price = web3.utils.toWei('3', "Ether");
        const bidPrice = web3.utils.toWei('2.3', "Ether");
        let offerId = await instance.getOfferByToken(tokenId);
        const owner_old = await instance_snarkbase.getOwnerOfToken(tokenId);
        const owner_new = accounts[10];
        
        assert.notEqual(owner_old, owner_new, "error on step 1");
        
        let bidId = await instance.getBidOfOwnerForToken(tokenId, { from: owner_new });
        
        assert.equal(offerId, 0, "error on step 2");
        assert.equal(bidId, 0, "error on step 3");
        
        const balanceOfBidderBeforeAddBid = await web3.eth.getBalance(owner_new);

        await instance.addOffer(tokenId, token_price, { from: owner_old });
        await instance.addBid(tokenId, { from: owner_new, value: bidPrice });

        const balanceOfBidderAfterAddBid = await web3.eth.getBalance(owner_new);

        assert.isAbove(
            new BigNumber(balanceOfBidderBeforeAddBid).toNumber(), 
            new BigNumber(balanceOfBidderAfterAddBid).toNumber(), 
            "error on step 4"
        );
        
        bidId = await instance.getBidOfOwnerForToken(tokenId, { from: owner_new });
        assert.notEqual(bidId, 0, "error on step 5");
        
        await instance.toGiftToken(tokenId, owner_new, { from: owner_old });
        
        const user = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(user, owner_new, "error on step 6");
        
        bidId = await instance.getBidOfOwnerForToken(tokenId, { from: owner_new });
        assert.equal(bidId, 0, "error on step 7");

        const balanceOfBidderAfterGiftToken = await web3.eth.getBalance(owner_new);
        assert.equal(
            new BigNumber(balanceOfBidderAfterGiftToken).toNumber(), 
            new BigNumber(balanceOfBidderAfterAddBid).plus(bidPrice).toNumber(), 
            "error on step 8"
        );
    });

    it("11. test accept Bid when the last prise of token is 0", async () => {
        const tokenOwner = accounts[0];
        const bidder1 = accounts[1];
        const bidder2 = accounts[2];
        const participants = [ tokenOwner, accounts[3] ];
        const profits = [ 95, 5 ];

        const costOfBid1 = web3.utils.toWei('0.4', "Ether");
        const costOfBid2 = web3.utils.toWei('0.6', "Ether");

        await instance_snarkbase.createProfitShareScheme(tokenOwner, participants, profits);
        const numberOfSchemes = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(tokenOwner);
        const profitShareSchemeId = await instance_snarkbase.getProfitShareSchemeIdForOwner(tokenOwner, numberOfSchemes - 1);

        await instance_snarkbase.addToken(
            tokenOwner,
            web3.utils.sha3("11. test accept Bid when the last prise of token is 0"),
            "QmXDeiDv96osHCBdgJdwK2sRD96CfPYmVo4KzS9e9E7Evi",
            'ipfs://decorator.io',
            'bla-blaa-blaaa',
            [
                1,
                15,
                profitShareSchemeId
            ],
            [
                true,
                true
            ],
            { from: tokenOwner }
        );

        const tokenId = await instance_snarkbase.getTokensCount();
        const countOfBids = await instance.getNumberBidsOfToken(tokenId);
        let tokenDetail = await instance_snarkbase.getTokenDetail(tokenId);

        assert.equal(countOfBids, 0, "Amount of bids not equal zero");
        assert.equal(tokenDetail.currentOwner, tokenOwner, "Token owner is wrong");
        assert.equal(tokenDetail.artist, tokenOwner, "Artist is wrong");
        assert.equal(tokenDetail.lastPrice, 0, "Price of token isn't zero");

        const balanceOfTokenOwnerBeforeAddBids = await web3.eth.getBalance(tokenOwner);

        await instance.addBid(tokenId, {from: bidder1, value: costOfBid1 });
        await instance.addBid(tokenId, {from: bidder2, value: costOfBid2 });
        const bidId2 = await instance.getTotalNumberOfBids();

        const balanceOfTokenOwnerAfterAddBids = await web3.eth.getBalance(tokenOwner);
        assert.equal(
            new BigNumber(balanceOfTokenOwnerBeforeAddBids).toNumber(),
            new BigNumber(balanceOfTokenOwnerAfterAddBids).toNumber(),
            "A balance of token owner was changed"
        );

        const balanceOfBidder1AfterAddBids = await web3.eth.getBalance(bidder1);
        const balanceOfBidder2AfterAddBids = await web3.eth.getBalance(bidder2);

        let tx = await instance.acceptBid(bidId2, { from: tokenOwner });

        const gasUsed = tx.receipt.gasUsed;
        tx = await web3.eth.getTransaction(tx.tx);
        const gasPrice = tx.gasPrice;
        const txCost = new BigNumber(gasUsed).multipliedBy(gasPrice).toNumber();
        const platformValue = new BigNumber(costOfBid2).multipliedBy(5).dividedBy(100).toNumber();
        const balanceOfTokenOwnerAfterAcceptBid = await web3.eth.getBalance(tokenOwner);
        const balanceOfBidder1AfterAcceptBid = await web3.eth.getBalance(bidder1);
        const balanceOfBidder2AfterAcceptBid = await web3.eth.getBalance(bidder2);        
        const participantValue = new BigNumber(costOfBid2).minus(platformValue).multipliedBy(profits[0]).dividedBy(100).toNumber();

        assert.equal(
            new BigNumber(balanceOfTokenOwnerAfterAcceptBid).toNumber(), 
            new BigNumber(balanceOfTokenOwnerAfterAddBids).plus(participantValue).minus(txCost).toNumber(),
            "Balance of ex owner of token is wrong"
        );
        assert.equal(
            new BigNumber(balanceOfBidder1AfterAddBids).toNumber(),
            new BigNumber(balanceOfBidder1AfterAcceptBid).minus(costOfBid1).toNumber(),
            "Balance of bidder 1 is wrong"
        );
        assert.equal(
            new BigNumber(balanceOfBidder2AfterAddBids).toNumber(),
            new BigNumber(balanceOfBidder2AfterAcceptBid).toNumber(),
            "Balance of bidder 2 is wrong"
        );

        const numberOfTokenBids = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(numberOfTokenBids, 0, "Number of bids in the end is not correct");

        tokenDetail = await instance_snarkbase.getTokenDetail(tokenId);
        assert.isAbove(new BigNumber(tokenDetail.lastPrice).toNumber(), 0, "Last price was not saved");
    });

    it("11. test accept Bid when the last prise of token is bigger than 0", async () => {
        const bidder1 = accounts[1];
        const bidder2 = accounts[0];
        const tokenOwner = accounts[2];

        const costOfBid1 = web3.utils.toWei('0.5', "Ether");
        const costOfBid2 = web3.utils.toWei('0.7', "Ether");

        const tokenId = await instance_snarkbase.getTokensCount();
        const tokenDetail = await instance_snarkbase.getTokenDetail(tokenId);
        const countOfBids = await instance.getNumberBidsOfToken(tokenId);

        assert.equal(countOfBids, 0, "Amount of bids not equal zero");
        assert.equal(tokenDetail.currentOwner, tokenOwner, "Token owner is wrong");
        assert.equal(tokenDetail.artist, bidder2, "Artist is wrong");
        assert.isAbove(new BigNumber(tokenDetail.lastPrice).toNumber(), 0, "Last price was not saved");

        const balanceOfBidder1BeforeAddBids = await web3.eth.getBalance(bidder1);
        const balanceOfBidder2BeforeAddBids = await web3.eth.getBalance(bidder2);

        const txb1 = await instance.addBid(tokenId, {from: bidder1, value: costOfBid1 });
        const txb2 = await instance.addBid(tokenId, {from: bidder2, value: costOfBid2 });
        const b1gasUsed = txb1.receipt.gasUsed;
        const b2gasUsed = txb2.receipt.gasUsed;

        const bidId2 = await instance.getTotalNumberOfBids();

        const balanceOfTokenOwnerAfterAddBids = await web3.eth.getBalance(tokenOwner);
        const balanceOfBidder1AfterAddBids = await web3.eth.getBalance(bidder1);
        assert.equal(
            new BigNumber(balanceOfBidder1AfterAddBids).toNumber(),
            new BigNumber(balanceOfBidder1BeforeAddBids).minus(b1gasUsed).minus(costOfBid1).toNumber(),
            "Balance of bidder 1 after add bid is not correct");
        const balanceOfBidder2AfterAddBids = await web3.eth.getBalance(bidder2);
        assert.equal(
            new BigNumber(balanceOfBidder2AfterAddBids).toNumber(),
            new BigNumber(balanceOfBidder2BeforeAddBids).minus(b2gasUsed).minus(costOfBid2).toNumber(),
            "Balance of bidder 2 after add bid is not correct");

        let tx = await instance.acceptBid(bidId2, { from: tokenOwner });

        const gasUsed = tx.receipt.gasUsed;
        tx = await web3.eth.getTransaction(tx.tx);
        const gasPrice = tx.gasPrice;
        const txCost = new BigNumber(gasUsed).multipliedBy(gasPrice).toNumber();

        const participantsAmount = await instance_snarkbase.getNumberOfParticipantsForProfitShareScheme(tokenDetail.profitShareSchemeId);
        const participants = [];
        const participantsBalances = [];
        for (let i = 0; i < participantsAmount; i++) {
            let p = await instance_snarkbase.getParticipantOfProfitShareScheme(tokenDetail.profitShareSchemeId, i);
            participants.push(p);
            let b = await web3.eth.getBalance(p[0]);
            participantsBalances.push(b);
        }

        const platformProfitShare = await instance_snarkbase.getPlatformProfitShare();
        const valueOfPlatform = new BigNumber(costOfBid2).multipliedBy(platformProfitShare).dividedBy(100).toNumber();
        const profit = new BigNumber(costOfBid2).minus(valueOfPlatform).minus(tokenDetail.lastPrice);
        const distributionAmount = new BigNumber(profit).multipliedBy(tokenDetail.profitShareFromSecondarySale).dividedBy(100).toNumber();
        let balanceOfOwner = new BigNumber(balanceOfTokenOwnerAfterAddBids).minus(txCost).plus(costOfBid2).minus(valueOfPlatform).minus(distributionAmount).toNumber();

        const valuesForParticipants = [];
        for (i = 0; i < participantsAmount; i++) {
            const v = new BigNumber(distributionAmount).multipliedBy(participants[i][1]).dividedBy(100).toNumber();
            valuesForParticipants.push(v);
            if (participants[i][0] == tokenOwner) {
                balanceOfOwner = new BigNumber(balanceOfOwner).plus(v).toNumber();
            }
        }

        const balanceOfTokenOwnerAfterAcceptBid = await web3.eth.getBalance(tokenOwner);
        assert.equal(
            new BigNumber(balanceOfOwner).toNumber(),
            new BigNumber(balanceOfTokenOwnerAfterAcceptBid).toNumber(), 
            "Balance of owner is wrong after accepting a bid"
        );

        const balanceOfBidder1AfterAcceptBid = await web3.eth.getBalance(bidder1);
        assert.equal(
            new BigNumber(balanceOfBidder1AfterAcceptBid).toNumber(),
            new BigNumber(balanceOfBidder1BeforeAddBids).minus(b1gasUsed).toNumber(),
            "Balance of Bidder 1 is not correct"
        );

        const balanceOfBidder2AfterAcceptBid = await web3.eth.getBalance(bidder2);
        assert.equal(
            new BigNumber(balanceOfBidder2AfterAcceptBid).toNumber(),
            new BigNumber(balanceOfBidder2AfterAddBids).plus(valuesForParticipants[0]).toNumber(),
            "Balance of Bidder 2 is not correct"
        );
        
        const numberOfTokenBids = await instance.getNumberBidsOfToken(tokenId);
        assert.equal(numberOfTokenBids, 0, "Number of bids in the end is not correct");
    });
});
