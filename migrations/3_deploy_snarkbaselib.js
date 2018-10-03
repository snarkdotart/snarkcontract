var SnarkBaseLib = artifacts.require("SnarkBaseLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkBaseLib);
};