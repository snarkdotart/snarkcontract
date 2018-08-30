var SafeMath = artifacts.require("./OpenZeppelin/SafeMath.sol");
var AddressUtils = artifacts.require("./OpenZeppelin/AddressUtils.sol");
var SnarkHub = artifacts.require("./SnarkHub.sol");
var SnarkContract = artifacts.require("./SnarkBase.sol");
var SnarkStorage = artifacts.require("./SnarkStorage.sol");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkContract);
    deployer.link(AddressUtils, SnarkContract);
    deployer.deploy(SnarkContract, SnarkHub.address, SnarkStorage.address);
};