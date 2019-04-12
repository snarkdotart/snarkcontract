var SnarkBaseLib    = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkLoanLib    = artifacts.require("snarklibs/SnarkLoanLib");

var SnarkTestFunctions  = artifacts.require("SnarkTestFunctions");
var SnarkStorage        = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SnarkBaseLib, SnarkTestFunctions);
        await deployer.link(SnarkLoanLib, SnarkTestFunctions);
        
        let storage_instance = await SnarkStorage.deployed();
        await deployer.deploy(SnarkTestFunctions, storage_instance.address);

        let snarkTestFunctions_instance = await SnarkTestFunctions.deployed();
        await storage_instance.allowAccess(snarkTestFunctions_instance.address);
    });
};