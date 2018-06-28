var SnarkStorage = artifacts.require("./SnarkStorage.sol");
var SafeMath = artifacts.require("./OpenZeppelin/SafeMath.sol");
var AddressUtils = artifacts.require("./OpenZeppelin/AddressUtils.sol");

module.exports = function(deployer) {
    deployer.deploy(SafeMath);
    deployer.deploy(AddressUtils);
    deployer.deploy(SnarkStorage);
};