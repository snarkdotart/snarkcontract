var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkBase = artifacts.require("SnarkBase");

contract('SnarkERC721', async (accounts) => {

    let instance = null;

    before(async () => {
        instance = await SnarkERC721.deployed();
        instance_snarkbase = await SnarkBase.deployed();
    });

    it("1. get size of the SnarkERC721 library", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

});
