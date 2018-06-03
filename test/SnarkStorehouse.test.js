import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

let SnarkStorehouse = artifacts.require('SnarkStorehouse');

contract('SnarkStorehouse', function(accounts) {
    let ownable;
    
    beforeEach(async function () {
        ownable = await SnarkStorehouse.new();
    });
    
    it('should have an owner', async function () {
        let owner = await ownable.owner();
        assert.isTrue(owner !== 0);
    });

    it('changes owner after transfer', async function () {
        let other = accounts[1];
        await ownable.transferOwnership(other);
        let owner = await ownable.owner();

        assert.isTrue(owner === other);
    });
 
});