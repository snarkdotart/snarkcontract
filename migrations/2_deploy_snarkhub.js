var SnarkHub = artifacts.require("./SnarkHub.sol");

module.exports = function(deployer) {
    deployer.deploy(SnarkHub);
};