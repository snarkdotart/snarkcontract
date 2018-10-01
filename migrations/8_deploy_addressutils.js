var AddressUtils = artifacts.require("../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol");

module.exports = function(deployer) {
    deployer.deploy(AddressUtils);
};