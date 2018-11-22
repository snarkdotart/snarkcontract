var SnarkOfferBidLib = artifacts.require("snarklibs/SnarkOfferBidLib");
var SafeMath = artifacts.require("openzeppelin/SafeMath");

module.exports = function(deployer) {
    deployer.then(async () => {
        await deployer.link(SafeMath, SnarkOfferBidLib);
        await deployer.deploy(SnarkOfferBidLib);
    });
};