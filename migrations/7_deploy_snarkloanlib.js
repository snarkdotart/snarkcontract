var SnarkLoanLib = artifacts.require("SnarkLoanLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkLoanLib);
};