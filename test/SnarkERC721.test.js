var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkBase = artifacts.require("SnarkBase");
var SnarkStorage = artifacts.require("SnarkStorage");
var truffleAssert = require('truffle-assertions');
var BN = web3.utils.BN;

contract('SnarkERC721', async (accounts) => {

    const participants = [
        '0x6b92C59de02aD4F8E9650101E9d890298A2D5A54', 
        '0x7Af26b6056713AbB900f5dD6A6C45a38F1F70Bc5'
    ];
    const tokenOwner = accounts[0];

    before(async () => {
        instance_erc721 = await SnarkERC721.deployed();
        instance_snarkbase = await SnarkBase.deployed();
        instance_storage = await SnarkStorage.deployed();

        await web3.eth.getBalance(instance_storage.address);
        await web3.eth.sendTransaction({
            from:   accounts[0],
            to:     instance_storage.address, 
            value:  web3.utils.toWei('1', "ether")
        });

    });

    // it("size of the SnarkERC721 library", async () => {
    //     const bytecode = instance_erc721.constructor._json.bytecode;
    //     const deployed = instance_erc721.constructor._json.deployedBytecode;
    //     const sizeOfB = bytecode.length / 2;
    //     const sizeOfD = deployed.length / 2;
    //     console.log("size of bytecode in bytes = ", sizeOfB);
    //     console.log("size of deployed in bytes = ", sizeOfD);
    //     console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    // });

    it("1. test name function", async () => {
        const _name = '89 seconds Atomized';

        let retval = await instance_erc721.name();
        assert.equal(retval, _name);
    });

    it("2. test symbol function", async () => {
        const _symbol = 'SNP001';

        retval = await instance_erc721.symbol();
        assert.equal(retval, _symbol);
    });

    it("3. test tokenURL function", async () => {
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

        retval = await instance_erc721.totalSupply();
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

        retval = await instance_erc721.totalSupply();
        assert.equal(retval.toNumber(), 10, "error on step 4");

        // ------ TESTING ------

        retval = await instance_erc721.tokenURI(1);
        assert.equal(retval, decorUrl, "error on step 5");
    });

    it("4. test totalSupply function", async () => {
        retval = await instance_erc721.totalSupply();
        assert.equal(retval.toNumber(), 10);
    });

    it("5. test tokenOfOwnerByIndex function", async () => {
        retval = await instance_erc721.tokenOfOwnerByIndex(tokenOwner, 2);
        assert.equal(retval.toNumber(), 3);
    });

    it("6. test tokenByIndex function", async () => {
        retval = await instance_erc721.tokenByIndex(0);
        assert.equal(retval.toNumber(), 1);
    });

    it("7. test balanceOf function", async () => {
        retval = await instance_erc721.balanceOf(tokenOwner);
        assert.equal(retval.toNumber(), 10, "error on step 1");

        retval = await instance_erc721.balanceOf(participants[0]);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance_erc721.balanceOf(participants[1]);
        assert.equal(retval.toNumber(), 0, "error on step 3");        
    });

    it("8. test ownerOf function", async () => {
        retval = await instance_erc721.ownerOf(2);
        assert.equal(retval, tokenOwner);
    });

    it("9. test exists function", async () => {
        retval = await instance_erc721.exists(6);
        assert.isTrue(retval, "error on step 1");

        retval = await instance_erc721.exists(100);
        assert.isFalse(retval, "error on step 2");
    });

    it("10. test approve and getApproved functions", async () => {
        retval = await instance_erc721.getApproved(1);
        assert.equal(retval, 0, "error on step 1");

        const tx = await instance_erc721.approve(participants[1], 1);

        truffleAssert.eventEmitted(tx, 'Approval', (ev) => {
            return ev._owner == accounts[0] && ev._approved == participants[1] && ev._tokenId == 1;
        });

        retval = await instance_erc721.getApproved(1);
        assert.equal(retval.toUpperCase(), participants[1].toUpperCase(), "error on step 2");
    });

    it("11. test setApprovalForAll and isApprovedForAll functions", async () => {
        retval = await instance_erc721.isApprovedForAll(tokenOwner, participants[1]);
        assert.equal(retval, false, "error on step 1");

        const tx = await instance_erc721.setApprovalForAll(participants[1], true);

        truffleAssert.eventEmitted(tx, 'ApprovalForAll', (ev) => {
            return ev._owner == tokenOwner && ev._operator == participants[1] && ev._approved == true;
        });

        retval = await instance_erc721.isApprovedForAll(tokenOwner, participants[1]);
        assert.equal(retval, true, "error on step 2");
    });

    it("12. test transferFrom function", async () => {
        const _to = accounts[1];
        const _tokenId = 1;

        retval = await instance_erc721.ownerOf(_tokenId);
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

        let tx = await instance_erc721.transferFrom(tokenOwner, _to, _tokenId, { from: tokenOwner, value: _v, });

        truffleAssert.eventEmitted(tx, 'Transfer', (ev) => {
            return ev._from == tokenOwner && ev._to == _to && ev._tokenId == _tokenId;
        });

        const profit = (tokenDetail.lastPrice == 0) ? new BN(_v) : new BN(_v).mul(tokenDetail.profitShareFromSecondarySale).div(new BN(100));
        const valueOfSnark = profit.mul(snarkwalletandprofit.platformProfit).div(new BN(100));

        balanceOfSnarkWalletAfterTransfer = await web3.eth.getBalance(snarkwalletandprofit.snarkWalletAddr);
        assert.isTrue(new BN(balanceOfSnarkWalletAfterTransfer).eq(new BN(balanceOfSnarkWalletBeforeTransfer).add(valueOfSnark)), "balance of Snark isn't correct");

        for (let i = 0; i < numberParticipants; i++) {
            const participant = await instance_snarkbase.getParticipantOfProfitShareScheme(tokenDetail.profitShareSchemeId, i);
            const valueOfParticipant = profit.sub(valueOfSnark).mul(participant[1]).div(new BN(100));

            retval = await web3.eth.getBalance(participant[0]);            
            assert.equal(retval, new BN(balanceOfParticipantsBeforeTransfer[i]).add(valueOfParticipant), "balance of participant isn't correct");
        }

        retval = await instance_erc721.ownerOf(_tokenId);
        assert.equal(retval, _to, "error on step 5");
    });

    it("13. test freeTransfer function behalf of contract owner", async () => {
        const _from = accounts[1];
        const _to = accounts[2];
        const _tokenId = 1;

        retval = await instance_erc721.ownerOf(_tokenId);
        assert.equal(retval, _from, "error on step 1");

        try {
            await instance_erc721.transferFrom(_from, _to, _tokenId, { from: accounts[0] });
        } catch (e) {
            assert.equal(e.message, "Returned error: VM Exception while processing transaction: revert You have to be either token owner or be approved by owner -- Reason given: You have to be either token owner or be approved by owner.");
        }

        retval = await instance_erc721.ownerOf(_tokenId);
        assert.equal(retval, _from, "error on step 2");
    });

    it("14. freeTransfer - not owner can't call a function", async () => {
        const tokenId = 1;
        try {
            await instance_erc721.transferFrom(accounts[2], accounts[3], tokenId, { from: accounts[3] });
        } catch(err) {
            assert.equal(err.message, 'Returned error: VM Exception while processing transaction: revert You have to be either token owner or be approved by owner -- Reason given: You have to be either token owner or be approved by owner.');
        }
    });

    it("15. freeTransfer - snark can't transfer token from other wallet", async () => {
        const tokenId = 1;
        try {
            await instance_erc721.transferFrom(accounts[2], accounts[3], tokenId, { from: accounts[0] });
        } catch (e) {
            assert.equal(e.message, "Returned error: VM Exception while processing transaction: revert You have to be either token owner or be approved by owner -- Reason given: You have to be either token owner or be approved by owner.");
        }
    });
});
