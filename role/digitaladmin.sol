// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Admin Role Contract
/// @author Wenhai Li
/// @notice These are the functions to manage digital admin role
/// @dev 09/29/2021
contract ToronetDigitalAdmin {

    /* ---------------------------------------------------- Variables ---------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from contract owner
    modifier onlyOwner {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[role.digitaladmin] The function can only be called by the owner");
        _;
    }

    /// @notice Only allow calls from super admin
    modifier onlySuperAdmin {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))), "[role.digitaladmin] The function can only be called by a super admin");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to initialize contract
    event Init();

    /// @notice Event to add a new digital admin
    /// @param addr digital admin address
    event AddDigitalAdmin(address indexed addr);

    /// @notice Event to remove an existing digital admin
    /// @param addr digital admin address
    event RemoveDigitalAdmin(address indexed addr);

    /// @notice Event to remove all existing digital admin
    /// @param num originial number of digital admins
    event RemoveAllDigitalAdmins(uint256 num);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Admin contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[role.digitaladmin] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.role.digitaladmin", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))))), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ----------------------------------------------- Initialize Contract ----------------------------------------------- */

    /// @notice Initialize digital admin contract
    /// @dev only called when the first time deploy the contract, do not call it during the contract update process
    function initDigitalAdmin() public onlyOwner returns (bool) {
        storageContract.setUint256(keccak256(abi.encodePacked("role.digitaladmin.number")), 0);
        emit Init();
        return true;
    }

    /* --------------------------------------------------- Add a Digital Admin -------------------------------------------------- */

    /// @notice Assign a new digital admin admin
    /// @param addr The new digital admin admin address
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function addDigitalAdmin(address addr) public onlySuperAdmin returns(bool) {
        require(addr != address(0), "[role.digitaladmin] The new digital admin address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isassigned", addr))), "[role.digitaladmin] The address has already been assigned a role");

        uint256 currentIndex = storageContract.getUint256(keccak256(abi.encodePacked("role.digitaladmin.number")));

        storageContract.setAddress(keccak256(abi.encodePacked("role.digitaladmin.list", currentIndex)), addr);
        storageContract.setUint256(keccak256(abi.encodePacked("role.digitaladmin.index", addr)), currentIndex);
        storageContract.increaseUint256(keccak256(abi.encodePacked("role.digitaladmin.number")), 1);

        storageContract.setBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr)), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", addr)), true);

        emit AddDigitalAdmin(addr);
        return true;
    }

    /* ------------------------------------------------- Remove a Digital Admin ------------------------------------------------- */

    /// @notice Remove an existing digital admin
    /// @param addr The existing digital admin address
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function removeDigitalAdmin(address addr) public onlySuperAdmin returns(bool) {
        require(addr != address(0), "[role.digitaladmin] The admin address cannot be null");
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[role.digitaladmin] The address is not assigned as a digital admin");

        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.digitaladmin.number")));
        address lastAddr = storageContract.getAddress(keccak256(abi.encodePacked("role.digitaladmin.list", number - 1)));
        uint256 currIndex = storageContract.getUint256(keccak256(abi.encodePacked("role.digitaladmin.index", addr)));

        storageContract.setAddress(keccak256(abi.encodePacked("role.digitaladmin.list", currIndex)), lastAddr);
        storageContract.deleteAddress(keccak256(abi.encodePacked("role.digitaladmin.list", number - 1)));
        storageContract.setUint256(keccak256(abi.encodePacked("role.digitaladmin.index", lastAddr)), currIndex);
        storageContract.deleteUint256(keccak256(abi.encodePacked("role.digitaladmin.index", addr)));

        storageContract.deleteBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr)));
        storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", addr)));

        storageContract.decreaseUint256(keccak256(abi.encodePacked("role.digitaladmin.number")), 1);

        emit RemoveDigitalAdmin(addr);
        return true;
    }

    /* ------------------------------------------------ Remove all Digital Admins ------------------------------------------------ */

    /// @notice Remove all existing digital admins
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function removeAllDigitalAdmins() public onlySuperAdmin returns(bool) {
        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.digitaladmin.number")));
        if (number > 0) {
            for (uint256 i = number; i > 0; i--) {
                address addr = storageContract.getAddress(keccak256(abi.encodePacked("role.digitaladmin.list", i - 1)));
                storageContract.deleteAddress(keccak256(abi.encodePacked("role.digitaladmin.list", i - 1)));
                storageContract.deleteUint256(keccak256(abi.encodePacked("role.digitaladmin.index", addr)));
                storageContract.deleteBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr)));
                storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", addr)));
            }
        }
        storageContract.setUint256(keccak256(abi.encodePacked("role.digitaladmin.number")), 0);

        emit RemoveAllDigitalAdmins(number);
        return true;
    }

    /* ------------------------------------------------- View Functions -------------------------------------------------- */

    /// @notice Check if an address is a digital admin
    /// @param addr address to test
    function isDigitalAdmin(address addr) public view returns(bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr)));
    }

    /// @notice Get the index of the address in the digital admin list
    /// @param addr address to query
    /// @return index is the index of the digital admin
    /// @return err is the error code; 0 - no error; 1 - the address is not a digital admin
    function getDigitalAdminIndex(address addr) public view returns(uint256 index, uint256 err) {
        index = uint256(2**256 - 1);
        err = 0;
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr)))) {
            err = 1;
            return (index, err);
        } else {
            index = storageContract.getUint256(keccak256(abi.encodePacked("role.digitaladmin.index", addr)));
            return (index, 0);
        }
    }

    /// @notice Get the total number of the existing digital admins
    function getNumberOfDigitalAdmin() public view returns(uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("role.digitaladmin.number")));
    }

    /// @notice Get the digital admin address by given index
    /// @param index the index of digital admin
    /// @return addr the digital admin address
    /// @return err is the error code; 0 - no error; 1 - no existing digital admin found; 2 - invalid index
    function getDigitalAdminByIndex(uint256 index) public view returns(address addr, uint256 err) {
        addr = address(0x0);
        err = 0;
        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.digitaladmin.number")));
        if (number == 0) {
            err = 1;
            return (addr, err);
        }
        if (index > number - 1) {
            err = 2;
            return (addr, err);
        }
        addr = storageContract.getAddress(keccak256(abi.encodePacked("role.digitaladmin.list", index)));
        return (addr, err);
    }
}