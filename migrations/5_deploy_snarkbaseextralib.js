var SafeMath = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkStorage = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkBaseExtraLib);
        const baseExtraLib = await deployer.deploy(SnarkBaseExtraLib);

        const storage_instance = await SnarkStorage.deployed();
        await storage_instance.allowAccess(baseExtraLib.address);
    });
};