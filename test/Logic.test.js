var SnarkBase = artifacts.require("SnarkBase");
var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkOfferBid = artifacts.require("SnarkOfferBid");

contract('Snark Logic', async (accounts) => {

    let instanceSnarkBase = null;
    let instanceSnarkLoan = null;
    let instanceSnarkOfferBid = null;

    before(async () => {
        instanceSnarkBase = await SnarkBase.deployed();
        instanceSnarkLoan = await SnarkLoan.deployed();
        instanceSnarkOfferBid = await SnarkOfferBid.deployed();
    });

    it('1. There aren\'t any tokens, bids and loans. Owner can\'t call DeleteOffer, AcceptBid, AcceptLoan, CancelLoan and freeTransfer.', async () => {
        const tokenId = 1;
        const offerId = 1;
        const bidId = 1;
        const loandId = 1;

        let result = await instanceSnarkOfferBid.getOwnerOffersCount(accounts[0]);
        assert.equal(result.toNumber(), 0, 'error on step 1');

        // DeleteOffer
        try {
            await instanceSnarkOfferBid.deleteOffer(offerId);
            throw('Error: a deleteOffer function is called');
        } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Offer id is wrong');
        }

        // AcceptBid
        try {
            await instanceSnarkOfferBid.acceptBid(bidId);
            throw('Error: an acceptBid function is called');
        } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Bid id is wrong');
        }

        // AcceptLoan
        try {
            await instanceSnarkLoan.acceptLoan([]);
            throw('Error: an acceptLoan function is called');
        } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Array of tokens can\'t be empty');
        }

        try {
            const tokenArray = [tokenId];
            await instanceSnarkLoan.acceptLoan(tokenArray);
            throw('Error: an acceptLoan function is called');
        } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Token has to be exist');
        }

        // CancelLoan
        try {} catch(e) {}

        // freeTransfer.
        try {} catch(e) {}
    });

    it("", async () => {});

    it("", async () => {});

    it("", async () => {});

    it("", async () => {});

    it("", async () => {});

});
