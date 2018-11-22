var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkBaseExtraLib);
        await deployer.deploy(SnarkBaseExtraLib);
    });
};