var SnarkLib = artifacts.require("SnarkLib");

module.exports = function(deployer) {
    deployer.deploy(SnarkLib);
};