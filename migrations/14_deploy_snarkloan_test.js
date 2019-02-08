var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");
var SnarkLoanTest = artifacts.require("SnarkLoanTest");
var SnarkStorage = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        const storage_instance = await SnarkStorage.deployed();
        await deployer.link(SnarkLoanLib, SnarkLoanTest);
        await deployer.deploy(SnarkLoanTest, storage_instance.address);
        const snarkLoanTest_instance = await SnarkLoanTest.deployed();
        await storage_instance.allowAccess(snarkLoanTest_instance.address);
    });
};