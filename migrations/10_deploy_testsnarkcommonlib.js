var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkCommonLib = artifacts.require("SnarkCommonLib");
var SnarkBaseLib = artifacts.require("SnarkBaseLib");
var TestSnarkCommonLib = artifacts.require("TestSnarkCommonLib");

module.exports = function(deployer) {
    deployer.link(SnarkCommonLib, TestSnarkCommonLib);
    deployer.link(SnarkBaseLib, TestSnarkCommonLib);
    deployer.deploy(TestSnarkCommonLib, SnarkStorage.address).then(
        function(test_instance) {
            SnarkStorage.deployed().then(
                function(storage_instance) {
                    storage_instance.allowAccess(test_instance.address);
                }
            );
        }
    );
};