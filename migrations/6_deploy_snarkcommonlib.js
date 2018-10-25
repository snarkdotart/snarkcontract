var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkCommonLib);
    deployer.link(SnarkBaseLib, SnarkCommonLib);
    deployer.link(SnarkBaseExtraLib, SnarkCommonLib);
    deployer.deploy(SnarkCommonLib);
};