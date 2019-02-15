var SafeMath        = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseLib    = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkLoanLibExt = artifacts.require("snarklibs/SnarkLoanLibExt");

var SnarkStorage    = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkLoanLibExt);
        await deployer.link(SnarkBaseLib, SnarkLoanLibExt);

        const loanLibExt = await deployer.deploy(SnarkLoanLibExt);
        const storage_instance = await SnarkStorage.deployed();
        await storage_instance.allowAccess(loanLibExt.address);
    });
};