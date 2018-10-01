var TestSnarkOfferBidLib = artifacts.require("TestSnarkOfferBidLib");

contract('TestSnarkOfferBidLib', async (accounts) => {

    let instance = null;

    before(async () => {
        instance = await TestSnarkOfferBidLib.deployed();
    });

    it("1. get size of the TestSnarkBaseLib library", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("2. test addOffer functions", async () => {
        // в тестах проверить events 

        const offerOwner = web3.eth.accounts[0].toUpperCase();
        const tokenId = 1;
        const price = 50;

        let retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 0, "error on step 1");

        retval = await instance.getTotalNumberOfOwnerOffers(offerOwner);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getOfferIdByTokenId(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        const event = instance.OfferAdded({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                retOfferId = result.args._offerId.toNumber();
                retOfferOwner = result.args._offerOwner;
                console.log(`event OfferAdded: owner - ${retOfferOwner}, offer Id - ${retOfferId}`);
                // assert.equal(schemeId, 1, "SchemeId is not equal 1");
            }
        });

        await instance.addOffer(offerOwner, tokenId, price);

        retval = await instance.getTotalNumberOfOffers();
        assert.equal(retval.toNumber(), 1, "error on step 6");

        retval = await instance.getTotalNumberOfOwnerOffers(offerOwner);
        assert.equal(retval.toNumber(), 1, "error on step 7");

        retval = await instance.getOfferIdByTokenId(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 8");

        retval = await instance.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 9");

        retval = await instance.getSaleStatusForOffer(1);
        assert.equal(retval.toNumber(), 2, "error on step 10");

        retval = await instance.getTokenIdByOfferId(1);
        assert.equal(retval.toNumber(), tokenId, "error on step 11");

        retval = await instance.getOfferIdOfOwner(offerOwner, 0);
        assert.equal(retval.toNumber(), 1, "error on step 12");

        await instance.deleteOffer(1);

        retval = await instance.getOfferIdByTokenId(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 13");

        retval = await instance.getTotalNumberOfOwnerOffers(offerOwner);
        assert.equal(retval.toNumber(), 0, "error on step 14");

        retval = await instance.getSaleStatusForOffer(1);
        assert.equal(retval.toNumber(), 3, "error on step 15");
        
        retval = await instance.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 4");
    });

    it("3. test addBid and deleteBid functions", async () => {
        const bidOwner = web3.eth.accounts[0];
        const tokenId = 1;
        const bidPrice = 25;

        let retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 0, "error on step 1");
        
        retval = await instance.getNumberOfTokenBids(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        const event = instance.BidAdded({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                retBidId = result.args._bidId.toNumber();
                retBidOwner = result.args._bidOwner;
                console.log(`event BidAdded: owner - ${retBidOwner}, bid Id - ${retBidId}`);
                // assert.equal(schemeId, 1, "SchemeId is not equal 1");
            }
        });

        await instance.addBid(bidOwner, tokenId, bidPrice);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 4");
        
        retval = await instance.getNumberOfTokenBids(tokenId);
        assert.equal(retval.toNumber(), 1, "error on step 5");

        retval = await instance.getOwnerOfBid(1);
        assert.equal(retval.toUpperCase(), bidOwner.toUpperCase(), "error on step 6");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 7");

        retval = await instance.getBidOfOwner(bidOwner, 0);
        assert.equal(retval.toNumber(), 1, "error on step 8");

        retval = await instance.getBidIdForToken(tokenId, 0);
        assert.equal(retval.toNumber(), 1, "error on step 9");

        retval = await instance.getTokenIdByBidId(1);
        assert.equal(retval.toNumber(), 1, "error on step 10");

        retval = await instance.getBidPrice(1);
        assert.equal(retval.toNumber(), bidPrice, "error on step 11");

        retval = await instance.getBidSaleStatus(1);
        assert.equal(retval.toNumber(), 2, "error on step 12");

        await instance.deleteBid(1);

        retval = await instance.getNumberOfTokenBids(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 13");

        retval = await instance.getBidSaleStatus(1);
        assert.equal(retval.toNumber(), 3, "error on step 14");
    });

});
