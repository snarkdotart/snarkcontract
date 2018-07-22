var SafeMath = artifacts.require("./OpenZeppelin/SafeMath.sol");
var AddressUtils = artifacts.require("./OpenZeppelin/AddressUtils.sol");
var SnarkStorage = artifacts.require("./SnarkStorage.sol");
var SnarkContract = artifacts.require("./SnarkBase.sol");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkContract);
    deployer.link(AddressUtils, SnarkContract);

    deployer.deploy(SnarkContract, SnarkStorage.address)
    .then(function(snarkbase_instance) {
        SnarkStorage.deployed().then(function(snarkstorage_instance) {
            snarkstorage_instance.allowAccess(snarkbase_instance.address);
        });
    });
};