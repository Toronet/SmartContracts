// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

/// @title Toronet Storage Contract
/// @author Wenhai Li
/// @notice This is the permanent data storage for all other toronet contracts
/// @dev 06/17/2021
contract ToronetStorage {

    /* --------------------------------------------------- Variables --------------------------------------------------- */

    /// @dev Storage types
    mapping(bytes32 => uint256)    private uInt256Storage;
    mapping(bytes32 => uint8)      private uInt8Storage;
    mapping(bytes32 => int256)     private int256Storage;
    mapping(bytes32 => int8)       private int8Storage;
    mapping(bytes32 => bytes32)    private bytes32Storage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bool)       private boolStorage;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls when the storage is turned on
    modifier onlyStorageOn() {
        require(boolStorage[keccak256(abi.encodePacked("storage.on"))] || boolStorage[keccak256(abi.encodePacked("role.isowner", tx.origin))], "[storage] The storage contract is currentlly offline");
        _;
    }

    /// @notice Only allow calls from the latest contracts
    modifier onlyLatestVersion() {
        require(boolStorage[keccak256(abi.encodePacked("storage.contract", uInt8Storage[keccak256(abi.encodePacked("storage.version"))], msg.sender))] || boolStorage[keccak256(abi.encodePacked("role.isowner", tx.origin))], "[storage] The caller contract is not the latest version");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Storage contract constructor
    constructor() {
        // Set the contract owner during the deployment
        addressStorage[keccak256(abi.encodePacked("role.owner"))] = msg.sender;
        boolStorage[keccak256(abi.encodePacked("role.isowner", msg.sender))] = true;
        boolStorage[keccak256(abi.encodePacked("role.isassigned", msg.sender))] = true;
        // Set contract version
        uInt8Storage[keccak256(abi.encodePacked("storage.version"))] = 0;
        // By default, the storage is turned off during the deployment
        boolStorage[keccak256(abi.encodePacked("storage.on"))] = false;
        emit Deploy(address(this));
    }

    /* ----------------------------------------------- uint256 Functions ------------------------------------------------- */

    /// @notice Get a uint256 value based on key
    /// @param key The key for the record
    function getUint256(bytes32 key) external view returns (uint256) {
        return uInt256Storage[key];
    }

    /// @notice Set a uint256 value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setUint256(bytes32 key, uint256 value) external onlyStorageOn onlyLatestVersion {
        uInt256Storage[key] = value;
    }

    /// @notice Increase a uint256 record by a value
    /// @param key The key for the record
    /// @param value The value to increase for the record
    function increaseUint256(bytes32 key, uint256 value) external onlyStorageOn onlyLatestVersion {
        require((uInt256Storage[key] + value) >= uInt256Storage[key], "[storage] uint256 overflow");
        uInt256Storage[key] = uInt256Storage[key] + value;
    }

    /// @notice Decrease a uint256 record by a value
    /// @param key The key for the record
    /// @param value The value to decrease for the record
    function decreaseUint256(bytes32 key, uint256 value) external onlyStorageOn onlyLatestVersion {
        require((uInt256Storage[key] - value) <= uInt256Storage[key], "[storage] uint256 underflow");
        uInt256Storage[key] = uInt256Storage[key] - value;
    }

    /// @notice Delete a uint256 value based on key
    /// @param key The key for the record
    function deleteUint256(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete uInt256Storage[key];
    }

    /* ------------------------------------------------ uint8 Functions -------------------------------------------------- */

    /// @notice Get a uint8 value based on key
    /// @param key The key for the record
    function getUint8(bytes32 key) external view returns (uint8) {
        return uInt8Storage[key];
    }

    /// @notice Set a uint8 value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setUint8(bytes32 key, uint8 value) external onlyStorageOn onlyLatestVersion {
        uInt8Storage[key] = value;
    }

    /// @notice Increase a uint8 record by a value
    /// @param key The key for the record
    /// @param value The value to increase for the record
    function increaseUint8(bytes32 key, uint8 value) external onlyStorageOn onlyLatestVersion {
        require((uInt8Storage[key] + value) >= uInt8Storage[key], "[storage] uint8 overflow");
        uInt8Storage[key] = uInt8Storage[key] + value;
    }

    /// @notice Decrease a uint8 record by a value
    /// @param key The key for the record
    /// @param value The value to decrease for the record
    function decreaseUint8(bytes32 key, uint8 value) external onlyStorageOn onlyLatestVersion {
        require((uInt8Storage[key] - value) <= uInt8Storage[key], "[storage] uint8 underflow");
        uInt8Storage[key] = uInt8Storage[key] - value;
    }

    /// @notice Delete a uint8 value based on key
    /// @param key The key for the record
    function deleteUint8(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete uInt8Storage[key];
    }

    /* ------------------------------------------------ int256 Functions ------------------------------------------------- */

    /// @notice Get a int256 value based on key
    /// @param key The key for the record
    function getInt256(bytes32 key) external view returns (int256) {
        return int256Storage[key];
    }

    /// @notice Set a int256 value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setInt256(bytes32 key, int256 value) external onlyStorageOn onlyLatestVersion {
        int256Storage[key] = value;
    }

    /// @notice Increase a int256 record by a value
    /// @param key The key for the record
    /// @param value The value to increase for the record
    function increaseInt256(bytes32 key, int256 value) external onlyStorageOn onlyLatestVersion {
        require((int256Storage[key] + value >= int256Storage[key]), "[storage] int256 overflow");
        int256Storage[key] = int256Storage[key] + value;
    }

    /// @notice Decrease a int256 record by a value
    /// @param key The key for the record
    /// @param value The value to decrease for the record
    function decreaseInt256(bytes32 key, int256 value) external onlyStorageOn onlyLatestVersion {
        require((int256Storage[key] - value <= int256Storage[key]), "[storage] int256 underflow");
        int256Storage[key] = int256Storage[key] - value;
    }

    /// @notice Delete a int256 value based on key
    /// @param key The key for the record
    function deleteInt256(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete int256Storage[key];
    }

    /* ------------------------------------------------- int8 Functions -------------------------------------------------- */

    /// @notice Get a int8 value based on key
    /// @param key The key for the record
    function getInt8(bytes32 key) external view returns (int8) {
        return int8Storage[key];
    }

    /// @notice Set a int8 value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setInt8(bytes32 key, int8 value) external onlyStorageOn onlyLatestVersion {
        int8Storage[key] = value;
    }

    /// @notice Increase a int8 record by a value
    /// @param key The key for the record
    /// @param value The value to increase for the record
    function increaseInt8(bytes32 key, int8 value) external onlyStorageOn onlyLatestVersion {
        require((int8Storage[key] + value >= int8Storage[key]), "[storage] int8 overflow");
        int8Storage[key] = int8Storage[key] + value;
    }

    /// @notice Decrease a int8 record by a value
    /// @param key The key for the record
    /// @param value The value to decrease for the record
    function decreaseInt8(bytes32 key, int8 value) external onlyStorageOn onlyLatestVersion {
        require((int8Storage[key] - value <= int8Storage[key]), "[storage] int8 underflow");
        int8Storage[key] = int8Storage[key] - value;
    }

    /// @notice Delete a int8 value based on key
    /// @param key The key for the record
    function deleteInt8(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete int8Storage[key];
    }

    /* ----------------------------------------------- bytes32 Functions ------------------------------------------------- */

    /// @notice Get a bytes32 value based on key
    /// @param key The key for the record
    function getBytes32(bytes32 key) external view returns (bytes32) {
        return bytes32Storage[key];
    }

    /// @notice Set a bytes32 value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setBytes32(bytes32 key, bytes32 value) external onlyStorageOn onlyLatestVersion {
        bytes32Storage[key] = value;
    }

    /// @notice Delete a bytes32 value based on key
    /// @param key The key for the record
    function deleteBytes32(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete bytes32Storage[key];
    }

    /* ------------------------------------------------ bytes Functions -------------------------------------------------- */

    /// @notice Get a bytes value based on key
    /// @param key The key for the record
    function getBytes(bytes32 key) external view returns (bytes memory) {
        return bytesStorage[key];
    }

    /// @notice Set a bytes value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setBytes(bytes32 key, bytes memory value) public onlyStorageOn onlyLatestVersion{
        bytesStorage[key] = value;
    }

    /// @notice Delete a bytes value based on key
    /// @param key The key for the record
    function deleteBytes(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete bytesStorage[key];
    }

    /* ------------------------------------------------ string Functions ------------------------------------------------- */

    /// @notice Get a string value based on key
    /// @param key The key for the record
    function getString(bytes32 key) external view returns (string memory) {
        return stringStorage[key];
    }

    /// @notice Set a string value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setString(bytes32 key, string memory value) public onlyStorageOn onlyLatestVersion {
        stringStorage[key] = value;
    }

    /// @notice Delete a string value based on key
    /// @param key The key for the record
    function deleteString(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete stringStorage[key];
    }

    /* ------------------------------------------------ address Functions ------------------------------------------------ */

    /// @notice Get an address value based on key
    /// @param key The key for the record
    function getAddress(bytes32 key) external view returns (address) {
        return addressStorage[key];
    }

    /// @notice Set an address value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setAddress(bytes32 key, address value) external onlyStorageOn onlyLatestVersion {
        addressStorage[key] = value;
    }

    /// @notice Delete an address value based on key
    /// @param key The key for the record
    function deleteAddress(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete addressStorage[key];
    }

    /* ------------------------------------------------- bool Functions -------------------------------------------------- */

    /// @notice Get a bool value based on key
    /// @param key The key for the record
    function getBool(bytes32 key) external view returns (bool) {
        return boolStorage[key];
    }

    /// @notice Set a bool value based on key
    /// @param key The key for the record
    /// @param value The value for the record
    function setBool(bytes32 key, bool value) external onlyStorageOn onlyLatestVersion {
        boolStorage[key] = value;
    }

    /// @notice Delete a bool value based on key
    /// @param key The key for the record
    function deleteBool(bytes32 key) external onlyStorageOn onlyLatestVersion {
        delete boolStorage[key];
    }
}