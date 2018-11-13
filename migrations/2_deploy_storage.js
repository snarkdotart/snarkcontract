var SnarkStorage = artifacts.require("SnarkStorage.sol");

module.exports = function(deployer) {
    deployer.deploy(SnarkStorage);
};