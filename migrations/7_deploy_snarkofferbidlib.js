var SnarkOfferBidLib = artifacts.require("snarklibs/SnarkOfferBidLib");
var SafeMath = artifacts.require("openzeppelin/SafeMath");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkOfferBidLib);
    deployer.deploy(SnarkOfferBidLib);
};