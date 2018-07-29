var SafeMath = artifacts.require("./OpenZeppelin/SafeMath.sol");
var AddressUtils = artifacts.require("./OpenZeppelin/AddressUtils.sol");
var SnarkStorage = artifacts.require("./SnarkStorage.sol");
var SnarkContract = artifacts.require("./SnarkOfferBid.sol");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkContract);
    deployer.link(AddressUtils, SnarkContract);

    deployer.deploy(SnarkContract, SnarkStorage.address)
    .then(function(snark_instance) {
        SnarkStorage.deployed().then(function(snarkstorage_instance) {
            snarkstorage_instance.allowAccess(snark_instance.address);
        });
    });
};