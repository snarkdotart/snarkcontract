pragma solidity ^0.4.22;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ISnarkHub.sol";


contract SnarkHub is Ownable {

    mapping(string => address) private moduleToAddressMap;
    mapping(address => bool) private addressToAccessMap;

    modifier onlyRegisteredContracts {
        require(addressToAccessMap[msg.sender] == true);
        _;
    }

    constructor() public {
        addressToAccessMap[msg.sender] = true;
    }

    function setContractToHub(string _moduleName, address _contractAddress) external onlyOwner {
        _removeOldContractAddress(_moduleName);
        moduleToAddressMap[_moduleName] = _contractAddress;
        addressToAccessMap[_contractAddress] = true;
    }

    function getContractAddress(string _moduleName) 
        external 
        view 
        onlyRegisteredContracts returns (address _moduleAddress) 
    {
        return moduleToAddressMap[_moduleName];
    }

    function isContractRegistered(address _contractAddress) 
        external 
        view 
        onlyRegisteredContracts 
        returns (bool isRegistered) 
    {
        return addressToAccessMap[_contractAddress];
    }

    function _removeOldContractAddress(string _moduleName) private {
        address _moduleAddress = moduleToAddressMap[_moduleName];
        if (_moduleAddress != address(0)) {
            // solhint-disable-next-line
            if (_moduleAddress.call(bytes4(keccak256("kill()")))) {
                delete moduleToAddressMap[_moduleName];
                delete addressToAccessMap[_moduleAddress];
            }
        }
    }

}
