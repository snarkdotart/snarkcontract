var SafeMath            = artifacts.require("openzeppelin/SafeMath.sol");
var AddressUtils        = artifacts.require("openzeppelin/AddressUtils.sol");
var SnarkCommonLib      = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib        = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib   = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkLoanLibExt     = artifacts.require("snarklibs/SnarkLoanLibExt");

var SnarkERC721         = artifacts.require("SnarkERC721");
var SnarkStorage        = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkERC721);
        await deployer.link(AddressUtils, SnarkERC721);
        await deployer.link(SnarkCommonLib, SnarkERC721);
        await deployer.link(SnarkBaseLib, SnarkERC721);
        await deployer.link(SnarkBaseExtraLib, SnarkERC721);
        await deployer.link(SnarkLoanLibExt, SnarkERC721);
        
        let storage_instance = await SnarkStorage.deployed();
        await deployer.deploy(SnarkERC721, storage_instance.address);
        
        let snarkERC721_instance = await SnarkERC721.deployed();
        await storage_instance.allowAccess(snarkERC721_instance.address);
    });
};