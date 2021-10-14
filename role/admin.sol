// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Admin Role Contract
/// @author Wenhai Li
/// @notice These are the functions to manage admin role
/// @dev 06/20/2021
contract ToronetAdmin {

    /* ---------------------------------------------------- Variables ---------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from contract owner
    modifier onlyOwner {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[role.admin] The function can only be called by the owner");
        _;
    }

    /// @notice Only allow calls from super admin
    modifier onlySuperAdmin {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))), "[role.admin] The function can only be called by a super admin");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to initialize contract
    event Init();

    /// @notice Event to add a new admin
    /// @param addr admin address
    event AddAdmin(address indexed addr);

    /// @notice Event to remove an existing admin
    /// @param addr admin address
    event RemoveAdmin(address indexed addr);

    /// @notice Event to remove all existing admin
    /// @param num originial number of admins
    event RemoveAllAdmins(uint256 num);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Admin contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[role.admin] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.role.admin", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))))), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ----------------------------------------------- Initialize Contract ----------------------------------------------- */

    /// @notice Initialize admin contract
    /// @dev only called when the first time deploy the contract, do not call it during the contract update process
    function initAdmin() public onlyOwner returns (bool) {
        storageContract.setUint256(keccak256(abi.encodePacked("role.admin.number")), 0);
        emit Init();
        return true;
    }

    /* --------------------------------------------------- Add an Admin -------------------------------------------------- */

    /// @notice Assign a new admin
    /// @param addr The new admin address
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function addAdmin(address addr) public onlySuperAdmin returns(bool) {
        require(addr != address(0), "[role.admin] The new admin address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isassigned", addr))), "[role.admin] The address has already been assigned a role");

        uint256 currentIndex = storageContract.getUint256(keccak256(abi.encodePacked("role.admin.number")));

        storageContract.setAddress(keccak256(abi.encodePacked("role.admin.list", currentIndex)), addr);
        storageContract.setUint256(keccak256(abi.encodePacked("role.admin.index", addr)), currentIndex);
        storageContract.increaseUint256(keccak256(abi.encodePacked("role.admin.number")), 1);

        storageContract.setBool(keccak256(abi.encodePacked("role.isadmin", addr)), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", addr)), true);

        emit AddAdmin(addr);
        return true;
    }

    /* ------------------------------------------------- Remove an Admin ------------------------------------------------- */

    /// @notice Remove an existing admin
    /// @param addr The existing admin address
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function removeAdmin(address addr) public onlySuperAdmin returns(bool) {
        require(addr != address(0), "[role.admin] The admin address cannot be null");
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))), "[role.admin] The address is not assigned as an admin");

        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.admin.number")));
        address lastAddr = storageContract.getAddress(keccak256(abi.encodePacked("role.admin.list", number - 1)));
        uint256 currIndex = storageContract.getUint256(keccak256(abi.encodePacked("role.admin.index", addr)));

        storageContract.setAddress(keccak256(abi.encodePacked("role.admin.list", currIndex)), lastAddr);
        storageContract.deleteAddress(keccak256(abi.encodePacked("role.admin.list", number - 1)));
        storageContract.setUint256(keccak256(abi.encodePacked("role.admin.index", lastAddr)), currIndex);
        storageContract.deleteUint256(keccak256(abi.encodePacked("role.admin.index", addr)));

        storageContract.deleteBool(keccak256(abi.encodePacked("role.isadmin", addr)));
        storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", addr)));

        storageContract.decreaseUint256(keccak256(abi.encodePacked("role.admin.number")), 1);

        emit RemoveAdmin(addr);
        return true;
    }

    /* ------------------------------------------------ Remove all Admins ------------------------------------------------ */

    /// @notice Remove all existing admins
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function removeAllAdmins() public onlySuperAdmin returns(bool) {
        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.admin.number")));
        if (number > 0) {
            for (uint256 i = number; i > 0; i--) {
                address addr = storageContract.getAddress(keccak256(abi.encodePacked("role.admin.list", i - 1)));
                storageContract.deleteAddress(keccak256(abi.encodePacked("role.admin.list", i - 1)));
                storageContract.deleteUint256(keccak256(abi.encodePacked("role.admin.index", addr)));
                storageContract.deleteBool(keccak256(abi.encodePacked("role.isadmin", addr)));
                storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", addr)));
            }
        }
        storageContract.setUint256(keccak256(abi.encodePacked("role.admin.number")), 0);

        emit RemoveAllAdmins(number);
        return true;
    }

    /* ------------------------------------------------- View Functions -------------------------------------------------- */

    /// @notice Check if an address is an admin
    /// @param addr address to test
    function isAdmin(address addr) public view returns(bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr)));
    }

    /// @notice Get the index of the address in the admin list
    /// @param addr address to query
    /// @return index is the index of the admin
    /// @return err is the error code; 0 - no error; 1 - the address is not an admin
    function getAdminIndex(address addr) public view returns(uint256 index, uint256 err) {
        index = uint256(2**256 - 1);
        err = 0;
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr)))) {
            err = 1;
            return (index, err);
        } else {
            index = storageContract.getUint256(keccak256(abi.encodePacked("role.admin.index", addr)));
            return (index, 0);
        }
    }

    /// @notice Get the total number of the existing admins
    function getNumberOfAdmin() public view returns(uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("role.admin.number")));
    }

    /// @notice Get the admin address by given index
    /// @param index the index of admin
    /// @return addr the admin address
    /// @return err is the error code; 0 - no error; 1 - no existing admin found; 2 - invalid index
    function getAdminByIndex(uint256 index) public view returns(address addr, uint256 err) {
        addr = address(0x0);
        err = 0;
        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.admin.number")));
        if (number == 0) {
            err = 1;
            return (addr, err);
        }
        if (index > number - 1) {
            err = 2;
            return (addr, err);
        }
        addr = storageContract.getAddress(keccak256(abi.encodePacked("role.admin.list", index)));
        return (addr, err);
    }
}