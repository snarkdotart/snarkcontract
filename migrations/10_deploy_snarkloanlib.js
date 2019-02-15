var SafeMath        = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseLib    = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkLoanLib    = artifacts.require("snarklibs/SnarkLoanLib");
var SnarkLoanLibExt = artifacts.require("snarklibs/SnarkLoanLibExt");

var SnarkStorage    = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkLoanLib);
        await deployer.link(SnarkBaseLib, SnarkLoanLib);
        await deployer.link(SnarkLoanLibExt, SnarkLoanLib);

        const loanLib = await deployer.deploy(SnarkLoanLib);
        const storage_instance = await SnarkStorage.deployed();
        await storage_instance.allowAccess(loanLib.address);
    });
};