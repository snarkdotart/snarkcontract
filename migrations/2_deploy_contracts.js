var SnarkArtMarket = artifacts.require("./SnarkArtMarket.sol");

module.exports = function(deployer) {
    deployer.deploy(SnarkArtMarket);
};