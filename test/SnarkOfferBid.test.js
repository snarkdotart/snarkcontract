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

    it("2. test addOffer and deleteOffer functions", async () => {
        const owner = accounts[0];
        const tokenId = 1;
        const price = 50;
        const offerId = 1;
        ////////////////////

        let retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 0, "error on step getTokensCountByOwner before addSnark");

        const tokenHash = web3.sha3("tokenHash");
        const limitedEdition = 1;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "http://snark.art";
        const profitShareSchemeId = 1;

        await instance_snarkbase.addToken(
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

        await instance.addOffer(tokenId, price);

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 1, "error on step 4");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 2, "error on step 5");

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 1, "error on step 6");

        retval = await instance.getOwnerOfferByIndex(owner, 0);
        assert.equal(retval.toNumber(), 1, "error on step 7");

        const eventOfferDeleted = instance.OfferDeleted({ fromBlock: 'latest' });
        eventOfferDeleted.watch(function (error, result) {
            if (!error) {
                retOfferId = result.args._offerId.toNumber();
                console.log(`event OfferDeleted: offer Id - ${retOfferId}`);
            }
        });

        await instance.deleteOffer(1);

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 8");
    });

    it("3. test buyOffer function", async () => {
        const owner = accounts[0];
        const buyer = accounts[1];
        const tokenId = 1;
        const offerId = 2;
        const price = web3.toWei(1, 'ether');

        let retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 1, "error on step 2");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        await instance.addOffer(tokenId, price);

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 2, "error on step 4");

        retval = await instance.getSaleStatusForOffer(offerId);
        assert.equal(retval.toNumber(), 2, "error on step 5");
        
        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 1, "error on step 6");

        retval = await instance_snarkbase.getWithdrawBalance(owner);
        assert.equal(retval.toNumber(), 0, "error on step 7");

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, owner, "error on step 8");

        await instance.buyOffer(offerId, { from: buyer, value: web3.toWei(2, 'ether') });

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, buyer, "error on step 9");

        retval = await instance_snarkbase.getWithdrawBalance(owner);
        assert.equal(retval.toNumber(), price, "error on step 10");
    });

    it("4. test addBid and deleteBid functions", async () => {
        const tokenOwner = accounts[1];
        const bidOwner = accounts[2];
        const tokenId = 1;
        const bidPrice = web3.toWei(0.5, 'ether');

        let retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 0, "error on step 1");
        
        retval = await instance.getNumberOfTokenBids(tokenId);
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
        assert.equal(retval.toNumber(), web3.toWei(0, 'ether'), "error on step 5");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), web3.toWei(0, 'ether'), "error on step 5");

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 6");

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), 0, "error on step 7");

        await instance.addBid(tokenId, {from: bidOwner, value: bidPrice});

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 8");
        
        retval = await instance.getNumberOfTokenBids(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 9");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 10");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), web3.toWei(0, 'ether'), "error on step 11");

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 12");

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), bidPrice, "error on step 13");

        await instance.acceptBid(1, { from: tokenOwner });

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval, bidOwner, "error on step 11");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 12");
        
        retval = await instance.getNumberOfTokenBids(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 13");

        let balanceOfTokenOwner = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        balanceOfTokenOwner = balanceOfTokenOwner.toNumber();
        assert.equal(balanceOfTokenOwner, bidPrice, "error on step 14");
        console.log(`tokenOwner's balance before addBid: ${ balanceOfTokenOwner }`);

        let balanceOfBidOwner = await instance_snarkbase.getWithdrawBalance(bidOwner);
        balanceOfBidOwner = balanceOfBidOwner.toNumber();
        assert.equal(balanceOfBidOwner, 0, "error on step 15");
        console.log(`bidOwner's balance before addBid: ${ balanceOfBidOwner }`);
        
        balanceOfContract = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        balanceOfContract = balanceOfContract.toNumber();
        assert.equal(balanceOfContract, 0, "error on step 16");
        console.log(`contract's balance before addBid: ${ balanceOfContract }`);

        await instance.addBid(tokenId, {from: tokenOwner, value: web3.toWei(0.57, 'ether')});

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log(`tokenOwner's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        console.log(`bidOwner's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`contract's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 2, "error on step 17");
        
        retval = await instance.getNumberOfTokenBids(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 18");

        retval = await instance.getNumberBidsOfOwner(tokenOwner);
        assert.equal(retval.toNumber(), 1, "error on step 19");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 20");

        await instance.cancelBid(2, { from: tokenOwner });

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log(`tokenOwner's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        console.log(`bidOwner's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`contract's balance after cancelBid: ${ retval.toNumber() }`);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 2, "error on step 21");
        
        retval = await instance.getNumberOfTokenBids(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 22");

        retval = await instance.getNumberBidsOfOwner(tokenOwner);
        assert.equal(retval.toNumber(), 1, "error on step 23");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 24");

    });

});
