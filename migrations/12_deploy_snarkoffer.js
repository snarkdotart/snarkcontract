var SafeMath            = artifacts.require("openzeppelin/SafeMath.sol");
var SnarkCommonLib      = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib        = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib   = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkOfferBidLib    = artifacts.require("snarklibs/SnarkOfferBidLib");
var SnarkLoanLib        = artifacts.require("snarklibs/SnarkLoanLib");

var SnarkStorage        = artifacts.require("SnarkStorage");
var SnarkOffer          = artifacts.require("SnarkOffer");
var SnarkERC721         = artifacts.require("SnarkERC721");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkOffer);
        await deployer.link(SnarkCommonLib, SnarkOffer);
        await deployer.link(SnarkBaseLib, SnarkOffer);
        await deployer.link(SnarkBaseExtraLib, SnarkOffer);
        await deployer.link(SnarkOfferBidLib, SnarkOffer);
        await deployer.link(SnarkLoanLib, SnarkOffer);

        const storage_instance = await SnarkStorage.deployed();
        const erc721_instance = await SnarkERC721.deployed();
        await deployer.deploy(SnarkOffer, storage_instance.address, erc721_instance.address);

        const snarkoffer_instance = await SnarkOffer.deployed();
        await storage_instance.allowAccess(snarkoffer_instance.address);
    });

};