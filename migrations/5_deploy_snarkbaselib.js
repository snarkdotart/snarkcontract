var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkBaseLib);
    deployer.link(SnarkBaseExtraLib, SnarkBaseLib);
    deployer.deploy(SnarkBaseLib);
};