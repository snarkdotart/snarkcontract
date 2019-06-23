var SafeMath            = artifacts.require("openzeppelin/SafeMath");
var SnarkBaseExtraLib   = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkBaseLib        = artifacts.require("snarklibs/SnarkBaseLib");

var SnarkStorage        = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkBaseLib);
        await deployer.link(SnarkBaseExtraLib, SnarkBaseLib);

        const baseLib = await deployer.deploy(SnarkBaseLib);
        const storage_instance = await SnarkStorage.deployed();
        await storage_instance.allowAccess(baseLib.address);
    });
};