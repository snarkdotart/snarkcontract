var SafeMath        = artifacts.require("openzeppelin/SafeMath.sol");
var SnarkCommonLib  = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib    = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkLoanLibExt = artifacts.require("snarklibs/SnarkLoanLibExt");
var SnarkLoanLib    = artifacts.require("snarklibs/SnarkLoanLib");

var SnarkLoan       = artifacts.require("SnarkLoan");
var SnarkStorage    = artifacts.require("SnarkStorage");
var SnarkERC721     = artifacts.require("SnarkERC721");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkLoan);
        await deployer.link(SnarkCommonLib, SnarkLoan);
        await deployer.link(SnarkBaseLib, SnarkLoan);
        await deployer.link(SnarkLoanLibExt, SnarkLoan);
        await deployer.link(SnarkLoanLib, SnarkLoan);

        const storage_instance = await SnarkStorage.deployed();
        const erc721_instance = await SnarkERC721.deployed();
        await deployer.deploy(SnarkLoan, storage_instance.address, erc721_instance.address);

        const snarkLoan_instance = await SnarkLoan.deployed();
        await storage_instance.allowAccess(snarkLoan_instance.address);
        await snarkLoan_instance.setDefaultLoanDuration(30);
    });
};