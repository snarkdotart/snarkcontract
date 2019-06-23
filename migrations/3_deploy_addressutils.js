var AddressUtils = artifacts.require("openzeppelin/AddressUtils.sol");

module.exports = function(deployer) {
    deployer.deploy(AddressUtils);
};