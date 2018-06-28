var SnarkBase = artifacts.require("SnarkBase");

contract('SnarkBase', function(accounts) {

  it("get the size of the SnarkBase contract", function() {
    return SnarkBase.deployed().then(function(instance) {
      var bytecode = instance.constructor._json.bytecode;
      var deployed = instance.constructor._json.deployedBytecode;
      var sizeOfB  = bytecode.length / 2;
      var sizeOfD  = deployed.length / 2;
      console.log("size of bytecode in bytes = ", sizeOfB);
      console.log("size of deployed in bytes = ", sizeOfD);
      console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });  
  });

});

  // it("check default value of platform profit share", function() {
  //   Snark.deployed().then(function(instance) {
  //     console.log(instance.platformProfitShare);
  //     return instance.platformProfitShare;
  //   });
  // });

  // it("check changing default value of platform profit share", function() {
  //   Snark.deployed().then(function(instance) {
  //     var newPercent = 7;
  //     instance.setPlatformProfitShare.call(newPercent);
  //     console.log(instance.platformProfitShare);
  //     assert.equal(instance.platformProfitShare, 5);
  //     assert.equal(instance.platformProfitShare, newPercent);
  //     console.log(instance.platformProfitShare);
  //     assert.equal(instance.platformProfitShare, 5);
  //   });
  // });

  // it("add 5 digital works to the blockchain", function() {
  //   Snark.deployed().then(function(instance) {
  //     var _url = "ipfs://sss.df";
  //     var _hash = "!q@w#e$r%t6y";
  //     var _editionNumber = 5;
  //     var _profitPercent = 10;

  //     instance.addArtwork(_hash, _editionNumber, _profitPercent, _url);

  //     assert.isTrue(instance.artworks.length == _editionNumber);
  //     assert.isTrue(instance.artworks[0].profitShare == _profitPercent);
  //     assert.isTrue(instance.artworks[0].artworkUrl == _url);
  //   });
  // });

// contract('SnarkStorehouse', function(accounts) {
//     let ownable;
//     beforeEach(async function () {
//         ownable = await SnarkStorehouse.new();
//     });
//     it('should have an owner', async function () {
//         let owner = await ownable.owner();
//         assert.isTrue(owner !== 0);
//     });
//     it('changes owner after transfer', async function () {
//         let other = accounts[1];
//         await ownable.transferOwnership(other);
//         let owner = await ownable.owner();
//         assert.isTrue(owner === other);
//     });
// });

