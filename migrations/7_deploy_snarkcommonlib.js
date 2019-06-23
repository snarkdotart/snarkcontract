var SafeMath            = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseExtraLib   = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkBaseLib        = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkCommonLib      = artifacts.require("snarklibs/SnarkCommonLib");

var SnarkStorage        = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkCommonLib);
        await deployer.link(SnarkBaseExtraLib, SnarkCommonLib);
        await deployer.link(SnarkBaseLib, SnarkCommonLib);
        
        const commonLib = await deployer.deploy(SnarkCommonLib);
        const storage_instance = await SnarkStorage.deployed();
        await storage_instance.allowAccess(commonLib.address);
    });
};