var SafeMath = artifacts.require("../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol");
var AddressUtils = artifacts.require("../node_modules/openzeppelin-solidity/contracts/AddressUtils.sol");

var SnarkCommonLib = artifacts.require("SnarkCommonLib");
var SnarkBaseLib = artifacts.require("SnarkBaseLib");
var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkStorage = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkERC721);
    deployer.link(AddressUtils, SnarkERC721);
    deployer.link(SnarkCommonLib, SnarkERC721);
    deployer.link(SnarkBaseLib, SnarkERC721);

    deployer.deploy(SnarkERC721, SnarkStorage.address).then(
        function(snarkERC721_instance) {
            SnarkStorage.deployed().then(
                function(storage_instance) {
                    storage_instance.allowAccess(snarkERC721_instance.address);
                }
            );
        }
    );
};