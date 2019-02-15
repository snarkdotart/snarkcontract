var SnarkOfferBidLib    = artifacts.require("snarklibs/SnarkOfferBidLib");
var SafeMath            = artifacts.require("openzeppelin/SafeMath");

var SnarkStorage        = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkOfferBidLib);

        const offerBidLib = await deployer.deploy(SnarkOfferBidLib);
        const storage_instance = await SnarkStorage.deployed();
        await storage_instance.allowAccess(offerBidLib.address);
    });
};