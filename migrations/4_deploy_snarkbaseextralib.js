var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkBaseExtraLib);
    deployer.deploy(SnarkBaseExtraLib);
};