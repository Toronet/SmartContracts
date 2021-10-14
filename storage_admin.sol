// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage.sol";

/// @title Toronet Storage Management Contract
/// @author Wenhai Li
/// @notice These are the admin owner only functions to manage the storage
/// @dev 06/17/2021
contract ToronetStorageAdmin {

    /* --------------------------------------------------- Variables --------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from contract owner
    modifier onlyOwner {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[storage.admin] The function can only be called by the owner");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to turn storage on
    event StorageOn();

    /// @notice Event to turn storage off
    event StorageOff();

    /// @notice Event to register a contract
    /// @param version storage version
    /// @param addr contract address
    event RegisterContract(uint8 version, address indexed addr);

     /// @notice Event to unregister a contract
    /// @param version storage version
    /// @param addr contract address
    event UnregisterContract(uint8 version, address indexed addr);


    /// @notice Event to increase storage version
    event IncreaseVersion(uint8 oldVer, uint8 newVer);

    /// @notice Event to decreasae storage version
    event DecreaseVersion(uint8 oldVer, uint8 newVer);

    /// @notice Event to decreasae storage version
    /// @param val version value
    event SetVersion(uint8 val);

    /// @notice Event to transfer ownership
    /// @param oldOwner original owner
    /// @param newOwner new owner
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[storage.admin] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.storage.admin")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ------------------------------------------- Storage On/Off Functions ---------------------------------------------- */

    /// @notice Turn storage on
    function setStorageOn() public onlyOwner returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("storage.on")), true);
        emit StorageOn();
        return true;
    }

    /// @notice Turn storage off
    function setStorageOff() public onlyOwner returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("storage.on")), false);
        emit StorageOff();
        return true;
    }

    /// @notice Check if storage is on
    function isStorageOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("storage.on")));
    }

    /* ----------------------------------------------- Register Functions ------------------------------------------------ */

    /// @notice Register a contract with the current version of storage
    /// @param addr contract address
    function registerContract(address addr) public onlyOwner returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), addr)), true);
        emit RegisterContract(storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), addr);
        return true;
    }

    /// @notice Unregister a contract with the current version of storage
    /// @param addr contract address
    function unregisterContract(address addr) public onlyOwner returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), addr)), false);
        emit UnregisterContract(storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), addr);
        return true;
    }

    /// @notice Check if a contract has been registered with the current version of storage
    /// @param addr contract address
    function isContractRegistered(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), addr)));
    }

    /* ------------------------------------------------ Version Functions ------------------------------------------------ */

    /// @notice Increase the version of storage by 1
    function increaseStorageVersion() public onlyOwner returns (bool) {
        uint8 oldVer = storageContract.getUint8(keccak256(abi.encodePacked("storage.version")));
        storageContract.increaseUint8(keccak256(abi.encodePacked("storage.version")), 1);
        uint8 newVer = storageContract.getUint8(keccak256(abi.encodePacked("storage.version")));
        emit IncreaseVersion(oldVer, newVer);
        return true;
    }

    /// @notice Decrease the version of storage by 1
    function decreaseStorageVersion() public onlyOwner returns (bool) {
        require(storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))) > 0, "[storage.admin] Cannot decrease stroage version from zero");
        uint8 oldVer = storageContract.getUint8(keccak256(abi.encodePacked("storage.version")));
        storageContract.decreaseUint8(keccak256(abi.encodePacked("storage.version")), 1);
        uint8 newVer = storageContract.getUint8(keccak256(abi.encodePacked("storage.version")));
        emit DecreaseVersion(oldVer, newVer);
        return true;
    }

    /// @notice Set value to the version of storage
    /// @param val storage version value
    function setStorageVersion(uint8 val) public onlyOwner returns (bool) {
        storageContract.setUint8(keccak256(abi.encodePacked("storage.version")), val);
        emit SetVersion(val);
        return true;
    }

    /// @notice Get the version of storage
    function getStorageVersion() public view returns (uint256) {
        return storageContract.getUint8(keccak256(abi.encodePacked("storage.version")));
    }

    /* ------------------------------------------------- Owner Functions ------------------------------------------------- */

    /// @notice Transfer the ownership of the smart contracts
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) public onlyOwner returns (bool){
        require(newOwner != address(0), "[storage.admin] The new owner address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isassigned", newOwner))), "[storage.admin] The new owner has already been assigned a role");

        // Assign the new owner
        storageContract.setAddress(keccak256(abi.encodePacked("role.owner")), newOwner);
        storageContract.setBool(keccak256(abi.encodePacked("role.isowner", newOwner)), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", newOwner)), true);

        // Change tns for owner
        storageContract.setBytes32(keccak256(abi.encodePacked("tns.name", newOwner)), bytes32("owner"));
        storageContract.setAddress(keccak256(abi.encodePacked("tns.addr", bytes32("owner"))), newOwner);
        storageContract.setBool(keccak256(abi.encodePacked("tns.name.isused", bytes32("owner"))), true);
        storageContract.setBool(keccak256(abi.encodePacked("tns.addr.isassigned", newOwner)), true);

        storageContract.deleteBytes32(keccak256(abi.encodePacked("tns.name", msg.sender)));
        storageContract.deleteBool(keccak256(abi.encodePacked("tns.addr.isassigned", msg.sender)));

        // Remove the original owmer
        storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", msg.sender)));
        storageContract.deleteBool(keccak256(abi.encodePacked("role.isowner", msg.sender)));        // This must be the last call

        // Emit Event
        emit TransferOwnership(msg.sender, newOwner);
        return true;
    }

    /// @notice Check if an address is the owner
    /// @param addr the address
    function isOwner(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr)));
    }

    /// @notice Get the owner address
    /// @return owner address
    function getOwner() public view returns (address) {
        return storageContract.getAddress(keccak256(abi.encodePacked("role.owner")));
    }
}