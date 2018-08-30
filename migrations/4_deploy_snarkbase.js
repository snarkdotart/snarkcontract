var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkLib = artifacts.require("SnarkLib");
var SnarkBase = artifacts.require("SnarkBase.sol");

module.exports = function(deployer) {
    deployer.link(SnarkLib, SnarkBase);
    deployer.deploy(SnarkBase, SnarkStorage.address).then(
        function(snarkbase_instance) {
            SnarkStorage.deployed().then(
                function(storage_instance) {
                    storage_instance.allowAccess(snarkbase_instance.address);
                }
            );
        }
    );
};