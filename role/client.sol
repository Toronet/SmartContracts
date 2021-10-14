// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Client Role Contract
/// @author Wenhai Li
/// @notice These are the functions to manage client role
/// @dev 09/29/2021
contract ToronetClient {

    /* ---------------------------------------------------- Variables ---------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from admin
    modifier onlyAdmin {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[role.client] The function can only be called by an admin");
        _;
    }

    /// @notice Only allow calls from client
    modifier onlyClient (address addr) {
        require(addr != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[role.client] Address is not a valid client address");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event for client approve admin calls
    /// @param addr client address
    event Approve(address indexed addr);

    /// @notice Event for client disapprove admin calls
    /// @param addr client address
    event Disapprove(address indexed addr);

    /// @notice Event for admin approve admin calls
    /// @param addr client address
    event AdminApprove(address indexed addr);

    /// @notice Event for admin disapprove admin calls
    /// @param addr client address
    event AdminDisapprove(address indexed addr);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Admin contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[role.client] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.role.client", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))))), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* -------------------------------------------------- Client Approve ------------------------------------------------- */

    /// @notice Client approve admin calls
    function approve() public onlyClient(msg.sender) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("role.client.isapproved", msg.sender)), true);
        emit Approve(msg.sender);
        return true;
    }

    /* ------------------------------------------------- Client Disapprove ----------------------------------------------- */

    /// @notice Client disapprove admin calls
    function disapprove() public onlyClient(msg.sender) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("role.client.isapproved", msg.sender)), false);
        emit Disapprove(msg.sender);
        return true;
    }

    /* -------------------------------------------------- Admin Approve -------------------------------------------------- */

    /// @notice Approve admin calls by admin
    function adminApprove(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("role.client.isapproved", addr)), true);
        emit AdminApprove(addr);
        return true;
    }

    /* ------------------------------------------------- Admin Disapprove ------------------------------------------------ */

    /// @notice Disapprove admin calls by admin
    function adminDisapprove(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("role.client.isapproved", addr)), false);
        emit AdminDisapprove(addr);
        return true;
    }

    /* -------------------------------------------------- View Functions ------------------------------------------------- */

    /// @notice Check if an address is a client
    /// @param addr address to test
    function isClient(address addr) public view returns(bool) {
        return addr != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr)));
    }

    /// @notice Check if admin calls are approved
    /// @param addr address to test
    function isApproved(address addr) public view returns(bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("role.client.isapproved", addr)));
    }
}