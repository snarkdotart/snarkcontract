pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";


/// @title The main snark's storage for tokens and different data of contracts
/// @author Vitali Hurski
/// @notice This contract used by others contracts to store their data
contract SnarkStorage is Ownable {

    mapping (bytes32 => bool)       public boolStorage;
    mapping (bytes32 => string)     public stringStorage;
    mapping (bytes32 => address)    public addressStorage;
    mapping (bytes32 => uint256)    public uintStorage;
    mapping (bytes32 => bytes32)    public bytesStorage;

    /// @notice Snark's contracts only can call functions marked this modifier.
    modifier onlyPlatform {
        require(boolStorage[keccak256(abi.encodePacked("accessAllowed", msg.sender))]);
        _;
    }
    
    /// @notice Contract constructor
    /// @dev The address of the creator is placed on the list of those who are allowed to call functions of contract.
    constructor() public {
        boolStorage[keccak256(abi.encodePacked("accessAllowed", msg.sender))] = true;
    }
    
    /// @notice Will receive any eth sent to the contract
    function() external payable {} // solhint-disable-line

    /// @notice Function to destroy the contract on the blockchain
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    /// @notice Allow access to functions for a particular address of contract.
    /// @param _allowedAddress The address of the contract or wallet to which we 
    /// want to give access to the current functionality.
    function allowAccess(address _allowedAddress) external onlyPlatform {
        boolStorage[keccak256(abi.encodePacked("accessAllowed", _allowedAddress))] = true;
    }
    
    /// @notice Deny access to functions for a particular address of contract.
    /// @param _allowedAddress The address of the contract or wallet that we want 
    /// to exclude access to the current functionality.
    function denyAccess(address _allowedAddress) external onlyPlatform {
        delete boolStorage[keccak256(abi.encodePacked("accessAllowed", _allowedAddress))];
    }

    /// @notice Allows withdrawing ether to a specific address.
    /// @param _to Address of wallet to withdraw
    /// @param _value Ether amount to withdraw
    function transferFunds(address payable _to, uint256 _value) external onlyPlatform {
        require(address(this).balance >= _value, "Not enough ETH to transfer funds to the user");
        _to.transfer(_value);
    }

    function setBool(bytes32 _key, bool _val) external onlyPlatform { boolStorage[_key] = _val; }
    function setString(bytes32 _key, string calldata _val) external onlyPlatform { stringStorage[_key] = _val; }
    function setAddress(bytes32 _key, address _val) external onlyPlatform { addressStorage[_key] = _val; }
    function setUint(bytes32 _key, uint256 _val) external onlyPlatform { uintStorage[_key] = _val; }
    function setBytes(bytes32 _key, bytes32 _val) external onlyPlatform { bytesStorage[_key] = _val; }

    function deleteBool(bytes32 _key) external onlyPlatform { delete boolStorage[_key]; }
    function deleteString(bytes32 _key) external onlyPlatform { delete stringStorage[_key]; }
    function deleteAddress(bytes32 _key) external onlyPlatform { delete addressStorage[_key]; }
    function deleteUint(bytes32 _key) external onlyPlatform { delete uintStorage[_key]; }
    function deleteBytes(bytes32 _key) external onlyPlatform { delete bytesStorage[_key]; }

    function getBool(bytes32 _key) external view returns (bool _value) { return boolStorage[_key]; }
    function getString(bytes32 _key) external view returns (string memory _value) { return stringStorage[_key]; }
    function getAddress(bytes32 _key) external view returns (address _value) { return addressStorage[_key]; }
    function getUint(bytes32 _key) external view returns (uint256 _value) { return uintStorage[_key]; }
    function getBytes(bytes32 _key) external view returns (bytes32 _value) { return bytesStorage[_key]; }
}
