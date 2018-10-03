var SafeMath = artifacts.require("openzeppelin/SafeMath.sol");

module.exports = function(deployer) {
    deployer.deploy(SafeMath);
};