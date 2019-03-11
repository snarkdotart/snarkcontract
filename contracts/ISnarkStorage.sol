pragma solidity >=0.5.0;


interface ISnarkStorage {
    function allowAccess(address _allowedAddress) external;
    function denyAccess(address _allowedAddress) external;
    function setBool(bytes32 _key, bool _val) external;
    function setString(bytes32 _key, string calldata _val) external;
    function setAddress(bytes32 _key, address _val) external;
    function setUint(bytes32 _key, uint256 _val) external;

    function deleteBool(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;

    function getBool(bytes32 _key) external view returns (bool _value);
    function getString(bytes32 _key) external view returns (string memory _value);
    function getAddress(bytes32 _key) external view returns (address _value);
    function getUint(bytes32 _key) external view returns (uint256 _value);
}