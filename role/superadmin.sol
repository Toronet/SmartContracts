// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Super Admin Role Contract
/// @author Wenhai Li
/// @notice These are the functions to manage super admin role
/// @dev 06/20/2021
contract ToronetSuperAdmin {

    /* --------------------------------------------------- Variables --------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from contract owner
    modifier onlyOwner {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[role.superadmin] The function can only be called by the owner");
        _;
    }

    /// @notice Only allow calls from debugger
    modifier onlyDebugger {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))), "[role.superadmin] The function can only be called by a debugger");
        _;
    }

    /// @notice Only allow calls from super admin
    modifier onlySuperAdmin {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))), "[role.superadmin] The function can only be called by a super admin");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to initialize contract
    event Init();

    /// @notice Event to add a new super admin
    /// @param addr Super admin address
    event AddSuperAdmin(address indexed addr);

    /// @notice Event to remove an existing super admin
    /// @param addr super admin address
    event RemoveSuperAdmin(address indexed addr);

    /// @notice Event to remove all existing super admin
    /// @param num originial number of super admins
    event RemoveAllSuperAdmins(uint256 num);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Super admin contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[role.superadmin] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.role.superadmin", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))))), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ----------------------------------------------- Initialize Contract ----------------------------------------------- */

    /// @notice Initialize super admin contract
    /// @dev only called when the first time deploy the contract, do not call it during the contract update process
    function initSuperAdmin() public onlyOwner returns (bool) {
        storageContract.setUint256(keccak256(abi.encodePacked("role.superadmin.number")), 0);
        emit Init();
        return true;
    }

    /* ------------------------------------------------ Add a Super Admin ------------------------------------------------ */

    /// @notice Assign a new super admin
    /// @param addr The new super admin address
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function addSuperAdmin(address addr) public onlySuperAdmin returns(bool) {
        require(addr != address(0), "[role.superadmin] The new super admin address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isassigned", addr))), "[role.superadmin] The address has already been assigned a role");

        uint256 currentIndex = storageContract.getUint256(keccak256(abi.encodePacked("role.superadmin.number")));

        storageContract.setAddress(keccak256(abi.encodePacked("role.superadmin.list", currentIndex)), addr);
        storageContract.setUint256(keccak256(abi.encodePacked("role.superadmin.index", addr)), currentIndex);
        storageContract.increaseUint256(keccak256(abi.encodePacked("role.superadmin.number")), 1);

        storageContract.setBool(keccak256(abi.encodePacked("role.issuperadmin", addr)), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", addr)), true);

        emit AddSuperAdmin(addr);
        return true;
    }

    /* ----------------------------------------------- Remove a Super Admin ---------------------------------------------- */

    /// @notice Remove an existing super admin
    /// @param addr The existing super admin address
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function removeSuperAdmin(address addr) public onlySuperAdmin returns(bool) {
        require(addr != address(0), "[role.superadmin] The super admin address cannot be null");
        require(addr != msg.sender, "[role.superadmin] A super admin cannot remove itself");
        require(storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))), "[role.superadmin] The address is not assigned as a super admin");

        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.superadmin.number")));
        address lastAddr = storageContract.getAddress(keccak256(abi.encodePacked("role.superadmin.list", number - 1)));
        uint256 currIndex = storageContract.getUint256(keccak256(abi.encodePacked("role.superadmin.index", addr)));

        storageContract.setAddress(keccak256(abi.encodePacked("role.superadmin.list", currIndex)), lastAddr);
        storageContract.deleteAddress(keccak256(abi.encodePacked("role.superadmin.list", number - 1)));
        storageContract.setUint256(keccak256(abi.encodePacked("role.superadmin.index", lastAddr)), currIndex);
        storageContract.deleteUint256(keccak256(abi.encodePacked("role.superadmin.index", addr)));

        storageContract.deleteBool(keccak256(abi.encodePacked("role.issuperadmin", addr)));
        storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", addr)));

        storageContract.decreaseUint256(keccak256(abi.encodePacked("role.superadmin.number")), 1);

        emit RemoveSuperAdmin(addr);
        return true;
    }

    /* ---------------------------------------------- Remove all Debuggers ----------------------------------------------- */

    /// @notice Remove all existing super admins
    /// @dev can only be called by a debugger or the contract owner
    function removeAllSuperAdmins() public onlyDebugger returns(bool) {
        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.superadmin.number")));
        if (number > 0) {
            for (uint256 i = number; i > 0; i--) {
                address addr = storageContract.getAddress(keccak256(abi.encodePacked("role.superadmin.list", i - 1)));
                storageContract.deleteAddress(keccak256(abi.encodePacked("role.superadmin.list", i - 1)));
                storageContract.deleteUint256(keccak256(abi.encodePacked("role.superadmin.index", addr)));
                storageContract.deleteBool(keccak256(abi.encodePacked("role.issuperadmin", addr)));
                storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", addr)));
            }
        }
        storageContract.setUint256(keccak256(abi.encodePacked("role.superadmin.number")), 0);

        emit RemoveAllSuperAdmins(number);
        return true;
    }

    /* ------------------------------------------------- View Functions -------------------------------------------------- */

    /// @notice Check if an address is a super admin
    /// @param addr address to test
    function isSuperAdmin(address addr) public view returns(bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr)));
    }

    /// @notice Get the index of the address in the super admin list
    /// @param addr address to query
    /// @return index is the index of the super admin
    /// @return err is the error code; 0 - no error; 1 - the address is not a super admin
    function getSuperAdminIndex(address addr) public view returns(uint256 index, uint256 err) {
        index = uint256(2**256 - 1);
        err = 0;
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr)))) {
            err = 1;
            return (index, err);
        } else {
            index = storageContract.getUint256(keccak256(abi.encodePacked("role.superadmin.index", addr)));
            return (index, 0);
        }
    }

    /// @notice Get the total number of the existing super admins
    function getNumberOfSuperAdmin() public view returns(uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("role.superadmin.number")));
    }

    /// @notice Get the super admin address by given index
    /// @param index the index of super admin
    /// @return addr the super admin address
    /// @return err is the error code; 0 - no error; 1 - no existing super admin found; 2 - invalid index
    function getSuperAdminByIndex(uint256 index) public view returns(address addr, uint256 err) {
        addr = address(0x0);
        err = 0;
        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("role.superadmin.number")));
        if (number == 0) {
            err = 1;
            return (addr, err);
        }
        if (index > number - 1) {
            err = 2;
            return (addr, err);
        }
        addr = storageContract.getAddress(keccak256(abi.encodePacked("role.superadmin.list", index)));
        return (addr, err);
    }

}