var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkCommonLib);
};