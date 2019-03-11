var SnarkLoanLib    = artifacts.require("snarklibs/SnarkLoanLib");
var SnarkLoanLibExt = artifacts.require("snarklibs/SnarkLoanLibExt");
var SnarkBaseLib    = artifacts.require("snarklibs/SnarkBaseLib");

var SnarkLoanExt    = artifacts.require("SnarkLoanExt");
var SnarkStorage    = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SnarkLoanLib, SnarkLoanExt);
        await deployer.link(SnarkLoanLibExt, SnarkLoanExt);
        await deployer.link(SnarkBaseLib, SnarkLoanExt);
        
        const storage_instance = await SnarkStorage.deployed();
        await deployer.deploy(SnarkLoanExt, storage_instance.address);

        const snarkLoanExt_instance = await SnarkLoanExt.deployed();
        await storage_instance.allowAccess(snarkLoanExt_instance.address);
    });
};