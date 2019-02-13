const BigNumber = require('bignumber.js');

var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkBase = artifacts.require("SnarkBase");
var SnarkStorage = artifacts.require("SnarkStorage");

contract('SnarkERC721', async (accounts) => {

    let instance = null;
    const participants = [
        '0x6b92C59de02aD4F8E9650101E9d890298A2D5A54', 
        '0x7Af26b6056713AbB900f5dD6A6C45a38F1F70Bc5'
    ];
    const tokenOwner = accounts[0];

    before(async () => {
        instance = await SnarkERC721.deployed();
        instance_snarkbase = await SnarkBase.deployed();
        instance_storage = await SnarkStorage.deployed();

        await web3.eth.getBalance(instance_storage.address);
        await web3.eth.sendTransaction({
            from:   accounts[0],
            to:     instance_storage.address, 
            value:  web3.utils.toWei('1', "ether")
        });
    });

    it("1. get size of the SnarkERC721 library", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("2. test name function", async () => {
        const _name = '89 seconds Atomized';

        let retval = await instance.name();
        assert.equal(retval, _name);
    });

    it("3. test symbol function", async () => {
        const _symbol = 'SNP001';

        retval = await instance.symbol();
        assert.equal(retval, _symbol);
    });

    it("4. test tokenURL function", async () => {
        // ------ PREPARING FOR TEST ------

        // add profit share scheme
        const profits = [ 20, 80 ];

        let retval = await instance_snarkbase.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 0, "error on step 1");

        await instance_snarkbase.createProfitShareScheme(accounts[0], participants, profits);

        retval = await instance_snarkbase.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1, "error on step 2");

        // add a number of new tokens
        const tokenHash = web3.utils.sha3("tokenHash");
        const limitedEdition = 10;
        const profitShareFromSecondarySale = 20;
        // const tokenUrl = "http://snark.art";
        const tokenUrl = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7Eni";
        const decorUrl = 'ipfs://decorator.io';
        const profitShareSchemeId = 1;

        retval = await instance_snarkbase.getTokensCount();
        assert.equal(retval.toNumber(), 0, "error on step 3");

        await instance_snarkbase.addToken(
            accounts[0],
            tokenHash,
            tokenUrl,
            decorUrl,
            'bla-blaa-blaaa',
            [
                limitedEdition,
                profitShareFromSecondarySale,
                profitShareSchemeId
            ],
            [true, true]
        );

        retval = await instance_snarkbase.getTokensCount();
        assert.equal(retval.toNumber(), 10, "error on step 4");

        // ------ TESTING ------

        retval = await instance.tokenURI(1);
        assert.equal(retval, decorUrl, "error on step 5");
    });

    it("5. test totalSupply function", async () => {
        retval = await instance.totalSupply();
        assert.equal(retval.toNumber(), 10);
    });

    it("6. test tokenOfOwnerByIndex function", async () => {
        retval = await instance.tokenOfOwnerByIndex(tokenOwner, 2);
        assert.equal(retval.toNumber(), 3);
    });

    it("7. test tokenByIndex function", async () => {
        retval = await instance.tokenByIndex(0);
        assert.equal(retval.toNumber(), 1);
    });

    it("8. test balanceOf function", async () => {
        retval = await instance.balanceOf(tokenOwner);
        assert.equal(retval.toNumber(), 10, "error on step 1");

        retval = await instance.balanceOf(participants[0]);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.balanceOf(participants[1]);
        assert.equal(retval.toNumber(), 0, "error on step 3");        
    });

    it("9. test ownerOf function", async () => {
        retval = await instance.ownerOf(2);
        assert.equal(retval, tokenOwner);
    });

    it("10. test exists function", async () => {
        retval = await instance.exists(6);
        assert.isTrue(retval, "error on step 1");

        retval = await instance.exists(100);
        assert.isFalse(retval, "error on step 2");
    });

    it("11. test approve and getApproved functions", async () => {
        retval = await instance.getApproved(1);
        assert.equal(retval, 0, "error on step 1");

        await instance.approve(participants[1], 1);

        retval = await instance.getApproved(1);
        assert.equal(retval.toUpperCase(), participants[1].toUpperCase(), "error on step 2");
    });

    it("12. test setApprovalForAll and isApprovedForAll functions", async () => {
        retval = await instance.isApprovedForAll(tokenOwner, participants[1]);
        assert.equal(retval, false, "error on step 1");

        await instance.setApprovalForAll(participants[1], true);

        retval = await instance.isApprovedForAll(tokenOwner, participants[1]);
        assert.equal(retval, true, "error on step 2");
    });

    it("13. test transferFrom function", async () => {
        const _to = accounts[1];
        const _tokenId = 1;

        retval = await instance_snarkbase.getOwnerOfToken(_tokenId);
        assert.equal(retval, tokenOwner, "error on step 1");

        const _v = web3.utils.toWei('1', 'Ether');
        const tokenDetail = await instance_snarkbase.getTokenDetail(_tokenId);
        
        await instance_snarkbase.setSnarkWalletAddress(accounts[5]);

        const snarkwalletandprofit = await instance_snarkbase.getSnarkWalletAddressAndProfit();

        const numberParticipants = await instance_snarkbase.getNumberOfParticipantsForProfitShareScheme(tokenDetail.profitShareSchemeId);
        const balanceOfParticipantsBeforeTransfer = [];
        for (let i = 0; i < numberParticipants; i++) {
            const participant = await instance_snarkbase.getParticipantOfProfitShareScheme(tokenDetail.profitShareSchemeId, i);
            retval = await web3.eth.getBalance(participant[0]);
            balanceOfParticipantsBeforeTransfer.push(retval);
        }
        
        balanceOfSnarkWalletBeforeTransfer = await web3.eth.getBalance(snarkwalletandprofit.snarkWalletAddr);
        balanceOfTokenOwnerBeforeTransfer = await web3.eth.getBalance(tokenOwner);
        balanceOfTokenReceiverBeforeTransfer = await web3.eth.getBalance(_to);

        await instance.transferFrom(
            tokenOwner, 
            _to, 
            _tokenId, 
            { 
                from: tokenOwner, 
                value: _v, 
            }
        );

        const profit = (tokenDetail.lastPrice == 0) ? new BigNumber(_v) : new BigNumber(_v).multipliedBy(tokenDetail.profitShareFromSecondarySale).dividedBy(100);

        // процент снарку составляет
        const valueOfSnark = profit.multipliedBy(snarkwalletandprofit.platformProfit).dividedBy(100);

        balanceOfSnarkWalletAfterTransfer = await web3.eth.getBalance(snarkwalletandprofit.snarkWalletAddr);
        assert.equal(balanceOfSnarkWalletAfterTransfer, new BigNumber(balanceOfSnarkWalletBeforeTransfer).plus(valueOfSnark).toNumber(), "balance of Snark isn't correct");

        for (let i = 0; i < numberParticipants; i++) {
            const participant = await instance_snarkbase.getParticipantOfProfitShareScheme(tokenDetail.profitShareSchemeId, i);
            const valueOfParticipant = profit.minus(valueOfSnark).multipliedBy(participant[1]).dividedBy(100);

            retval = await web3.eth.getBalance(participant[0]);            
            assert.equal(retval, new BigNumber(balanceOfParticipantsBeforeTransfer[i]).plus(valueOfParticipant), "balance of participant isn't correct");
        }

        retval = await instance_snarkbase.getOwnerOfToken(_tokenId);
        assert.equal(retval, _to, "error on step 5");
    });

    it("14. test freeTransfer function behalf of contract owner", async () => {
        const _from = accounts[1];
        const _to = accounts[2];
        const _tokenId = 1;

        retval = await instance_snarkbase.getOwnerOfToken(_tokenId);
        assert.equal(retval, _from, "error on step 1");

        await instance.transferFrom(_from, _to, _tokenId, { from: accounts[0] });

        retval = await instance_snarkbase.getOwnerOfToken(_tokenId);
        assert.equal(retval, _to, "error on step 2");
    });

    it('15. freeTransfer - not owner can\'t call a function', async () => {
        const tokenId = 1;
        try {
            await instance.transferFrom(accounts[2], accounts[3], tokenId, { from: accounts[3] });
        } catch(err) {
            assert.equal(err.message, 'Returned error: VM Exception while processing transaction: revert You have to be either token owner or be approved by owner -- Reason given: You have to be either token owner or be approved by owner.');
        }
    });

    it('16. freeTransfer - snark can transfer token from other wallet', async () => {
        const tokenId = 1;
        await instance.transferFrom(accounts[2], accounts[3], tokenId, { from: accounts[0] });
    });
});
