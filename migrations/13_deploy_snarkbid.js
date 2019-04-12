var SafeMath            = artifacts.require("openzeppelin/SafeMath.sol");
var SnarkCommonLib      = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib        = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib   = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkOfferBidLib    = artifacts.require("snarklibs/SnarkOfferBidLib");
var SnarkLoanLib        = artifacts.require("snarklibs/SnarkLoanLib");

var SnarkStorage        = artifacts.require("SnarkStorage");
var SnarkBid            = artifacts.require("SnarkBid");
var SnarkERC721         = artifacts.require("SnarkERC721");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkBid);
        await deployer.link(SnarkCommonLib, SnarkBid);
        await deployer.link(SnarkBaseLib, SnarkBid);
        await deployer.link(SnarkBaseExtraLib, SnarkBid);
        await deployer.link(SnarkOfferBidLib, SnarkBid);
        await deployer.link(SnarkLoanLib, SnarkBid);

        const storage_instance = await SnarkStorage.deployed();
        const erc721_instance = await SnarkERC721.deployed();
        await deployer.deploy(SnarkBid, storage_instance.address, erc721_instance.address);

        const snarkbid_instance = await SnarkBid.deployed();
        await storage_instance.allowAccess(snarkbid_instance.address);
    });

};