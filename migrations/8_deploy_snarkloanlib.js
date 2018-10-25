var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkLoanLib);
};