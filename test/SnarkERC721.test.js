var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkBase = artifacts.require("SnarkBase");

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
        const _name = 'Snark Art Token';

        let retval = await instance.name();
        assert.equal(retval, _name);
    });

    it("3. test symbol function", async () => {
        const _symbol = 'SAT';

        retval = await instance.symbol();
        assert.equal(retval, _symbol);
    });

    it("4. test tokenURL function", async () => {
        // ------ PREPARING FOR TEST ------

        // add profit share scheme
        const profits = [ 20, 80 ];

        let retval = await instance_snarkbase.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 0, "error on step 1");

        await instance_snarkbase.createProfitShareScheme(participants, profits);

        retval = await instance_snarkbase.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1, "error on step 2");

        // add a number of new tokens
        const tokenHash = web3.sha3("tokenHash");
        const limitedEdition = 10;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "http://snark.art";
        const profitShareSchemeId = 1;

        retval = await instance_snarkbase.getTokensCount();
        assert.equal(retval.toNumber(), 0, "error on step 3");

        await instance_snarkbase.addToken(
            tokenHash,
            limitedEdition,
            profitShareFromSecondarySale,
            tokenUrl,
            profitShareSchemeId,
            true,
            true
        );

        retval = await instance_snarkbase.getTokensCount();
        assert.equal(retval.toNumber(), 10, "error on step 4");

        // ------ TESTING ------

        retval = await instance.tokenURI(1);
        assert.equal(retval, tokenUrl, "error on step 5");
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
        assert.isFalse(retval, "error on step 1");

        await instance.setApprovalForAll(participants[1], true);

        retval = await instance.isApprovedForAll(tokenOwner, participants[1]);
        assert.isTrue(retval, "error on step 2");
    });

    it("13. test transferFrom function", async () => {
        const _to = accounts[1];
        const _tokenId = 1;

        retval = await instance_snarkbase.getOwnerOfToken(_tokenId);
        assert.equal(retval, tokenOwner, "error on step 1");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance_snarkbase.getWithdrawBalance(participants[0]);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance_snarkbase.getWithdrawBalance(participants[1]);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        await instance.transferFrom(tokenOwner, _to, _tokenId, { value: 10 });

        retval = await instance_snarkbase.getOwnerOfToken(_tokenId);
        assert.equal(retval, _to, "error on step 5");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), 10, "error on step 6");

        retval = await instance_snarkbase.getWithdrawBalance(participants[0]);
        assert.equal(retval.toNumber(), 0, "error on step 7");

        retval = await instance_snarkbase.getWithdrawBalance(participants[1]);
        assert.equal(retval.toNumber(), 0, "error on step 8");
    });
});
