var SafeMath = artifacts.require("openzeppelin/SafeMath.sol");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkOfferBidLib = artifacts.require("snarklibs/SnarkOfferBidLib");
var SnarkOfferBid = artifacts.require("SnarkOfferBid");
var SnarkStorage = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkOfferBid);
    deployer.link(SnarkCommonLib, SnarkOfferBid);
    deployer.link(SnarkBaseLib, SnarkOfferBid);
    deployer.link(SnarkOfferBidLib, SnarkOfferBid);

    deployer.deploy(SnarkOfferBid, SnarkStorage.address).then(
        function(snarkofferbid_instance) {
            SnarkStorage.deployed().then(
                function(storage_instance) {
                    storage_instance.allowAccess(snarkofferbid_instance.address);
                }
            );
        }
    );
};