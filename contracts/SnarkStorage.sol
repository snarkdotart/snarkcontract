pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";


contract SnarkStorage is Ownable {

    mapping (bytes32 => bool)       public boolStorage;
    mapping (bytes32 => string)     public stringStorage;
    mapping (bytes32 => address)    public addressStorage;
    mapping (bytes32 => uint256)    public uintStorage;
    mapping (bytes32 => bytes32)    public bytesStorage;

    modifier onlyPlatform {
        require(boolStorage[keccak256(abi.encodePacked("accessAllowed", msg.sender))]);
        _;
    }
    
    constructor() public {
        boolStorage[keccak256(abi.encodePacked("accessAllowed", msg.sender))] = true;
    }
    
    /// @notice Will receive any eth sent to the contract
    function() external payable {} // solhint-disable-line

    /// @dev Function to destroy the contract on the blockchain
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }
    
    function allowAccess(address _allowedAddress) external onlyPlatform {
        boolStorage[keccak256(abi.encodePacked("accessAllowed", _allowedAddress))] = true;
    }
    
    function denyAccess(address _allowedAddress) external onlyPlatform {
        delete boolStorage[keccak256(abi.encodePacked("accessAllowed", _allowedAddress))];
    }
    
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
