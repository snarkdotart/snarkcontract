var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkStorage = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkLoanLib);
        await deployer.link(SnarkBaseLib, SnarkLoanLib);
        const loanLib = await deployer.deploy(SnarkLoanLib);

        const storage_instance = await SnarkStorage.deployed();
        await storage_instance.allowAccess(loanLib.address);
    });
};