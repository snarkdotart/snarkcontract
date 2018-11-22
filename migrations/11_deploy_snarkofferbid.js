var SafeMath = artifacts.require("openzeppelin/SafeMath.sol");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkOfferBidLib = artifacts.require("snarklibs/SnarkOfferBidLib");
var SnarkLoanLib = artifacts.require("snarklibs/SnarkLoanLib");
var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkOfferBid = artifacts.require("SnarkOfferBid");

module.exports = function(deployer) {
    deployer.then(async () => {
        let storage_instance = await SnarkStorage.deployed();
        await deployer.link(SafeMath, SnarkOfferBid);
        await deployer.link(SnarkCommonLib, SnarkOfferBid);
        await deployer.link(SnarkBaseLib, SnarkOfferBid);
        await deployer.link(SnarkBaseExtraLib, SnarkOfferBid);
        await deployer.link(SnarkOfferBidLib, SnarkOfferBid);
        await deployer.link(SnarkLoanLib, SnarkOfferBid);
        await deployer.deploy(SnarkOfferBid, storage_instance.address);
        let snarkofferbid_instance = await SnarkOfferBid.deployed();
        await storage_instance.allowAccess(snarkofferbid_instance.address);
    });

};