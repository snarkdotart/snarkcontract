var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkCommonLib = artifacts.require("snarklibs/SnarkCommonLib");
var SnarkBaseLib = artifacts.require("snarklibs/SnarkBaseLib");
var SnarkBase = artifacts.require("SnarkBase");

module.exports = function(deployer) {
    deployer.link(SnarkCommonLib, SnarkBase);
    deployer.link(SnarkBaseLib, SnarkBase);
    deployer.deploy(SnarkBase, SnarkStorage.address).then(
        function(snarkbase_instance) {
            SnarkStorage.deployed().then(
                function(storage_instance) {
                    storage_instance.allowAccess(snarkbase_instance.address);
                }
            );
            snarkbase_instance.setTokenName("Snark Art Token");
            snarkbase_instance.setTokenSymbol("SAT");
        }
    );
};