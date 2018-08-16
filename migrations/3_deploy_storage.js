var SnarkStorage = artifacts.require("./SnarkStorage.sol");
var SafeMath = artifacts.require("./OpenZeppelin/SafeMath.sol");
var AddressUtils = artifacts.require("./OpenZeppelin/AddressUtils.sol");
var SnarkHub = artifacts.require("./SnarkHub.sol");

module.exports = function(deployer) {
    deployer.deploy(SafeMath);
    deployer.deploy(AddressUtils);
    deployer.deploy(SnarkStorage, SnarkHub.address);
    // .then(function(snarkstorage_instance) {
    //     SnarkStorage.deployed().then(function(snarkhub_instance) {
    //         snarkhub_instance.allowAccess(snark_instance.address);
    //     });
    // });
};