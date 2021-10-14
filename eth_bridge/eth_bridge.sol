// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

/// @title Ethereum Bridge Contract
/// @author Ken Alabi & Wenhai Li
/// @notice These are the functions for eth bridge
/// @dev 07/27/2021

/**
 * @dev Original Note
 * Implementation of the {Bridge} interface.
 * 	Written by Dr. Ken Alabi, July 18th 2021.
 *
 * This is the Admin contract. Changing owners and removing owners has been removed from this contract for secuirty
 * If there is a need to change owners or the ownership composition, the contract should best be changed and its funds transferred.
 *	Written by Dr. Ken Alabi, July 18th 2021.
 *
 * This is an implementation of a bridge between Ethereum and Toro network and vice versa.
 *
 * Eth deposits into this contract if the include their Toro address in the message section
 * will cause this contract to emit a message on the Ethereum network announcing the deposits
 * Scanners on the Toro network that run intermittently will then create the equivalent Toro
 * into the user's aaddress on the Toronetwork

 * In the inverse situation, the Toronet Network can request a withdrawal off the network
 * Also, the Toronet Network owners of the current contract can request
 * an automatic withdrawal of the Ethereum for a user when the equivalent Toro is burned and
 * a withdrawal is requested. However, withdrewals are implemented with a time lag
 * (setable but defaults to 24 hrs). On successful withdrawal, the Eth is transferred to
 * the indicated user's account. An admin is able to override a pending withdrawal
 */

contract EthBridge {

    /* ---------------------------------------------------- Variables ---------------------------------------------------- */

    address payable public owner;
    address[] public owners;
    uint256 public numberOfOwners;

    struct AutoWithdrawal {
        address payable eth_address;   	    // External ether address
        address toro_address;   			// Toronet address
        uint256 amount;                     // Amout to withdraw
        uint256 fee;
        uint256 date_Received;              // Request received date
        bool isCredited;                    // Check if the withdrawal has been processed
        uint256 date_Credited;              // Request processed date
        uint256 index;                      // Index in the pending array
        bool isWithdrawl;                   // Check if the withdrawal exists
    }

    mapping (bytes32 => AutoWithdrawal) public auto_withdrawals;

    bytes32[] public pending_auto_withdrawals;

    struct ManualWithdrawal {
        address payable eth_address;   	    // External ether address
        uint256 amount;                     // Amout to withdraw
        uint256 date_Received;              // Request received date
        bool isCredited;                    // Check if the withdrawal has been processed
        uint256 date_Credited;              // Request processed date
        mapping(address => bool) confirms;  // Confirms from owners
        uint256 numberOfConfirms;           // Number of confirms
        uint256 index;                      // Index in the pending array
        bool isWithdrawl;                   // Check if the withdrawal exists
    }

    mapping (bytes32 => ManualWithdrawal) public manual_withdrawals;

    bytes32[] public pending_manual_withdrawals;

    uint256 public required_NumberofMins;                         // Required Number of hours to implement a manual withdrawal

    uint256 public total_deposit;
    uint256 public total_withdraw;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    modifier onlyOwners {
        require(isOwners(msg.sender), "Function can only be called by an owner");
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Function can only be called by an owner");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    event AddOwner(address indexed newOwner);

    event RemoveOwner(address indexed newOwner);

    event TransferOwner(address indexed oldOwner, address indexed newOwner);

    event ReceivedEth(address indexed from, uint256 amount);

    event AddPendiungAutoWithdrawal(bytes32 id, address payable indexed eth_address, address indexed toro_address, uint256 amount, uint256 fee);

    event ProcessAutoWithdrawal(bytes32 id, address payable indexed eth_address, address indexed toro_address, uint256 amount, uint256 fee);

    event AddPendiungManualWithdrawal(bytes32 id, address payable indexed eth_address, uint256 amount);

    event ConfirmPendiungManualWithdrawal(bytes32 id, address indexed addr, uint256 count);

    event ProcessManualWithdrawal(bytes32 id, address payable indexed eth_address, uint256 amount);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    constructor (uint256 _Required_NumberofMins) {
        owner = payable(msg.sender);
        numberOfOwners = 0;

        owners.push(owner);
        numberOfOwners++;

        required_NumberofMins = _Required_NumberofMins;

        total_deposit = 0;
        total_withdraw = 0;
    }

    /* ------------------------------------------------- Owner Functions ------------------------------------------------- */

    function addOwner(address addr) public onlyOwner returns (bool) {
        require(!isOwners(addr), "The address is already an owner");

        owners.push(addr);
        numberOfOwners++;

        emit AddOwner(addr);
        return true;
    }

    function removeOwner(address addr) public onlyOwner returns (bool) {

        require(isOwners(addr), "The address is not an owner");

        for (uint256 i = 0; i < owners.length; i++) {
            if (addr == owners[i]) {
                owners[i] = owners[owners.length-1];
                delete owners[owners.length-1];
                owners.pop();
                numberOfOwners--;

                emit RemoveOwner(addr);
                return true;
            }
        }
        return false;
    }

    function isOwners(address addr) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (addr == owners[i]) return true;
        }
        return false;
    }

    function transferOwnership(address payable newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "The new owner cannot be null");
        require(newOwner != owner, "The new owner is same with the original owner");

        address oldOwner = owner;
        owner = newOwner;

        emit TransferOwner(oldOwner, newOwner);
        return true;
    }

    /* --------------------------------------------- Ether Receive Functions --------------------------------------------- */

    fallback() external payable {
        uint256 amount = msg.value;
        require(amount > 0, "Amount must be greater than 0");
        total_deposit += amount;

        emit ReceivedEth(msg.sender, amount);
    }

	receive() external payable {
		uint256 amount = msg.value;
        require(amount > 0, "Amount must be greater than 0");
        total_deposit += amount;

        emit ReceivedEth(msg.sender, amount);
	}

    /* ------------------------------------------------ View Auto Withdraw ----------------------------------------------- */

    function getNumberOfPendiungAutoWithdrawal() public view returns (uint256) {
        return pending_auto_withdrawals.length;
    }

    /* ------------------------------------------------ Add Auto Withdraw ------------------------------------------------ */

    function addPendiungAutoWithdrawal(bytes32 id, address payable eth_address, address toro_address, uint256 amount, uint256 fee) public onlyOwners returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        require(!auto_withdrawals[id].isWithdrawl, "Withdrawal request already exists");
        require(amount > fee, "Amount must be greater than fee");

        auto_withdrawals[id].eth_address = eth_address;
        auto_withdrawals[id].toro_address = toro_address;
        auto_withdrawals[id].amount = amount;
        auto_withdrawals[id].fee = fee;
        auto_withdrawals[id].date_Received = block.timestamp;
        auto_withdrawals[id].isCredited = false;

        pending_auto_withdrawals.push(id);
        auto_withdrawals[id].index = pending_auto_withdrawals.length - 1;
        auto_withdrawals[id].isWithdrawl = true;

        emit AddPendiungAutoWithdrawal(id, eth_address, toro_address, amount, fee);
        return true;
    }

    /* ---------------------------------------- Process Pending Auto Withdrawal ------------------------------------------ */

    function processPendiungAutoWithdrawals() public onlyOwners returns (bool) {
        uint256 count = pending_auto_withdrawals.length;
        if (count > 0) {
            for (uint256 i = count; i > 0; i--) {
                bytes32 id = pending_auto_withdrawals[i - 1];
                if ((auto_withdrawals[id].date_Received + required_NumberofMins * 1 minutes) < block.timestamp) {
                    if (address(this).balance >= auto_withdrawals[id].amount) {
                        if (auto_withdrawals[id].eth_address.send(auto_withdrawals[id].amount - auto_withdrawals[id].fee) && owner.send(auto_withdrawals[id].fee)) {
                            auto_withdrawals[id].isCredited = true;
                            auto_withdrawals[id].date_Credited = block.timestamp;
                            auto_withdrawals[id].index = 2**256 - 1;

                            pending_auto_withdrawals[i - 1] = pending_auto_withdrawals[pending_auto_withdrawals.length - 1];
                            auto_withdrawals[pending_auto_withdrawals[i - 1]].index = i - 1;
                            pending_auto_withdrawals.pop();

                            total_withdraw += auto_withdrawals[id].amount;

                            emit ProcessAutoWithdrawal(id, auto_withdrawals[id].eth_address, auto_withdrawals[id].toro_address, auto_withdrawals[id].amount, auto_withdrawals[id].fee);
                        }
                    }
                }
            }
        }
        return true;
    }

    /* ------------------------------------------------ View Auto Withdraw ----------------------------------------------- */

    function getNumberOfPendiungManualWithdrawal() public view returns (uint256) {
        return pending_manual_withdrawals.length;
    }

    /* ----------------------------------------------- Add Manual Withdraw ----------------------------------------------- */

    function addPendiungManualWithdrawal(bytes32 id, address payable eth_address, uint256 amount) public onlyOwners returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        require(!manual_withdrawals[id].isWithdrawl, "Withdrawal request already exists");

        manual_withdrawals[id].eth_address = eth_address;
        manual_withdrawals[id].amount = amount;
        manual_withdrawals[id].date_Received = block.timestamp;
        manual_withdrawals[id].isCredited = false;
        manual_withdrawals[id].numberOfConfirms = 0;

        pending_manual_withdrawals.push(id);
        manual_withdrawals[id].index = pending_manual_withdrawals.length - 1;
        manual_withdrawals[id].isWithdrawl = true;

        emit AddPendiungManualWithdrawal(id, eth_address, amount);
        return true;
    }

    /* --------------------------------------------- Confirm Manual Withdraw --------------------------------------------- */

    function confirmPendiungManualWithdrawal(bytes32 id) public onlyOwners returns (bool) {
        require(manual_withdrawals[id].isWithdrawl, "Withdrawal does not exist");
        require(!manual_withdrawals[id].isCredited, "Withdrawal has been processed");
        require(!manual_withdrawals[id].confirms[msg.sender], "WIthdrwal has been confirmed by the caller");
        manual_withdrawals[id].confirms[msg.sender] = true;
        manual_withdrawals[id].numberOfConfirms++;

        emit ConfirmPendiungManualWithdrawal(id, msg.sender, manual_withdrawals[id].numberOfConfirms);
        return true;
    }

    /* --------------------------------------- Process Pending Manual Withdrawal ----------------------------------------- */

    function processPendiungManualWithdrawals() public onlyOwners returns (bool) {
        uint256 count = pending_manual_withdrawals.length;
        if (count > 0) {
            for (uint256 i = count; i > 0; i--) {
                bytes32 id = pending_manual_withdrawals[i - 1];
                if (manual_withdrawals[id].numberOfConfirms * 2 > numberOfOwners) {
                    if ((manual_withdrawals[id].date_Received + required_NumberofMins * 1 minutes) < block.timestamp) {
                        if (address(this).balance >= manual_withdrawals[id].amount) {
                            if (manual_withdrawals[id].eth_address.send(manual_withdrawals[id].amount)) {
                                manual_withdrawals[id].isCredited = true;
                                manual_withdrawals[id].date_Credited = block.timestamp;
                                manual_withdrawals[id].index = 2**256 - 1;

                                pending_manual_withdrawals[i - 1] = pending_manual_withdrawals[pending_manual_withdrawals.length - 1];
                                manual_withdrawals[pending_manual_withdrawals[i - 1]].index = i - 1;
                                pending_manual_withdrawals.pop();

                                total_withdraw += manual_withdrawals[id].amount;

                                emit ProcessManualWithdrawal(id, manual_withdrawals[id].eth_address, manual_withdrawals[id].amount);
                            }
                        }
                    }
                }
            }
        }
        return true;
    }
}