var SafeMath = artifacts.require("./OpenZeppelin/SafeMath.sol");
var AddressUtils = artifacts.require("./OpenZeppelin/AddressUtils.sol");
var SnarkHub = artifacts.require("./SnarkHub.sol");
var SnarkContract = artifacts.require("./SnarkBase.sol");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkContract);
    deployer.link(AddressUtils, SnarkContract);
    deployer.deploy(SnarkContract, SnarkHub.address);
    // .then(function(snark_instance) {
    //     SnarkStorage.deployed().then(function(snarkhub_instance) {
    //         snarkhub_instance.allowAccess(snark_instance.address);
    //     });
    // });
};