pragma solidity ^0.4.24;


interface ISnarkStorage {

    function increaseArrayNameToItemsCount(string _variableName) external;
    function addStorageUint8ToUint256Array(string _variableName, uint8 _key, uint256 _val) external;
    function addStorageUint256ToBytes32Array(string _variableName, uint256 _key, bytes32 _val) external;
    function addStorageUint256ToUint8Array(string _variableName, uint256 _key, uint8 _val) external;
    function addStorageUint256ToUint16Array(string _variableName, uint256 _key, uint16 _val) external;
    function addStorageUint256ToUint64Array(string _variableName, uint256 _key, uint64 _val) external;
    function addStorageUint256ToUint256Array(string _variableName, uint256 _key, uint256 _val) external;
    function addStorageUint256ToAddressArray(string _variableName, uint256 _key, address _val) external;
    function addStorageAddressToAddressArray(string _variableName, address _key, address _val) external;
    function addStorageAddressToUint256Array(string _variableName, address _key, uint256 _val) external;

    ///// SET
    function setStorageBytes32ToBool(string _variableName, bytes32 _key, bool _val) external;
    function setStorageUint8ToUint256Array(string _variableName, uint8 _key, uint256 _index, uint256 _val) external;
    function setStorageUint256ToBytes32Array(string _variableName, uint256 _key, uint256 _index, bytes32 _val) external;
    function setStorageUint256ToUint8Array(string _variableName, uint256 _key, uint256 _index, uint8 _val) external;
    function setStorageUint256ToUint16Array(string _variableName, uint256 _key, uint256 _index, uint16 _val) external;
    function setStorageUint256ToUint64Array(string _variableName, uint256 _key, uint256 _index, uint64 _val) external;
    function setStorageUint256ToUint256Array(string _variableName, uint256 _key, uint256 _index, uint256 _val) external;
    function setStorageUint256ToAddressArray(string _variableName, uint256 _key, uint256 _index, address _val) external;
    function setStorageUint256ToString(string _variableName, uint256 _key, string _val) external;
    function setStorageAddressToAddressArray(string _variableName, address _key, uint256 _index, address _val) external;
    function setStorageAddressToUint256Array(string _variableName, address _key, uint256 _index, uint256 _val) external;
    function setStorageAddressToBool(string _variableName, address _key, bool _val) external;

    ///// DELETE
    function deleteStorageUint8ToUint256Array(string _variableName, uint8 _key, uint256 _index) external;
    function deleteStorageUint256ToBytes32Array(string _variableName, uint256 _key, uint256 _index) external;
    function deleteStorageUint256ToUint8Array(string _variableName, uint256 _key, uint256 _index) external;
    function deleteStorageUint256ToUint16Array(string _variableName, uint256 _key, uint256 _index) external;
    function deleteStorageUint256ToUint64Array(string _variableName, uint256 _key, uint256 _index) external;
    function deleteStorageUint256ToUint256Array(string _variableName, uint256 _key, uint256 _index) external;
    function deleteStorageUint256ToAddressArray(string _variableName, uint256 _key, uint256 _index) external;
    function deleteStorageUint256ToString(string _variableName, uint256 _key) external;
    function deleteStorageAddressToAddressArray(string _variableName, address _key, uint256 _index) external;
    function deleteStorageAddressToUint256Array(string _variableName, address _key, uint256 _index) external;

    ///// GET
    function getArrayNameToItemsCount(string _variableName) external view returns (uint256);
    function getStorageBytes32ToBool(string _variableName, bytes32 _key) external view returns (bool);
    
    function getStorageUint8ToUint256Array(
        string _variableName, 
        uint8 _key, 
        uint256 _index
    ) external view returns (uint256);
    
    function getStorageUint8ToUint256ArrayLength(string _variableName, uint8 _key) external view returns (uint256);
    
    function getStorageUint256ToBytes32Array(
        string _variableName, 
        uint256 _key, 
        uint256 _index
    ) external view returns (bytes32);

    function getStorageUint256ToBytes32ArrayLength(string _variableName, uint256 _key) external view returns (uint256);

    function getStorageUint256ToUint8Array(
        string _variableName, 
        uint256 _key,
        uint256 _index
    ) external view returns (uint8);

    function getStorageUint256ToUint8ArrayLength(string _variableName, uint256 _key) external view returns (uint256);
    
    function getStorageUint256ToUint16Array(
        string _variableName, 
        uint256 _key, 
        uint256 _index
    ) external view returns (uint16);
    
    function getStorageUint256ToUint16ArrayLength(string _variableName, uint256 _key) external view returns (uint256);
    
    function getStorageUint256ToUint64Array(
        string _variableName, 
        uint256 _key, 
        uint256 _index
    ) external view returns (uint64);

    function getStorageUint256ToUint64ArrayLength(string _variableName, uint256 _key) external view returns (uint256);
    
    function getStorageUint256ToUint256Array(
        string _variableName, 
        uint256 _key, 
        uint256 _index
    ) external view returns (uint256);

    function getStorageUint256ToUint256ArrayLength(string _variableName, uint256 _key) external view returns (uint256);
    
    function getStorageUint256ToAddressArray(
        string _variableName, 
        uint256 _key, 
        uint256 _index
    ) external view returns (address);

    function getStorageUint256ToAddressArrayLength(string _variableName, uint256 _key) external view returns (uint256);
    function getStorageUint256ToString(string _variableName, uint256 _key) external view returns (string);

    function getStorageAddressToAddressArray(
        string _variableName, 
        address _key, 
        uint256 _index
    ) external view returns (address);

    function getStorageAddressToAddressArrayLength(string _variableName, address _key) external view returns (uint256);
    
    function getStorageAddressToUint256Array(
        string _variableName, 
        address _key, 
        uint256 _index
    ) external view returns (uint256);

    function getStorageAddressToUint256ArrayLength(string _variableName, address _key) external view returns (uint256);
    function getStorageAddressToBool(string _variableName, address _key) external view returns (bool);
}