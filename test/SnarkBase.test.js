var SnarkBase = artifacts.require("SnarkBase");

contract('SnarkBase', async (accounts) => {

    it("get the size of the SnarkBase contract", async () => {
        let instance = await SnarkBase.deployed();
        let bytecode = instance.constructor._json.bytecode;
        let deployed = instance.constructor._json.deployedBytecode;
        let sizeOfB = bytecode.length / 2;
        let sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("test default value of platform profit share", async () => {
        let instance = await SnarkBase.deployed();
        let value = await instance.platformProfitShare.call();
        assert.equal(value.toNumber(), 5);
    });

    it("test changing of platform profit share value", async () => {
        let instance = await SnarkBase.deployed();
        await instance.setPlatformProfitShare(34);
        let value = await instance.platformProfitShare.call();
        assert.equal(value.toNumber(), 34);
    });

    it("test createProfitShareScheme function", async () => {
        let instance = await SnarkBase.deployed();
        const addresses = [accounts[1], accounts[2]];
        const percents = [60, 40];

        let result = await instance.getProfitShareSchemesTotalAmount.call();
        assert.equal(result.toNumber(), 0, "Array of profits is not empty")

        const event = instance.ProfitShareSchemeAdded({ fromBlock: 0, toBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                // let val_from = result.args._schemeOwner;
                let val_schemeId = result.args._profitShareSchemeId.toNumber();
                assert.equal(val_schemeId, 0, "ProfitShare Id is not equal 0");
            }
        });

        await instance.createProfitShareScheme(addresses, percents);

        result = await instance.getProfitShareSchemesTotalAmount.call();
        assert.equal(result.toNumber(), 1, "Array of profits has a wrong length")
    });

    // it("test prop profit share from secondary sale function", async () => {
    // });
});
