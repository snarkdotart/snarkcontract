var SnarkOfferBidLib = artifacts.require("SnarkOfferBidLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkOfferBidLib);
};