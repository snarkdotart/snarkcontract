var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");
var SafeMath = artifacts.require("openzeppelin/SafeMath");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkLoanLib);
        await deployer.deploy(SnarkLoanLib);
    });
};