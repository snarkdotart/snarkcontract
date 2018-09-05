pragma solidity ^0.4.24;


contract ISnarkHub {
    function setContractToHub(string _moduleName, address _contractAddress) external;
    function getContractAddress(string _moduleName) external view returns (address _moduleAddress);
    function isContractRegistered(address _contractAddress) external view returns (bool isRegistered);
}
