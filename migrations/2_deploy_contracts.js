var SnarkTrade = artifacts.require("./SnarkTrade.sol");

module.exports = function(deployer) {
    deployer.deploy(SnarkTrade);
};