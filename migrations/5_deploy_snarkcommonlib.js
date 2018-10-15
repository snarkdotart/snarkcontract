var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkCommonLib);
    deployer.link(SnarkBaseLib, SnarkCommonLib);
    deployer.deploy(SnarkCommonLib);
};