var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkCommonLib);
        await deployer.link(SnarkBaseLib, SnarkCommonLib);
        await deployer.link(SnarkBaseExtraLib, SnarkCommonLib);
        await deployer.deploy(SnarkCommonLib);
    });
};