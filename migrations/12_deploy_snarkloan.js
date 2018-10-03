var SafeMath = artifacts.require("../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol");
var SnarkCommonLib = artifacts.require("SnarkCommonLib");
var SnarkBaseLib = artifacts.require("SnarkBaseLib");
var SnarkLoanLib = artifacts.require("SnarkLoanLib");
var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkStorage = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkLoan);
    deployer.link(SnarkCommonLib, SnarkLoan);
    deployer.link(SnarkBaseLib, SnarkLoan);
    deployer.link(SnarkLoanLib, SnarkLoan);

    deployer.deploy(SnarkLoan, SnarkStorage.address).then(
        function(snarkLoan_instance) {
            SnarkStorage.deployed().then(
                function(storage_instance) {
                    storage_instance.allowAccess(snarkLoan_instance.address);
                }
            );
        }
    );
};