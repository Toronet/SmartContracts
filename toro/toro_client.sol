// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Token Client Contract
/// @author Wenhai Li
/// @notice These are the client only functions to use the toro token
/// @dev 06/24/2021
contract ToroTokenClient {

    /* --------------------------------------------------- Variables --------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from toro enrolled account
    modifier onlyEnrolled {
        if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")))) {
            storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled", msg.sender)), true);
        }
        else {
            if (!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isenrolled", msg.sender)))) {
                revert("[toro.client] The address has not been enrolled as an toro account");
            }
        }
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to transfer toro
    /// @param from sender address
    /// @param to receiver address
    /// @param value transfer amount
    /// @param fee transfer fee
    event Transfer(address indexed from, address indexed to, uint256 value, uint256 fee);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[toro.client] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.toro.client")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* --------------------------------------------- Client Transfer Function -------------------------------------------- */

    /// @notice Client toro transfer
    /// @param to Receiver address
    /// @param value Transfer amount
    /// @dev note that only check allowance for sender, no allowance check for receiver
    function transfer(address to, uint256 value) public onlyEnrolled returns (bool) {
        require(msg.sender != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[toro.client] Invalid address to send toro");
        require(to != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", to))), "[toro.client] Invalid address to receive toro");
        require(msg.sender != to, "[toro.client] An address cannot send toro to itself");
        require(value > 0, "[toro.client] The ammount to send cannot be zero");
        require(storageContract.getBool(keccak256(abi.encodePacked("token.toro.on.transfer"))), "[toro.client] The toro transfer is currently unavailable");
        require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", msg.sender))), "[toro.client] The sender account has been freezed");
        require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", to))), "[toro.client] The receiver account has been freezed");
        if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", msg.sender)))) {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", msg.sender))), "[toro.client] The ammount to send is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", msg.sender))), "[toro.client] The ammount to send is too large");
        }
        else {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))), "[toro.client] The ammount to send is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))), "[toro.client] The ammount to send is too large");
        }
        uint256 txfee = _calculateTxFee(msg.sender, value);
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", msg.sender))) >= value + txfee, "[toro.client] Insufficient sender account balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", msg.sender)), value + txfee);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", to)), value);

        if (txfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(txfee);
                require(comm <= txfee, "[toro.client] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toller)), txfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toller)), txfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.totalfee")), txfee);
        }

        emit Transfer(msg.sender, to, value, txfee);
        return true;
    }

    /// @notice Calculate transfer fee
    /// @param val Transfer amount
    /// @dev Client can use this function before the transaction to get the potential transaction fee
    function calculateTxFee(uint256 val) public view returns (uint256) {
        return (_calculateTxFee(msg.sender, val));
    }

    function _calculateTxFee(address from, uint256 val) internal view returns (uint256) {
        uint256 txfee;
        uint256 txfee_fixed;
        uint256 txfee_percent;
        if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.txfee", from)))) {
            txfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", from)));
            txfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", from)));
        }
        else {
            txfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default")));
            txfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default")));
        }

        uint256 percent = val * txfee_percent / 100 / 1 ether;
        if (percent > txfee_fixed) {
            txfee = percent;
        }
        else {
            txfee = txfee_fixed;
        }
        return txfee;
    }

    function _calculateComm(uint256 txfee) internal view returns (uint256) {
        uint256 commissionPercentage = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.commission.percent")));
        uint256 commissionShare = txfee * commissionPercentage / 100 / 1 ether;
        return commissionShare;
    }
}