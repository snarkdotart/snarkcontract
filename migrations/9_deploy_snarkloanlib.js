var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SafeMath = artifacts.require("openzeppelin/SafeMath");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkLoanLib);
        await deployer.link(SnarkBaseLib, SnarkLoanLib);
        await deployer.deploy(SnarkLoanLib);
    });
};