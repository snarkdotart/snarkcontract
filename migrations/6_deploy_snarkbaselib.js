var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkBaseLib);
        await deployer.link(SnarkBaseExtraLib, SnarkBaseLib);
        await deployer.deploy(SnarkBaseLib);
    });
};