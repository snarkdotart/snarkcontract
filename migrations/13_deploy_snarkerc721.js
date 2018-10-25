var SafeMath = artifacts.require("openzeppelin/SafeMath.sol");
var AddressUtils = artifacts.require("openzeppelin/AddressUtils.sol");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBaseExtraLib = artifacts.require("snarklibs/SnarkBaseExtraLib");
var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkStorage = artifacts.require("SnarkStorage");

module.exports = function(deployer) {
    deployer.link(SafeMath, SnarkERC721);
    deployer.link(AddressUtils, SnarkERC721);
    deployer.link(SnarkCommonLib, SnarkERC721);
    deployer.link(SnarkBaseLib, SnarkERC721);
    deployer.link(SnarkBaseExtraLib, SnarkERC721);
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