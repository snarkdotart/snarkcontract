var SafeMath = artifacts.require("./OpenZeppelin/SafeMath.sol");
var AddressUtils = artifacts.require("./OpenZeppelin/AddressUtils.sol");
var SnarkBase = artifacts.require("./SnarkBase.sol");
var SnarkStorage = artifacts.require("./SnarkStorage.sol");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkBase);
    deployer.link(AddressUtils, SnarkBase);

    deployer.deploy(SnarkBase, SnarkStorage.address)
    .then(function(snarkbase_instance) {
        SnarkStorage.deployed().then(function(snarkstorage_instance) {
            snarkstorage_instance.allowAccess(snarkbase_instance.address);
        });
    });
};