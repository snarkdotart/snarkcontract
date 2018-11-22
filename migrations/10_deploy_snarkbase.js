var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkBase = artifacts.require("SnarkBase");

module.exports = function(deployer) {
    deployer.then(async () => {
        let storage_instance = await SnarkStorage.deployed();
        await deployer.link(SnarkCommonLib, SnarkBase);
        await deployer.link(SnarkBaseExtraLib, SnarkBase);
        await deployer.link(SnarkBaseLib, SnarkBase);
        await deployer.deploy(SnarkBase, storage_instance.address);
        let snarkbase_instance = await SnarkBase.deployed();
        await storage_instance.allowAccess(snarkbase_instance.address);
        await snarkbase_instance.setTokenName("89 seconds Atomized");
        await snarkbase_instance.setTokenSymbol("SNP001");
        await snarkbase_instance.changeRestrictAccess(true);
        await snarkbase_instance.setPlatformProfitShare(5);
    });
};