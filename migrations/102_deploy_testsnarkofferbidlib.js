var SnarkBaseLib = artifacts.require("SnarkBaseLib");
var SnarkOfferBidLib = artifacts.require("SnarkOfferBidLib");
var SnarkStorage = artifacts.require("SnarkStorage");
var TestSnarkOfferBidLib = artifacts.require("TestSnarkOfferBidLib");

module.exports = function(deployer) {
    deployer.link(SnarkBaseLib, TestSnarkOfferBidLib);
    deployer.link(SnarkOfferBidLib, TestSnarkOfferBidLib);
    deployer.deploy(TestSnarkOfferBidLib, SnarkStorage.address).then(
        function(test_instance) {
            SnarkStorage.deployed().then(
                function(storage_instance) {
                    storage_instance.allowAccess(test_instance.address);
                }
            );
        }
    );
};