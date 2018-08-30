var SnarkStorage = artifacts.require("SnarkStorage");

contract('SnarkStorage', async (accounts) => {

    let instance = null;
    const variableName = "testvariable";

    before(async () => {
        instance = await SnarkStorage.deployed();
    });

    it("1. get size of the SnarkStorage contract", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("2. test of boolStorage functions", async () => {
        const key = web3.sha3(variableName, '0xC04691B99EB731536E35F375ffC85249Ec713597');

        let result = await instance.getBool(key);
        assert.isFalse(result);

        await instance.setBool(key, true);

        result = await instance.getBool(key);
        assert.isTrue(result);

        await instance.deleteBool(key);

        result = await instance.getBool(key);
        assert.isFalse(result);
    });

    it("3. test of stringStorage functions", async () => {
        const key = web3.sha3(variableName, '2');
        const val = 'ku-ku';

        let result = await instance.getString(key);
        assert.isEmpty(result);

        await instance.setString(key, val);
        result = await instance.getString(key);
        assert.equal(result, val);

        await instance.deleteString(key);
        result = await instance.getString(key);
        assert.isEmpty(result);
    });

    it("4. test of addressStorage functions", async () => {
        const key = web3.sha3(variableName, '2');
        const val = '0xC04691B99EB731536E35F375ffC85249Ec713597';

        let result = await instance.getAddress(key);
        assert.equal(result, 0);

        await instance.setAddress(key, val);
        result = await instance.getAddress(key);
        assert.equal(result.toUpperCase(), val.toUpperCase());

        await instance.deleteAddress(key);
        result = await instance.getAddress(key);
        assert.equal(result, 0);
    });

    it("5. test of uintStorage functions", async () => {
        const key = web3.sha3(variableName, '2');
        const val = 245;

        let result = await instance.getUint(key);
        assert.equal(result, 0);

        await instance.setUint(key, val);
        result = await instance.getUint(key);
        assert.equal(result, val);

        await instance.deleteUint(key);
        result = await instance.getUint(key);
        assert.equal(result, 0);
    });

    it("6. test of bytesStorage functions", async () => {
        const key = web3.sha3(variableName, '2');
        const val = web3.sha3("newkey");

        let result = await instance.getBytes(key);
        assert.equal(result, 0);

        await instance.setBytes(key, val);
        result = await instance.getBytes(key);
        assert.equal(result, val);

        await instance.deleteBytes(key);
        result = await instance.getBytes(key);
        assert.equal(result, 0);
    });

});
