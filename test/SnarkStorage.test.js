var SnarkStorage = artifacts.require("SnarkStorage");

contract('SnarkStorage', async (accounts) => {

    let instance = null;
    const variableName = "testvariable";

    before(async () => {
        instance = await SnarkStorage.deployed();
    });

    it("get size of the SnarkStorage contract", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("test arrayNameToItemsCount functions", async () => {
        let cnt = await instance.getArrayNameToItemsCount(variableName);
        assert.equal(cnt, 0);

        await instance.increaseArrayNameToItemsCount(variableName);
        cnt = await instance.getArrayNameToItemsCount(variableName);
        assert.equal(cnt, 1);
    });

    it("test storageBytes32ToBool functions", async () => {
        const key = 0x123456789;

        let cnt = await instance.getStorageBytes32ToBool(variableName, key);
        assert.isFalse(cnt);

        await instance.setStorageBytes32ToBool(variableName, key, true);

        cnt = await instance.getStorageBytes32ToBool(variableName, key);
        assert.isTrue(cnt);
    });

    it("test storageUint8ToUint256Array functions", async () => {
        const key = 5;
        let val = 7;
        
        let cnt = await instance.getStorageUint8ToUint256ArrayLength(variableName, key);
        assert.equal(cnt, 0);

        await instance.addStorageUint8ToUint256Array(variableName, key, val);
        cnt = await instance.getStorageUint8ToUint256ArrayLength(variableName, key);
        assert.equal(cnt, 1);

        await instance.addStorageUint8ToUint256Array(variableName, key, val + 1);
        cnt = await instance.getStorageUint8ToUint256ArrayLength(variableName, key);
        assert.equal(cnt, 2);

        cnt = await instance.getStorageUint8ToUint256Array(variableName, key, 0);
        assert.equal(cnt, val);

        cnt = await instance.getStorageUint8ToUint256Array(variableName, key, 1);
        assert.equal(cnt, val + 1);

        await instance.setStorageUint8ToUint256Array(variableName, key, 1, val + 9);
        cnt = await instance.getStorageUint8ToUint256Array(variableName, key, 1);
        assert.equal(cnt, val + 9);

        await instance.deleteStorageUint8ToUint256Array(variableName, key, 0);
        cnt = await instance.getStorageUint8ToUint256ArrayLength(variableName, key);
        assert.equal(cnt, 1);

        cnt = await instance.getStorageUint8ToUint256Array(variableName, key, 0);
        assert.equal(cnt, val + 9);
    });

    it("test storageUint256ToBytes32Array functions", async () => {
        const key = 5;
        const val1 = 0x123;
        const val2 = 0x987;

        let cnt = await instance.getStorageUint256ToBytes32ArrayLength(variableName, key);
        assert.equal(cnt, 0);

        await instance.addStorageUint256ToBytes32Array(variableName, key, val1);
        await instance.addStorageUint256ToBytes32Array(variableName, key, val2);

        cnt = await instance.getStorageUint256ToBytes32ArrayLength(variableName, key);
        assert.equal(cnt, 2);

        cnt = await instance.getStorageUint256ToBytes32Array(variableName, key, 0);
        cnt = cutZeros(cnt);
        assert.equal(web3.fromDecimal(cnt), web3.fromDecimal(val1));

        cnt = await instance.getStorageUint256ToBytes32Array(variableName, key, 1);
        cnt = cutZeros(cnt);
        assert.equal(web3.fromDecimal(cnt), web3.fromDecimal(val2));

        await instance.setStorageUint256ToBytes32Array(variableName, key, 0, val2);
        cnt = await instance.getStorageUint256ToBytes32Array(variableName, key, 0);
        cnt = cutZeros(cnt);
        assert.equal(web3.fromDecimal(cnt), web3.fromDecimal(val2));

        await instance.deleteStorageUint256ToBytes32Array(variableName, key, 0);
        cnt = await instance.getStorageUint256ToBytes32ArrayLength(variableName, key);
        assert.equal(cnt, 1);

        cnt = await instance.getStorageUint256ToBytes32Array(variableName, key, 0);
        cnt = cutZeros(cnt);
        assert.equal(web3.fromDecimal(cnt), web3.fromDecimal(val2));
    });

    function cutZeros(str) {
        var indexFrom = str.length;
        for (var i = str.length - 1; i > 0; i--) {
            if (str[i] == "0") indexFrom = i;
            else break;
        }
        str = str.substr(0, indexFrom);
        return str;
    }

    it("test storageUint256ToUint8Array functions", async () => {
        const key = 2;

        let cnt = await instance.getStorageUint256ToUint8ArrayLength(variableName, key);
        assert(cnt, 0);

        await instance.addStorageUint256ToUint8Array(variableName, key, 4);
        await instance.addStorageUint256ToUint8Array(variableName, key, 6);

        cnt = await instance.getStorageUint256ToUint8ArrayLength(variableName, key);
        assert(cnt, 2);

        await instance.setStorageUint256ToUint8Array(variableName, key, 1, 9);
        cnt = await instance.getStorageUint256ToUint8Array(variableName, key, 1);
        assert(cnt, 9);

        await instance.deleteStorageUint256ToUint8Array(variableName, key, 1);
        cnt = await instance.getStorageUint256ToUint8ArrayLength(variableName, key);
        assert(cnt, 1);

        cnt = await instance.getStorageUint256ToUint8Array(variableName, key, 0);
        assert(cnt, 4);
    });

    it("test storageUint256ToUint16Array functions", async () => {
        const key = 2;

        let cnt = await instance.getStorageUint256ToUint16ArrayLength(variableName, key);
        assert(cnt, 0);

        await instance.addStorageUint256ToUint16Array(variableName, key, 4);
        await instance.addStorageUint256ToUint16Array(variableName, key, 6);

        cnt = await instance.getStorageUint256ToUint16ArrayLength(variableName, key);
        assert(cnt, 2);

        await instance.setStorageUint256ToUint16Array(variableName, key, 1, 9);
        cnt = await instance.getStorageUint256ToUint16Array(variableName, key, 1);
        assert(cnt, 9);

        await instance.deleteStorageUint256ToUint16Array(variableName, key, 1);
        cnt = await instance.getStorageUint256ToUint16ArrayLength(variableName, key);
        assert(cnt, 1);

        cnt = await instance.getStorageUint256ToUint16Array(variableName, key, 0);
        assert(cnt, 4);
    });

    it("test storageUint256ToUint64Array functions", async () => {
        const key = 2;

        let cnt = await instance.getStorageUint256ToUint64ArrayLength(variableName, key);
        assert(cnt, 0);

        await instance.addStorageUint256ToUint64Array(variableName, key, 4);
        await instance.addStorageUint256ToUint64Array(variableName, key, 6);

        cnt = await instance.getStorageUint256ToUint64ArrayLength(variableName, key);
        assert(cnt, 2);

        await instance.setStorageUint256ToUint64Array(variableName, key, 1, 9);
        cnt = await instance.getStorageUint256ToUint64Array(variableName, key, 1);
        assert(cnt, 9);

        await instance.deleteStorageUint256ToUint64Array(variableName, key, 1);
        cnt = await instance.getStorageUint256ToUint64ArrayLength(variableName, key);
        assert(cnt, 1);

        cnt = await instance.getStorageUint256ToUint64Array(variableName, key, 0);
        assert(cnt, 4);
    });

    it("test storageUint256ToUint256Array functions", async () => {
        const key = 2;

        let cnt = await instance.getStorageUint256ToUint256ArrayLength(variableName, key);
        assert(cnt, 0);

        await instance.addStorageUint256ToUint256Array(variableName, key, 4);
        await instance.addStorageUint256ToUint256Array(variableName, key, 6);

        cnt = await instance.getStorageUint256ToUint256ArrayLength(variableName, key);
        assert(cnt, 2);

        await instance.setStorageUint256ToUint256Array(variableName, key, 1, 9);
        cnt = await instance.getStorageUint256ToUint256Array(variableName, key, 1);
        assert(cnt, 9);

        await instance.deleteStorageUint256ToUint256Array(variableName, key, 1);
        cnt = await instance.getStorageUint256ToUint256ArrayLength(variableName, key);
        assert(cnt, 1);

        cnt = await instance.getStorageUint256ToUint256Array(variableName, key, 0);
        assert(cnt, 4);
    });

    it("test storageUint256ToAddressArray functions", async () => {
        const key = 3;
        const val1 = '0xC04691B99EB731536E35F375ffC85249Ec713597';
        const val2 = '0xC04691B99EB731536E35F375ffC85249Ec713733';

        let cnt = await instance.getStorageUint256ToAddressArrayLength(variableName, key);
        assert(cnt, 0);

        await instance.addStorageUint256ToAddressArray(variableName, key, val1);
        await instance.addStorageUint256ToAddressArray(variableName, key, val2);

        cnt = await instance.getStorageUint256ToAddressArrayLength(variableName, key);
        assert(cnt, 2);

        await instance.setStorageUint256ToAddressArray(variableName, key, 1, val1);
        cnt = await instance.getStorageUint256ToAddressArray(variableName, key, 1);
        assert(cnt, val1);

        await instance.deleteStorageUint256ToAddressArray(variableName, key, 1);
        cnt = await instance.getStorageUint256ToAddressArrayLength(variableName, key);
        assert(cnt, val1);

        cnt = await instance.getStorageUint256ToAddressArray(variableName, key, 0);
        assert(cnt, val1);
    });

    it("test storageUint256ToString functions", async () => {
        const key = 2;
        const val1 = "test1";
        const val2 = "test2";

        let cnt = await instance.getStorageUint256ToString(variableName, key);
        assert.equal(cnt, "");

        await instance.setStorageUint256ToString(variableName, key, val1);
        cnt = await instance.getStorageUint256ToString(variableName, key);
        assert.equal(cnt, val1);

        await instance.setStorageUint256ToString(variableName, key, val2);
        cnt = await instance.getStorageUint256ToString(variableName, key);
        assert.equal(cnt, val2);

        await instance.deleteStorageUint256ToString(variableName, key);
        cnt = await instance.getStorageUint256ToString(variableName, key);
        assert.equal(cnt, "");
    });

    it("test storageAddressToAddressArray functions", async () => {
        const key = '0xc04691b99eb731536e35f375ffc85249ec713597';
        const val1 = "0xc05691b99eb731536e35f375ffc85249ec713756";
        const val2 = "0xc09991b99eb731536e35f375ffc85249ec711234";

        let cnt = await instance.getStorageAddressToAddressArrayLength(variableName, key);
        assert.equal(cnt, 0);

        await instance.addStorageAddressToAddressArray(variableName, key, val1);
        await instance.addStorageAddressToAddressArray(variableName, key, val2);

        cnt = await instance.getStorageAddressToAddressArrayLength(variableName, key);
        assert.equal(cnt, 2);

        await instance.setStorageAddressToAddressArray(variableName, key, 1, val1);
        cnt = await instance.getStorageAddressToAddressArray(variableName, key, 1);
        assert.equal(cnt, val1);

        await instance.deleteStorageAddressToAddressArray(variableName, key, 1);
        cnt = await instance.getStorageAddressToAddressArrayLength(variableName, key);
        assert.equal(cnt, 1);
    });

    it("test storageAddressToUint256Array functions", async () => {
        const key = '0xc04691b99eb731536e35f375ffc85249ec713597';
        let val = 7;
        
        let cnt = await instance.getStorageAddressToUint256ArrayLength(variableName, key);
        assert.equal(cnt, 0);

        await instance.addStorageAddressToUint256Array(variableName, key, val);
        await instance.addStorageAddressToUint256Array(variableName, key, val + 1);
        cnt = await instance.getStorageAddressToUint256ArrayLength(variableName, key);
        assert.equal(cnt, 2);

        await instance.setStorageAddressToUint256Array(variableName, key, 1, val + 3);

        cnt = await instance.getStorageAddressToUint256Array(variableName, key, 0);
        assert.equal(cnt, val);

        cnt = await instance.getStorageAddressToUint256Array(variableName, key, 1);
        assert.equal(cnt, val + 3);

        await instance.deleteStorageAddressToUint256Array(variableName, key, 0);
        cnt = await instance.getStorageAddressToUint256ArrayLength(variableName, key);
        assert.equal(cnt, 1);

        cnt = await instance.getStorageAddressToUint256Array(variableName, key, 0);
        assert.equal(cnt, val + 3);
    });

    it("test storageAddressToBool functions", async () => {
        const key = '0xc04691b99eb731536e35f375ffc85249ec713597';

        let cnt = await instance.getStorageAddressToBool(variableName, key);
        assert.equal(cnt, false);

        await instance.setStorageAddressToBool(variableName, key, true);
        cnt = await instance.getStorageAddressToBool(variableName, key);
        assert.equal(cnt, true);
    });

    it("test tokenToParticipantApprovingMap functions", async () => {});

});
