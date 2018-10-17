var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkBaseLib);
    deployer.deploy(SnarkBaseLib);
};