var SnarkCommonLib = artifacts.require("SnarkCommonLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkCommonLib);
};