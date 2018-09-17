var SafeMath = artifacts.require("../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol");

module.exports = function(deployer) {
    deployer.deploy(SafeMath);
};