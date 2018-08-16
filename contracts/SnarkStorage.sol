pragma solidity ^0.4.24;

import "./ISnarkStorage.sol";
import "./ISnarkHub.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract SnarkStorage is Ownable, ISnarkStorage {

    mapping (string => uint256)                         private arrayNameToItemsCount;

    mapping (string => mapping (bytes32 => bool))       private storageBytes32ToBool;
    mapping (string => mapping (uint8   => uint256[]))  private storageUint8ToUint256Array;
    mapping (string => mapping (uint256 => bytes32[]))  private storageUint256ToBytes32Array;
    mapping (string => mapping (uint256 => uint8[]))    private storageUint256ToUint8Array;
    mapping (string => mapping (uint256 => uint16[]))   private storageUint256ToUint16Array;
    mapping (string => mapping (uint256 => uint64[]))   private storageUint256ToUint64Array;
    mapping (string => mapping (uint256 => uint256[]))  private storageUint256ToUint256Array;
    mapping (string => mapping (uint256 => address[]))  private storageUint256ToAddressArray;
    mapping (string => mapping (uint256 => string))     private storageUint256ToString;

    mapping (string => mapping (address => address[]))  private storageAddressToAddressArray;
    mapping (string => mapping (address => uint256[]))  private storageAddressToUint256Array;
    mapping (string => mapping (address => bool))       private storageAddressToBool;

    // TODO: Think how to get rid of it!
    // Mapping token of revenue participant to their approval confirmation
    mapping (uint256 => mapping (address => bool))      private tokenToParticipantApprovingMap;
    // Mapping from owner to approved operator
    // use storageAddressToAddressArray instead of operatorToApprovalsMap
    // mapping (address => mapping (address => bool))      private operatorToApprovalsMap;

    ISnarkHub private snarkHub;

    modifier onlyPlatform {
        require(storageAddressToBool["accessAllowed"][msg.sender] || snarkHub.isContractRegistered(msg.sender));
        _;
    }

    constructor (address _hubAddr) public {
        storageAddressToBool["accessAllowed"][msg.sender] = true;
        storageAddressToBool["accessAllowed"][_hubAddr] = true;
        snarkHub = ISnarkHub(_hubAddr);
    }

    function kill() external onlyPlatform {
        selfdestruct(owner);
    }

    ///// ADD or INCREMENT
    function increaseArrayNameToItemsCount(string _variableName) external {
        arrayNameToItemsCount[_variableName]++;
    }

    function addStorageUint8ToUint256Array(string _variableName, uint8 _key, uint256 _val) external {
        storageUint8ToUint256Array[_variableName][_key].push(_val);
    }

    function addStorageUint256ToBytes32Array(string _variableName, uint256 _key, bytes32 _val) external {
        storageUint256ToBytes32Array[_variableName][_key].push(_val);
    }

    function addStorageUint256ToUint8Array(string _variableName, uint256 _key, uint8 _val) external {
        storageUint256ToUint8Array[_variableName][_key].push(_val);
    }

    function addStorageUint256ToUint16Array(string _variableName, uint256 _key, uint16 _val) external {
        storageUint256ToUint16Array[_variableName][_key].push(_val);
    }

    function addStorageUint256ToUint64Array(string _variableName, uint256 _key, uint64 _val) external {
        storageUint256ToUint64Array[_variableName][_key].push(_val);
    }

    function addStorageUint256ToUint256Array(string _variableName, uint256 _key, uint256 _val) external {
        storageUint256ToUint256Array[_variableName][_key].push(_val);
    }

    function addStorageUint256ToAddressArray(string _variableName, uint256 _key, address _val) external {
        storageUint256ToAddressArray[_variableName][_key].push(_val);
    }

    function addStorageAddressToAddressArray(string _variableName, address _key, address _val) external {
        storageAddressToAddressArray[_variableName][_key].push(_val);
    }

    function addStorageAddressToUint256Array(string _variableName, address _key, uint256 _val) external {
        storageAddressToUint256Array[_variableName][_key].push(_val);
    }

    ///// SET
    function setStorageBytes32ToBool(string _variableName, bytes32 _key, bool _val) external {
        storageBytes32ToBool[_variableName][_key] = _val;
    }

    function setStorageUint8ToUint256Array(string _variableName, uint8 _key, uint256 _index, uint256 _val) external {
        require(_index < storageUint8ToUint256Array[_variableName][_key].length);
        storageUint8ToUint256Array[_variableName][_key][_index] = _val;
    }

    function setStorageUint256ToBytes32Array(
        string _variableName, 
        uint256 _key, 
        uint256 _index, 
        bytes32 _val
    ) 
        external 
    {
        require(_index < storageUint256ToBytes32Array[_variableName][_key].length);
        storageUint256ToBytes32Array[_variableName][_key][_index] = _val;
    }

    function setStorageUint256ToUint8Array(string _variableName, uint256 _key, uint256 _index, uint8 _val) external {
        require(_index < storageUint256ToUint8Array[_variableName][_key].length);
        storageUint256ToUint8Array[_variableName][_key][_index] = _val;
    }

    function setStorageUint256ToUint16Array(string _variableName, uint256 _key, uint256 _index, uint16 _val) external {
        require(_index < storageUint256ToUint16Array[_variableName][_key].length);
        storageUint256ToUint16Array[_variableName][_key][_index] = _val;
    }

    function setStorageUint256ToUint64Array(string _variableName, uint256 _key, uint256 _index, uint64 _val) external {
        require(_index < storageUint256ToUint64Array[_variableName][_key].length);
        storageUint256ToUint64Array[_variableName][_key][_index] = _val;
    }

    function setStorageUint256ToUint256Array(
        string _variableName, 
        uint256 _key, 
        uint256 _index, 
        uint256 _val
    ) 
        external 
    {
        require(_index < storageUint256ToUint256Array[_variableName][_key].length);
        storageUint256ToUint256Array[_variableName][_key][_index] = _val;
    }

    function setStorageUint256ToAddressArray(
        string _variableName, 
        uint256 _key, 
        uint256 _index, 
        address _val
    ) 
        external 
    {
        require(_index < storageUint256ToAddressArray[_variableName][_key].length);
        storageUint256ToAddressArray[_variableName][_key][_index] = _val;
    }

    function setStorageUint256ToString(string _variableName, uint256 _key, string _val) external {
        storageUint256ToString[_variableName][_key] = _val;
    }

    function setStorageAddressToAddressArray(
        string _variableName, 
        address _key, 
        uint256 _index, 
        address _val
    ) 
        external 
    {
        require(_index < storageAddressToAddressArray[_variableName][_key].length);
        storageAddressToAddressArray[_variableName][_key][_index] = _val;
    }

    function setStorageAddressToUint256Array(
        string _variableName, 
        address _key, 
        uint256 _index, 
        uint256 _val
    ) 
        external 
    {
        require(_index < storageAddressToUint256Array[_variableName][_key].length);
        storageAddressToUint256Array[_variableName][_key][_index] = _val;
    }

    function setStorageAddressToBool(string _variableName, address _key, bool _val) external {
        storageAddressToBool[_variableName][_key] = _val;
    }

    ///// DELETE
    function deleteStorageUint8ToUint256Array(string _variableName, uint8 _key, uint256 _index) external {
        require(_index < storageUint8ToUint256Array[_variableName][_key].length);
        storageUint8ToUint256Array[_variableName][_key][_index] = 
            storageUint8ToUint256Array[_variableName][_key][storageUint8ToUint256Array[_variableName][_key].length - 1];
        storageUint8ToUint256Array[_variableName][_key].length--;
    }

    function deleteStorageUint256ToBytes32Array(string _variableName, uint256 _key, uint256 _index) external {
        require(_index < storageUint256ToBytes32Array[_variableName][_key].length);
        uint256 lastIndex = storageUint256ToBytes32Array[_variableName][_key].length - 1;
        storageUint256ToBytes32Array[_variableName][_key][_index] = 
            storageUint256ToBytes32Array[_variableName][_key][lastIndex];
        storageUint256ToBytes32Array[_variableName][_key].length--;
    }

    function deleteStorageUint256ToUint8Array(string _variableName, uint256 _key, uint256 _index) external {
        require(_index < storageUint256ToUint8Array[_variableName][_key].length);
        storageUint256ToUint8Array[_variableName][_key][_index] = 
            storageUint256ToUint8Array[_variableName][_key][storageUint256ToUint8Array[_variableName][_key].length - 1];
        storageUint256ToUint8Array[_variableName][_key].length--;
    }

    function deleteStorageUint256ToUint16Array(string _variableName, uint256 _key, uint256 _index) external {
        require(_index < storageUint256ToUint16Array[_variableName][_key].length);
        uint256 lastIndex = storageUint256ToUint16Array[_variableName][_key].length - 1;
        storageUint256ToUint16Array[_variableName][_key][_index] = 
            storageUint256ToUint16Array[_variableName][_key][lastIndex];
        storageUint256ToUint16Array[_variableName][_key].length--;
    }

    function deleteStorageUint256ToUint64Array(string _variableName, uint256 _key, uint256 _index) external {
        require(_index < storageUint256ToUint64Array[_variableName][_key].length);
        uint256 lastIndex = storageUint256ToUint64Array[_variableName][_key].length - 1;
        storageUint256ToUint64Array[_variableName][_key][_index] = 
            storageUint256ToUint64Array[_variableName][_key][lastIndex];
        storageUint256ToUint64Array[_variableName][_key].length--;
    }

    function deleteStorageUint256ToUint256Array(string _variableName, uint256 _key, uint256 _index) external {
        require(_index < storageUint256ToUint256Array[_variableName][_key].length);
        uint256 lastIndex = storageUint256ToUint256Array[_variableName][_key].length - 1;
        storageUint256ToUint256Array[_variableName][_key][_index] = 
            storageUint256ToUint256Array[_variableName][_key][lastIndex];
        storageUint256ToUint256Array[_variableName][_key].length--;
    }

    function deleteStorageUint256ToAddressArray(string _variableName, uint256 _key, uint256 _index) external {
        require(_index < storageUint256ToAddressArray[_variableName][_key].length);
        uint256 lastIndex = storageUint256ToAddressArray[_variableName][_key].length - 1;
        storageUint256ToAddressArray[_variableName][_key][_index] = 
            storageUint256ToAddressArray[_variableName][_key][lastIndex];
        storageUint256ToAddressArray[_variableName][_key].length--;
    }

    function deleteStorageUint256ToString(string _variableName, uint256 _key) external {
        delete storageUint256ToString[_variableName][_key];
    }
    
    function deleteStorageAddressToAddressArray(string _variableName, address _key, uint256 _index) external {
        require(_index < storageAddressToAddressArray[_variableName][_key].length);
        uint256 lastIndex = storageAddressToAddressArray[_variableName][_key].length - 1;
        storageAddressToAddressArray[_variableName][_key][_index] = 
            storageAddressToAddressArray[_variableName][_key][lastIndex];
        storageAddressToAddressArray[_variableName][_key].length--;
    }

    function deleteStorageAddressToUint256Array(string _variableName, address _key, uint256 _index) external {
        require(_index < storageAddressToUint256Array[_variableName][_key].length);
        uint256 lastIndex = storageAddressToUint256Array[_variableName][_key].length - 1;
        storageAddressToUint256Array[_variableName][_key][_index] = 
            storageAddressToUint256Array[_variableName][_key][lastIndex];
        storageAddressToUint256Array[_variableName][_key].length--;
    }

    ///// GET
    function getArrayNameToItemsCount(string _variableName) external view returns (uint256) {
        return arrayNameToItemsCount[_variableName];
    }
    
    function getStorageBytes32ToBool(string _variableName, bytes32 _key) external view returns (bool) {
        return storageBytes32ToBool[_variableName][_key];
    }

    function getStorageUint8ToUint256Array(
        string _variableName, 
        uint8 _key, 
        uint256 _index
    ) 
        external 
        view 
        returns (uint256) 
    {
        require(storageUint8ToUint256Array[_variableName][_key].length > 0);
        require(_index < storageUint8ToUint256Array[_variableName][_key].length);
        return storageUint8ToUint256Array[_variableName][_key][_index];
    }

    function getStorageUint8ToUint256ArrayLength(string _variableName, uint8 _key) external view returns (uint256) {
        return storageUint8ToUint256Array[_variableName][_key].length;
    }

    function getStorageUint256ToBytes32Array(
        string _variableName,
        uint256 _key,
        uint256 _index
    )
        external
        view
        returns (bytes32)
    {
        require(storageUint256ToBytes32Array[_variableName][_key].length > 0);
        require(_index < storageUint256ToBytes32Array[_variableName][_key].length);
        return storageUint256ToBytes32Array[_variableName][_key][_index];
    }

    function getStorageUint256ToBytes32ArrayLength(string _variableName, uint256 _key) external view returns (uint256) {
        return storageUint256ToBytes32Array[_variableName][_key].length;
    }

    function getStorageUint256ToUint8Array(
        string _variableName,
        uint256 _key,
        uint256 _index
    ) 
        external 
        view 
        returns (uint8) 
    {
        require(storageUint256ToUint8Array[_variableName][_key].length > 0);
        require(_index < storageUint256ToUint8Array[_variableName][_key].length);
        return storageUint256ToUint8Array[_variableName][_key][_index];
    }
    
    function getStorageUint256ToUint8ArrayLength(string _variableName, uint256 _key) external view returns (uint256) {
        return storageUint256ToUint8Array[_variableName][_key].length;
    }

    function getStorageUint256ToUint16Array(
        string _variableName,
        uint256 _key,
        uint256 _index
    )
        external
        view
        returns (uint16)
    {
        require(storageUint256ToUint16Array[_variableName][_key].length > 0);
        require(_index < storageUint256ToUint16Array[_variableName][_key].length);
        return storageUint256ToUint16Array[_variableName][_key][_index];
    }

    function getStorageUint256ToUint16ArrayLength(string _variableName, uint256 _key) external view returns (uint256) {
        return storageUint256ToUint16Array[_variableName][_key].length;
    }

    function getStorageUint256ToUint64Array(
        string _variableName,
        uint256 _key,
        uint256 _index
    )
        external
        view
        returns (uint64)
    {
        require(storageUint256ToUint64Array[_variableName][_key].length > 0);
        require(_index < storageUint256ToUint64Array[_variableName][_key].length);
        return storageUint256ToUint64Array[_variableName][_key][_index];
    }

    function getStorageUint256ToUint64ArrayLength(string _variableName, uint256 _key) external view returns (uint256) {
        return storageUint256ToUint64Array[_variableName][_key].length;
    }

    function getStorageUint256ToUint256Array(
        string _variableName,
        uint256 _key,
        uint256 _index
    )
        external
        view
        returns (uint256)
    {
        require(storageUint256ToUint256Array[_variableName][_key].length > 0);
        require(_index < storageUint256ToUint256Array[_variableName][_key].length);
        return storageUint256ToUint256Array[_variableName][_key][_index];
    }

    function getStorageUint256ToUint256ArrayLength(string _variableName, uint256 _key) external view returns (uint256) {
        return storageUint256ToUint256Array[_variableName][_key].length;
    }

    function getStorageUint256ToAddressArray(
        string _variableName,
        uint256 _key,
        uint256 _index
    )
        external
        view
        returns (address)
    {
        require(storageUint256ToAddressArray[_variableName][_key].length > 0);
        require(_index < storageUint256ToAddressArray[_variableName][_key].length);
        return storageUint256ToAddressArray[_variableName][_key][_index];
    }

    function getStorageUint256ToAddressArrayLength(string _variableName, uint256 _key) external view returns (uint256) {
        return storageUint256ToAddressArray[_variableName][_key].length;
    }

    function getStorageUint256ToString(string _variableName, uint256 _key) external view returns (string) {
        return storageUint256ToString[_variableName][_key];
    }

    function getStorageAddressToAddressArray(
        string _variableName,
        address _key,
        uint256 _index
    )
        external
        view
        returns (address)
    {
        require(storageAddressToAddressArray[_variableName][_key].length > 0);
        require(_index < storageAddressToAddressArray[_variableName][_key].length);
        return storageAddressToAddressArray[_variableName][_key][_index];
    }

    function getStorageAddressToAddressArrayLength(string _variableName, address _key) external view returns (uint256) {
        return storageAddressToAddressArray[_variableName][_key].length;
    }

    function getStorageAddressToUint256Array(
        string _variableName,
        address _key,
        uint256 _index
    )
        external
        view
        returns (uint256)
    {
        require(storageAddressToUint256Array[_variableName][_key].length > 0);
        require(_index < storageAddressToUint256Array[_variableName][_key].length);
        return storageAddressToUint256Array[_variableName][_key][_index];
    }

    function getStorageAddressToUint256ArrayLength(string _variableName, address _key) external view returns (uint256) {
        return storageAddressToUint256Array[_variableName][_key].length;
    }

    function getStorageAddressToBool(string _variableName, address _key) external view returns (bool) {
        return storageAddressToBool[_variableName][_key];
    }
}