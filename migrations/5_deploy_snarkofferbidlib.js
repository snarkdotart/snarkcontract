var SnarkOfferBidLib = artifacts.require("snarklibs/SnarkOfferBidLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkOfferBidLib);
};