var SnarkCommonLib      = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib        = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib   = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkLoanLib        = artifacts.require("snarklibs/SnarkLoanLib");

var SnarkBase           = artifacts.require("SnarkBase");
var SnarkStorage        = artifacts.require("SnarkStorage");
var SnarkERC721         = artifacts.require("SnarkERC721");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SnarkCommonLib, SnarkBase);
        await deployer.link(SnarkBaseExtraLib, SnarkBase);
        await deployer.link(SnarkBaseLib, SnarkBase);
        await deployer.link(SnarkLoanLib, SnarkBase);

        const storage_instance = await SnarkStorage.deployed();
        const erc721_instance = await SnarkERC721.deployed();
        await deployer.deploy(SnarkBase, storage_instance.address, erc721_instance.address);

        const snarkbase_instance = await SnarkBase.deployed();
        await storage_instance.allowAccess(snarkbase_instance.address);

        await snarkbase_instance.setTokenName("89 seconds Atomized");
        await snarkbase_instance.setTokenSymbol("SNP001");
        await snarkbase_instance.changeRestrictAccess(false);
        await snarkbase_instance.setPlatformProfitShare(5);
        await snarkbase_instance.setSnarkWalletAddress('0xF2d515F3fC586B6C0dc083599b224372f9B3e53c');
    });
};