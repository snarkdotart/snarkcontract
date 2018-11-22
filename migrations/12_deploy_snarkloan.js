var SafeMath = artifacts.require("openzeppelin/SafeMath.sol");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");
var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkStorage = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        let storage_instance = await SnarkStorage.deployed();
        await deployer.link(SafeMath, SnarkLoan);
        await deployer.link(SnarkCommonLib, SnarkLoan);
        await deployer.link(SnarkBaseLib, SnarkLoan);
        await deployer.link(SnarkLoanLib, SnarkLoan);
        await deployer.deploy(SnarkLoan, storage_instance.address);
        let snarkLoan_instance = await SnarkLoan.deployed();
        await storage_instance.allowAccess(snarkLoan_instance.address);
        await snarkLoan_instance.setDefaultLoanDuration(30);
    });
};