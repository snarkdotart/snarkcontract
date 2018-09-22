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
        const owner = web3.eth.accounts[0].toUpperCase();
        const artworkId = 1;
        const price = 50;
        
        ////////////////////

        let retval = await instance_snarkbase.getTokensCountByOwner(owner);
        assert.equal(retval.toNumber(), 0, "error on step getTokensCountByOwner before addSnark");

        const artworkHash = web3.sha3("artworkHash");
        const limitedEdition = 1;
        const profitShareFromSecondarySale = 20;
        const artworkUrl = "http://snark.art";
        const profitShareSchemeId = 1;

        await instance_snarkbase.addArtwork(
            artworkHash,
            limitedEdition,
            profitShareFromSecondarySale,
            artworkUrl,
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

        await instance.addOffer(artworkId, price);

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 1, "error on step 2");

        retval = await instance.getOwnerOfferByIndex(owner, 0);
        assert.equal(retval.toNumber(), 1, "error on step 3");

        const eventOfferDeleted = instance.OfferDeleted({ fromBlock: 'latest' });
        eventOfferDeleted.watch(function (error, result) {
            if (!error) {
                retOfferId = result.args._offerId.toNumber();
                console.log(`event OfferDeleted: offer Id - ${retOfferId}`);
            }
        });

        await instance.deleteOffer(1);

        retval = await instance.getOwnerOffersCount(owner);
        assert.equal(retval.toNumber(), 0, "error on step 2");
    });

    it("3. test addBid and deleteBid functions", async () => {
        const tokenOwner = web3.eth.accounts[0];
        const bidOwner = web3.eth.accounts[1];
        const artworkId = 1;
        const bidPrice = web3.toWei(0.5, 'ether');

        let retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 0, "error on step 1");
        
        retval = await instance.getNumberOfArtworkBids(artworkId);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance_snarkbase.getOwnerOfArtwork(artworkId);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 4");

        const event = instance.BidAdded({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                retBidId = result.args._bidId.toNumber();
                retBidOwner = result.args._bidder;
                console.log(`event BidAdded: owner - ${retBidOwner}, bid Id - ${retBidId}`);
            }
        });
        await instance.addBid(artworkId, {from: bidOwner, value: bidPrice});

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 5");
        
        retval = await instance.getNumberOfArtworkBids(artworkId);
        assert.equal(retval.toNumber(), 1, "error on step 6");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 7");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), 0, "error on step 8");

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        assert.equal(retval.toNumber(), 0, "error on step 9");

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        assert.equal(retval.toNumber(), bidPrice, "error on step 10");

        await instance.acceptBid(1); // it calls deleteBid as well

        retval = await instance_snarkbase.getOwnerOfArtwork(artworkId);
        assert.equal(retval.toUpperCase(), bidOwner.toUpperCase(), "error on step 11");

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 1, "error on step 12");
        
        retval = await instance.getNumberOfArtworkBids(artworkId);
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

        console.log("run addBid after step 16");
        await instance.addBid(artworkId, {from: tokenOwner, value: web3.toWei(0.57, 'ether')});

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log(`tokenOwner's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(bidOwner);
        console.log(`bidOwner's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance_snarkbase.getWithdrawBalance(SnarkStorage.address);
        console.log(`contract's balance after addBid: ${ retval.toNumber() }`);

        retval = await instance.getTotalNumberOfBids();
        assert.equal(retval.toNumber(), 2, "error on step 17");
        
        retval = await instance.getNumberOfArtworkBids(artworkId);
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
        
        retval = await instance.getNumberOfArtworkBids(artworkId);
        assert.equal(retval.toNumber(), 0, "error on step 22");

        retval = await instance.getNumberBidsOfOwner(tokenOwner);
        assert.equal(retval.toNumber(), 1, "error on step 23");

        retval = await instance.getNumberBidsOfOwner(bidOwner);
        assert.equal(retval.toNumber(), 1, "error on step 24");

    });

    // it("3. test PlatformProfitShare functions", async () => {
    //     const val = 5;

    //     let retval = await instance.getPlatformProfitShare();
    //     assert.equal(retval.toNumber(), 0);

    //     await instance.setPlatformProfitShare(val);

    //     retval = await instance.getPlatformProfitShare();
    //     assert.equal(retval.toNumber(), val);
    // });

    // it("4. test addArtwork | totalNumberOfArtworks functions", async () => {
    //     const artistAddress = "0xC04691B99EB731536E35F375ffC85249Ec713597".toUpperCase();
    //     const artworkHash = web3.sha3("artworkHash");
    //     const limitedEdition = 10;
    //     const editionNumber = 2;
    //     const lastPrice = 5000;
    //     const profitShareSchemeId = 1;
    //     const profitShareFromSecondarySale = 20;
    //     const artworkUrl = "http://snark.art";

    //     let retval = await instance.getTotalNumberOfArtworks();
    //     assert.equal(retval.toNumber(), 0);

    //     const event = instance.ArtworkCreated({ fromBlock: 'latest' });
    //     event.watch(function (error, result) {
    //         if (!error) {
    //             artworkId = result.args._artworkId.toNumber();
    //             assert.equal(artworkId, 1, "Artwork Id is not equal 1");
    //         }
    //     });

    //     retval = await instance.addArtwork(
    //         artistAddress,
    //         artworkHash,
    //         limitedEdition,
    //         editionNumber,
    //         lastPrice,
    //         profitShareSchemeId,
    //         profitShareFromSecondarySale,
    //         artworkUrl
    //     );

    //     artworkId = await instance.getTotalNumberOfArtworks();
    //     artworkId = artworkId.toNumber();
    //     assert.equal(artworkId, 1);

    //     retval = await instance.getArtwork(artworkId);
    //     assert.equal(retval[0].toUpperCase(), artistAddress.toUpperCase());
    //     assert.equal(retval[1].toUpperCase(), artworkHash.toUpperCase());
    //     assert.equal(retval[2].toNumber(), limitedEdition);
    //     assert.equal(retval[3].toNumber(), editionNumber);
    //     assert.equal(retval[4].toNumber(), lastPrice);
    //     assert.equal(retval[5].toNumber(), profitShareSchemeId);
    //     assert.equal(retval[6].toNumber(), profitShareFromSecondarySale);
    //     assert.equal(retval[7], artworkUrl);
    // });

    // it("5. test ArtworkArtist functions", async () => {
    //     const val = '0xC04691B99EB731536E35F375ffC85249Ec713597'.toUpperCase();
    //     const key = 2;

    //     let retval = await instance.getArtworkArtist(key);
    //     assert.equal(retval, 0);

    //     await instance.setArtworkArtist(key, val);
    //     retval = await instance.getArtworkArtist(key);
    //     assert.equal(retval.toUpperCase(), val);
    // });

    // it("6. test ArtworkLimitedEdition functions", async () => {
    //     const key1 = 3;
    //     const val1 = 45;

    //     let retval = await instance.getArtworkLimitedEdition(key1);
    //     assert.equal(retval, 0);

    //     await instance.setArtworkLimitedEdition(key1, val1);
    //     retval = await instance.getArtworkLimitedEdition(key1);
    //     assert.equal(retval, val1);
    // });

    // it("7. test ArtworkEditionNumber functions", async () => {
    //     const key1 = 4;
    //     const key2 = 5;
    //     const val1 = 1;
    //     const val2 = 5;

    //     let retval = await instance.getArtworkEditionNumber(key1);
    //     assert.equal(retval, 0);

    //     retval = await instance.getArtworkEditionNumber(key2)
    //     assert.equal(retval, 0);

    //     await instance.setArtworkEditionNumber(key1, val1);
    //     await instance.setArtworkEditionNumber(key2, val2);

    //     retval = await instance.getArtworkEditionNumber(key1);
    //     assert.equal(retval, val1);

    //     retval = await instance.getArtworkEditionNumber(key2)
    //     assert.equal(retval, val2);
    // });

    // it("8. test ArtworkLastPrice functions", async () => {
    //     const key1 = 6;
    //     const key2 = 7;
    //     const val1 = 34;
    //     const val2 = 98;

    //     let retval = await instance.getArtworkLastPrice(key1);
    //     assert.equal(retval, 0);

    //     retval = await instance.getArtworkLastPrice(key2);
    //     assert.equal(retval, 0);

    //     await instance.setArtworkLastPrice(key1, val1);
    //     await instance.setArtworkLastPrice(key2, val2);

    //     retval = await instance.getArtworkLastPrice(key1);
    //     assert.equal(retval, val1);

    //     retval = await instance.getArtworkLastPrice(key2);
    //     assert.equal(retval, val2);
    // });

    // it("9. test ArtworkHash functions", async () => {
    //     const key = 8;
    //     const val = web3.sha3("test_hash_of_artwork");

    //     let retval = await instance.getArtworkHash(key);
    //     assert.equal(retval, 0);

    //     await instance.setArtworkHash(key, val);

    //     retval = await instance.getArtworkHash(key);
    //     assert.equal(retval, val);
    // });

    // it("10. test ArtworkProfitShareSchemeId functions", async () => {
    //     const key = 9;
    //     const val = 2;

    //     let retval = await instance.getArtworkProfitShareSchemeId(key);
    //     assert.equal(retval, 0);

    //     await instance.setArtworkProfitShareSchemeId(key, val);

    //     retval = await instance.getArtworkProfitShareSchemeId(key);
    //     assert.equal(retval, val);
    // });

    // it("11. test ArtworkProfitShareFromSecondarySale functions", async () => {
    //     const key = 10;
    //     const val = 20;

    //     let retval = await instance.getArtworkProfitShareFromSecondarySale(key);
    //     assert.equal(retval, 0);

    //     await instance.setArtworkProfitShareFromSecondarySale(key, val);

    //     retval = await instance.getArtworkProfitShareFromSecondarySale(key);
    //     assert.equal(retval.toNumber(), val);
    // });

    // it("12. test ArtworkURL functions", async () => {
    //     const key = 11;
    //     const val = "http://snark.art";

    //     let retval = await instance.getArtworkURL(key);
    //     assert.isEmpty(retval);

    //     await instance.setArtworkURL(key, val);

    //     retval = await instance.getArtworkURL(key);
    //     assert.equal(retval, val);
    // });

    // it("13. test ProftShareScheme functions", async () => {
    //     const participants = [
    //         '0xC04691B99EB731536E35F375ffC85249Ec713597', 
    //         '0xB94691B99EB731536E35F375ffC85249Ec717233'
    //     ];
    //     const profits = [ 20, 80 ];

    //     let retval = await instance.getTotalNumberOfProfitShareSchemes();
    //     assert.equal(retval, 0);

    //     retval = await instance.getNumberOfProfitShareSchemesForOwner();
    //     assert.equal(retval, 0);

    //     const event = instance.ProfitShareSchemeCreated({ fromBlock: 'latest' });
    //     event.watch(function (error, result) {
    //         if (!error) {
    //             schemeId = result.args._profitShareSchemeId.toNumber();
    //             assert.equal(schemeId, 1, "Artwork Id is not equal 1");
    //         }
    //     });

    //     await instance.addProfitShareScheme(participants, profits);

    //     retval = await instance.getTotalNumberOfProfitShareSchemes();
    //     assert.equal(retval, 1);

    //     retval = await instance.getNumberOfProfitShareSchemesForOwner();
    //     assert.equal(retval, 1);

    //     schemeId = await instance.getProfitShareSchemeIdForOwner(0);
    //     assert.equal(schemeId, 1);

    //     retval = await instance.getNumberOfParticipantsForProfitShareScheme(schemeId);
    //     assert.equal(retval, participants.length);

    //     retval = await instance.getParticipantOfProfitShareScheme(schemeId, 0);
    //     assert.equal(retval[0].toUpperCase(), participants[0].toUpperCase());
    //     assert.equal(retval[1], profits[0]);

    //     retval = await instance.getParticipantOfProfitShareScheme(schemeId, 1);
    //     assert.equal(retval[0].toUpperCase(), participants[1].toUpperCase());
    //     assert.equal(retval[1], profits[1]);
    // });

    // it("14. test ArtworkToOwner functions", async () => {
    //     const key = 14;

    //     let retval = await instance.getNumberOfOwnerArtworks(web3.eth.accounts[0]);
    //     assert.equal(retval.toNumber(), 0, "getNumberOfOwnerArtworks must be empty");

    //     await instance.setArtworkToOwner(web3.eth.accounts[0], key);

    //     retval = await instance.getNumberOfOwnerArtworks(web3.eth.accounts[0]);
    //     assert.equal(retval.toNumber(), 1, "getNumberOfOwnerArtworks must return 1 element");

    //     retval = await instance.getArtworkIdOfOwner(web3.eth.accounts[0], 0);
    //     assert.equal(retval.toNumber(), key, "getArtworkIdOfOwner returned not a expected artwork id");

    //     await instance.deleteArtworkFromOwner(0);

    //     retval = await instance.getNumberOfOwnerArtworks(web3.eth.accounts[0]);
    //     assert.equal(retval.toNumber(), 0, "getNumberOfOwnerArtworks must be empty after deleting");
    // });

    // it("15. test OwnerOfArtwork functions", async () => {
    //     const artworkId = 11;
    //     const emptyOwner = '0x0000000000000000000000000000000000000000';
    //     const owner1 = '0xC04691B99EB731536E35F375ffC85249Ec713597';
    //     const owner2 = '0xB94691B99EB731536E35F375ffC85249Ec717233';

    //     let retval = await instance.getOwnerOfArtwork(artworkId);
    //     assert.equal(retval, emptyOwner);

    //     await instance.setOwnerOfArtwork(artworkId, owner1);

    //     retval = await instance.getOwnerOfArtwork(artworkId);
    //     assert.equal(retval.toUpperCase(), owner1.toUpperCase());

    //     await instance.setOwnerOfArtwork(artworkId, owner2);

    //     retval = await instance.getOwnerOfArtwork(artworkId);
    //     assert.equal(retval.toUpperCase(), owner2.toUpperCase());
    // });

    // it("16. test ArtworkToArtist functions", async () => {
    //     const artworkId = 11;
    //     const owner1 = '0xC04691B99EB731536E35F375ffC85249Ec713597';
    //     const owner2 = '0xB94691B99EB731536E35F375ffC85249Ec717233';
        
    //     let retval = await instance.getNumberOfArtistArtworks(owner1);
    //     assert.equal(retval.toNumber(), 0);
    //     retval = await instance.getNumberOfArtistArtworks(owner2);
    //     assert.equal(retval.toNumber(), 0);

    //     await instance.addArtworkToArtistList(artworkId, owner1);

    //     retval = await instance.getNumberOfArtistArtworks(owner1);
    //     assert.equal(retval.toNumber(), 1);
    //     retval = await instance.getNumberOfArtistArtworks(owner2);
    //     assert.equal(retval.toNumber(), 0);
    //     retval = await instance.getArtworkIdForArtist(owner1, 0);
    //     assert.equal(retval.toNumber(), artworkId);
    // });

    // it("17. test ArtworkHashAsInUse functions", async () => {
    //     const artworkHash = web3.sha3("ArtworkHashAsInUse");

    //     let retval = await instance.getArtworkHashAsInUse(artworkHash);
    //     assert.isFalse(retval);

    //     await instance.setArtworkHashAsInUse(artworkHash, true);

    //     retval = await instance.getArtworkHashAsInUse(artworkHash);
    //     assert.isTrue(retval);

    //     await instance.setArtworkHashAsInUse(artworkHash, false);
        
    //     retval = await instance.getArtworkHashAsInUse(artworkHash);
    //     assert.isFalse(retval);
    // });

    // it("18. test ApprovalsToOperator functions", async () => {
    //     const owner1 = '0xC04691B99EB731536E35F375ffC85249Ec713597';
    //     const owner2 = '0xB94691B99EB731536E35F375ffC85249Ec717233';

    //     let retval = await instance.getApprovalsToOperator(owner1, owner2);
    //     assert.isFalse(retval);

    //     await instance.setApprovalsToOperator(owner1, owner2, true);

    //     retval = await instance.getApprovalsToOperator(owner1, owner2);
    //     assert.isTrue(retval);

    //     await instance.setApprovalsToOperator(owner1, owner2, false);

    //     retval = await instance.getApprovalsToOperator(owner1, owner2);
    //     assert.isFalse(retval);
    // });

    // it("19. test ApprovalsToArtwork functions", async () => {
    //     const artworkId = 11;
    //     const owner = '0xC04691B99EB731536E35F375ffC85249Ec713597';

    //     let retval = await instance.getApprovalsToArtwork(owner, artworkId);
    //     assert.isFalse(retval);

    //     await instance.setApprovalsToArtwork(owner, artworkId, true);

    //     retval = await instance.getApprovalsToArtwork(owner, artworkId);
    //     assert.isTrue(retval);

    //     await instance.setApprovalsToArtwork(owner, artworkId, false);
        
    //     retval = await instance.getApprovalsToArtwork(owner, artworkId);
    //     assert.isFalse(retval);
    // });

    // it("20. test ArtworkToParticipantApproving functions", async () => {
    //     const artworkId = 11;
    //     const participant = '0xC04691B99EB731536E35F375ffC85249Ec713597';

    //     let retval = await instance.getArtworkToParticipantApproving(artworkId, participant);
    //     assert.isFalse(retval);

    //     await instance.setArtworkToParticipantApproving(artworkId, participant, true);

    //     retval = await instance.getArtworkToParticipantApproving(artworkId, participant);
    //     assert.isTrue(retval);

    //     await instance.setArtworkToParticipantApproving(artworkId, participant, false);

    //     retval = await instance.getArtworkToParticipantApproving(artworkId, participant);
    //     assert.isFalse(retval);
    // });

    // it("21. test PendingWithdrawals functions", async () => {
    //     const balance = 100500;
    //     const owner = '0xC04691B99EB731536E35F375ffC85249Ec713597';
 
    //     let retval = await instance.getPendingWithdrawals(owner);
    //     assert.equal(retval.toNumber(), 0);

    //     await instance.addPendingWithdrawals(owner, balance);

    //     retval = await instance.getPendingWithdrawals(owner);
    //     assert.equal(retval.toNumber(), 100500);

    //     await instance.subPendingWithdrawals(owner, 500);

    //     retval = await instance.getPendingWithdrawals(owner);
    //     assert.equal(retval.toNumber(), 100000);
    // });

    // it("22. test SaleTypeToArtwork functions", async () => {
    //     const artworkId = 12;
    //     const saleType = 1;

    //     let retval = await instance.getSaleTypeToArtwork(artworkId);
    //     assert.equal(retval.toNumber(), 0);

    //     await instance.setSaleTypeToArtwork(artworkId, saleType);

    //     retval = await instance.getSaleTypeToArtwork(artworkId);
    //     assert.equal(retval.toNumber(), saleType);
    // });

    // it("23 test SaleStatusToArtwork functions", async () => {
    //     const artworkId = 1;
    //     const saleStatus = 2;

    //     let retval = await instance.getSaleStatusToArtwork(artworkId);
    //     assert.equal(retval.toNumber(), 0);

    //     await instance.setSaleStatusToArtwork(artworkId, saleStatus);

    //     retval = await instance.getSaleStatusToArtwork(artworkId);
    //     assert.equal(retval.toNumber(), saleStatus);
    // });
});
