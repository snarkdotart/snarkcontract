var SnarkArt = artifacts.require("./SnarkArt.sol");

module.exports = function(deployer) {
    deployer.deploy(SnarkArt);
};