var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkBaseLib);
};