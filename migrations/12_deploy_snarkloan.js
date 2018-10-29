var SafeMath = artifacts.require("openzeppelin/SafeMath.sol");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");
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
                    snarkLoan_instance.setDefaultLoanDuration(30);
                }
            );
        }
    );
};