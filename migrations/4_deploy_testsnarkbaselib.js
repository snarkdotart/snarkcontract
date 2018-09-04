var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkBaseLib = artifacts.require("SnarkBaseLib");
var TestSnarkBaseLib = artifacts.require("TestSnarkBaseLib");

module.exports = function(deployer) {
    deployer.link(SnarkBaseLib, TestSnarkBaseLib);
    deployer.deploy(TestSnarkBaseLib, SnarkStorage.address).then(
        function(test_instance) {
            SnarkStorage.deployed().then(
                function(storage_instance) {
                    storage_instance.allowAccess(test_instance.address);
                }
            );
        }
    );
};