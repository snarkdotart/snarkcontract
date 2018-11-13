var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");
var SafeMath = artifacts.require("openzeppelin/SafeMath");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkLoanLib);
    deployer.deploy(SnarkLoanLib);
};