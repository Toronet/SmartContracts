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
 * This is the Admin contract. Changing owners and removing owners has been removed from this contract for security
 * If there is a need to change owners or the ownership composition, the contract should best be changed and its funds transferred.
 *	Written by Dr. Ken Alabi, July 18th 2021.
 *
 * This is an implementation of a bridge between Ethereum and Toro network and vice versa.
 *
 * Eth deposits into this contract
 * will cause this contract to emit a message on the Ethereum network announcing the deposits
 * Scanners on the Toro network that run intermittently will then create the equivalent Eth
 * into the user's aaddress on the Toronetwork
 * If they include their ToroNet address in the message section, the deposit address will be the address isgned into the message
 * If they linked their Ethereum address, the deposit address will be the linked Toronet address
 * If no target address is indicated, the target address on the Toronet network will be the same address as the Ethereum address
 * Since primary keys do not collide and are always unique, the user's keys on the Ethereum network will unlock the same address on Toronetwork.

 * In the inverse situation, the Toronet Network can request a withdrawal off the network
 * Also, the Toronet Network owners of the current contract can request
 * an automatic withdrawal of the Ethereum for a user when the equivalent Toro is burned and
 * a withdrawal is requested. However, withdrewals are implemented with a time lag
 * On successful withdrawal, the Eth is transferred to
 * the indicated user's account. An admin is able to override a pending withdrawal
 * Oct 28 2021 - Added functions to potentially remove pending auto and manual withdrawals - Dr. Ken Alabi.
 & Dec 21 2022 - Even though this is only internally called, add a reentrancy protection out of an abundance of security caution. See https://cointelegraph.com/news/defi-protocol-grim-finance-lost-30m-in-5x-reentrancy-hack
 * Jan 20 2022 - Modify tne AddOWner and RemoveOwber functions to require the same majority owner confirmation as a manual withdrawal - Dr. Ken Alabi.
 & Jan 21 2022 - Add a pause function out of an abundance of security caution. See https://cointelegraph.com/news/multichain-asks-users-to-revoke-approvals-amid-critical-vulnerability
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
        bool isWithdrawal;                  // Check if the withdrawal exists
    }
    mapping (bytes32 => AutoWithdrawal) public auto_withdrawals;
    bytes32[] public pending_auto_withdrawals;


    struct ManualWithdrawal {
        address payable eth_address;   	    					// External ether address
        uint256 amount;                     					// Amout to withdraw
        uint256 date_Received;              					// Request received date
        bool isCredited;                    					// Check if the withdrawal has been processed
        uint256 date_Credited;              					// Request processed date
        mapping(address => bool) confirms;  					// Confirms from owners
        uint256 numberOfConfirms;           					// Number of confirms
        uint256 index;                      					// Index in the pending array
        bool isWithdrawal;                  					// Check if the withdrawal exists
    }
    mapping (bytes32 => ManualWithdrawal) public manual_withdrawals;
    bytes32[] public pending_manual_withdrawals;



    struct ProposedOwner {
        bool isProcessed;                   					// Check if the request has been processed
        uint256 date_Received;              					// Request received date
        uint256 date_Processed;             					// Request processed date
        mapping(address => bool) confirms;  					// Confirms from owners
        uint256 numberOfConfirms;           					// Number of confirms
        uint256 index;                      					// Index in the pending array
        bool isRequest;                     					// Check if the request exists
    }
    mapping (address => ProposedOwner) public ProposedOwners;
    address[] public pending_ProposedOwners;


    struct ProposedRemoveOwner {
        bool isProcessed;                   					// Check if the request has been processed
        uint256 date_Received;              					// Request received date
        uint256 date_Processed;             					// Request processed date
        mapping(address => bool) confirms;  					// Confirms from owners
        uint256 numberOfConfirms;           					// Number of confirms
        uint256 index;                      					// Index in the pending array
        bool isRequest;                     					// Check if the request exists
    }
    mapping (address => ProposedRemoveOwner) public ProposedRemoveOwners;
    address[] public pending_ProposedRemoveOwners;


    uint256 public required_NumberofMins;                         // Required Number of hours to implement an auto withdrawal
    uint256 public required_NumberofMinsManual;                   // Required Number of hours to implement a manual withdrawal
    uint256 public required_NumberofMinsOwner;                    // Required Number of hours to implement an new owner addition or renewal
    bool public pause_Withdrawals;                    		  	  // Add a pause option to add another layer of protection to the network. Jan 21 2022
    bool public pause_Deposit;

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

    // Rentrancy protection Dec 21 2021
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    /* ----------------------------------------------------- Events ------------------------------------------------------ */

	event AddProposedOwner (address indexed newOwner);

    event ConfirmOwner(address indexed newOwner, address indexed addr, uint256 count);

    event AddOwner(address indexed newOwner);

	event AddRemoveOwner (address indexed oldOwner);

    event ConfirmRemoveOwner(address indexed oldOwner, address indexed addr, uint256 count);

    event RemoveOwner(address indexed oldOwner);

    event TransferOwner(address indexed oldOwner, address indexed newOwner);

    event ReceivedEth(address indexed from, uint256 amount);

    event AddAutoWithdrawal(bytes32 id, address payable indexed eth_address, address indexed toro_address, uint256 amount, uint256 fee);

    event RemoveAutoWithdrawal(bytes32 id, address payable indexed eth_address, address indexed toro_address, uint256 amount, uint256 fee);

    event ProcessAutoWithdrawal(bytes32 id, address payable indexed eth_address, address indexed toro_address, uint256 amount, uint256 fee);

    event AddManualWithdrawal(bytes32 id, address payable indexed eth_address, uint256 amount);

    event RemoveManualWithdrawal(bytes32 id, address payable indexed eth_address, uint256 amount);

    event ConfirmManualWithdrawal(bytes32 id, address indexed addr, uint256 count);

    event ProcessManualWithdrawal(bytes32 id, address payable indexed eth_address, uint256 amount);
	

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    constructor (uint256 _Required_NumberofMins, uint256 _required_NumberofMinsManual, uint256 _required_NumberofMinsOwner) {
        owner = payable(msg.sender);
        numberOfOwners = 0;

        owners.push(owner);
        numberOfOwners++;

        required_NumberofMins = _Required_NumberofMins;
		required_NumberofMinsManual = _required_NumberofMinsManual;
		required_NumberofMinsOwner = _required_NumberofMinsOwner;

        total_deposit = 0;
        total_withdraw = 0;

        _status = _NOT_ENTERED;

		pause_Withdrawals = false;
        pause_Deposit = false;

    }

    /* ------------------------------------------------- Owner Functions ------------------------------------------------- */

    function addOwner(address addr) public onlyOwner returns (bool) {
        require(addr != address(0), "An owner cannot be null");
        require(!isOwners(addr), "The address is already an owner");


        require(!ProposedOwners[addr].isRequest, "Pending request already exists for this owner address");

        ProposedOwners[addr].date_Received = block.timestamp;
        ProposedOwners[addr].isProcessed = false;
        ProposedOwners[addr].numberOfConfirms = 0;

        pending_ProposedOwners.push(addr);
        ProposedOwners[addr].index = pending_ProposedOwners.length - 1;
		ProposedOwners[addr].isRequest = true;

        emit AddProposedOwner(addr);
        return true;
    }

    function confirmOwner(address addr) public onlyOwners returns (bool) {
        require(ProposedOwners[addr].isRequest, "Pending request does not exist for this owner address");
        require(!ProposedOwners[addr].isProcessed, "Request has been processed");
        //require(!ProposedOwners[addr].confirms[msg.sender], "Request has already been confirmed by the caller");

		if (!ProposedOwners[addr].confirms[msg.sender]) {
			ProposedOwners[addr].confirms[msg.sender] = true;
			ProposedOwners[addr].numberOfConfirms++;
			emit ConfirmOwner(addr, msg.sender, ProposedOwners[addr].numberOfConfirms);
		}

		//if number of confirmations have been reached, then process the request
		if (ProposedOwners[addr].numberOfConfirms * 2 > numberOfOwners) {
			if ((ProposedOwners[addr].date_Received + required_NumberofMinsOwner * 1 minutes) < block.timestamp) {
					    owners.push(addr);
						numberOfOwners++;
						emit AddOwner(addr);

						ProposedOwners[addr].isProcessed = true;
						ProposedOwners[addr].date_Processed = block.timestamp;

                        uint256 i = ProposedOwners[addr].index;
						ProposedOwners[addr].index = 2**256 - 1;

						pending_ProposedOwners[i] = pending_ProposedOwners[pending_ProposedOwners.length - 1];
						ProposedOwners[pending_ProposedOwners[i]].index = i;
						pending_ProposedOwners.pop();

			}
		}

        return true;
    }

    function removeOwner(address addr) public onlyOwner returns (bool) {

        require(addr != owner, "Cannot remove contract initiator");

        require(isOwners(addr), "The address is not an owner");

        require(!ProposedRemoveOwners[addr].isRequest, "Pending request already exists for removing this owner address");

        ProposedRemoveOwners[addr].date_Received = block.timestamp;
        ProposedRemoveOwners[addr].isProcessed = false;
        ProposedRemoveOwners[addr].numberOfConfirms = 0;

        pending_ProposedRemoveOwners.push(addr);
        ProposedRemoveOwners[addr].index = pending_ProposedRemoveOwners.length - 1;
		ProposedRemoveOwners[addr].isRequest = true;

        emit AddRemoveOwner(addr);
        return false;
    }

    function confirmRemoveOwner(address addr) public onlyOwners returns (bool) {
        require(ProposedRemoveOwners[addr].isRequest, "Pending request does not exist for removing this owner address");
        require(!ProposedRemoveOwners[addr].isProcessed, "Request has been processed");
        //require(!ProposedRemoveOwners[addr].confirms[msg.sender], "Request has already been confirmed by this caller");

		if (!ProposedRemoveOwners[addr].confirms[msg.sender]) {
			ProposedRemoveOwners[addr].confirms[msg.sender] = true;
			ProposedRemoveOwners[addr].numberOfConfirms++;
			emit ConfirmRemoveOwner(addr, msg.sender, ProposedRemoveOwners[addr].numberOfConfirms);
		}

		//if number of confirmations have been reached, then process the request
		if (ProposedRemoveOwners[addr].numberOfConfirms * 2 > numberOfOwners) {
			if ((ProposedRemoveOwners[addr].date_Received + required_NumberofMinsOwner * 1 minutes) < block.timestamp) {

					for (uint256 i = 0; i < owners.length; i++) {
						if (addr == owners[i]) {
							owners[i] = owners[owners.length-1];
							delete owners[owners.length-1];
							owners.pop();
							numberOfOwners--;
							emit RemoveOwner(addr);

                            ProposedRemoveOwners[addr].isProcessed = true;
                            ProposedRemoveOwners[addr].date_Processed = block.timestamp;
                            ProposedRemoveOwners[addr].index = 2**256 - 1;

                            for (uint256 j = pending_ProposedRemoveOwners.length; j > 0; j--) {
                                if (pending_ProposedRemoveOwners[j - 1] == addr) {
                                    pending_ProposedRemoveOwners[j - 1] = pending_ProposedRemoveOwners[pending_ProposedOwners.length - 1];
                                    ProposedRemoveOwners[pending_ProposedOwners[j - 1]].index = j - 1;
                                    pending_ProposedRemoveOwners.pop();
                                }
                            }

							return true;
						}
					}
			}
		}
        return true;
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

    function pauseWithdrawal() public onlyOwner returns (bool) {
        pause_Withdrawals = true;
        return false;
    }

    function resumeWithdrawal() public onlyOwner returns (bool) {
        pause_Withdrawals = false;
        return false;
    }

    function pauseDeposit() public onlyOwner returns (bool) {
        pause_Deposit = true;
        return false;
    }

    function resumeDeposit() public onlyOwner returns (bool) {
        pause_Deposit = false;
        return false;
    }

    /* --------------------------------------------- Ether Receive Functions --------------------------------------------- */

    fallback() external payable {
        require(!pause_Deposit, "Deposits are currently paused");

        uint256 amount = msg.value;
        require(amount > 0, "Amount must be greater than 0");
        total_deposit += amount;

        emit ReceivedEth(msg.sender, amount);
    }

	receive() external payable {
        require(!pause_Deposit, "Deposits are currently paused");

		uint256 amount = msg.value;
        require(amount > 0, "Amount must be greater than 0");
        total_deposit += amount;

        emit ReceivedEth(msg.sender, amount);
	}

    /* ------------------------------------------------ View Auto Withdraw ----------------------------------------------- */

    function getNumberOfAutoWithdrawal() public view returns (uint256) {
        return pending_auto_withdrawals.length;
    }

    /* ------------------------------------------------ Add Auto Withdraw ------------------------------------------------ */

    function addAutoWithdrawal(bytes32 id, address payable eth_address, address toro_address, uint256 amount, uint256 fee) public onlyOwners returns (bool) {
        require(eth_address != address(0), "Eth Address cannot be null");
        require(amount > 0, "Amount must be greater than 0");
        require(!auto_withdrawals[id].isWithdrawal, "Withdrawal request already exists");
        require(amount > fee, "Amount must be greater than fee");

        auto_withdrawals[id].eth_address = eth_address;
        auto_withdrawals[id].toro_address = toro_address;
        auto_withdrawals[id].amount = amount;
        auto_withdrawals[id].fee = fee;
        auto_withdrawals[id].date_Received = block.timestamp;
        auto_withdrawals[id].isCredited = false;

        pending_auto_withdrawals.push(id);
        auto_withdrawals[id].index = pending_auto_withdrawals.length - 1;
        auto_withdrawals[id].isWithdrawal = true;

        emit AddAutoWithdrawal(id, eth_address, toro_address, amount, fee);
        return true;
    }

    /* ------------------------------------------------ Remove Auto Withdraw ------------------------------------------------ */

    function removeAutoWithdrawal(bytes32 id) public onlyOwners returns (bool) {
        require(auto_withdrawals[id].isWithdrawal, "Withdrawal request does not exists");

        uint256 count = pending_auto_withdrawals.length;
        if (count > 0) {
            for (uint256 i = count; i > 0; i--) {
                if (id == pending_auto_withdrawals[i - 1]) {
                    //auto_withdrawals[id].index = 2**256 - 1;

                    pending_auto_withdrawals[i - 1] = pending_auto_withdrawals[pending_auto_withdrawals.length - 1];
                    auto_withdrawals[pending_auto_withdrawals[i - 1]].index = i - 1;
                    pending_auto_withdrawals.pop();

                    emit RemoveAutoWithdrawal(id, auto_withdrawals[id].eth_address, auto_withdrawals[id].toro_address, auto_withdrawals[id].amount, auto_withdrawals[id].fee);
                }
            }
        }
        return true;
    }

    /* ---------------------------------------- Process Pending Auto Withdrawal ------------------------------------------ */

    function processAutoWithdrawals() public onlyOwners nonReentrant returns (bool) {
		require(!pause_Withdrawals, "Withdrawals are currently paused");
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
                        else {
                            revert("Failed auto withdrawals (transfer)");
                        }
                    }
                }
            }
        }
        _status = _NOT_ENTERED;
        return true;
    }

    /* ------------------------------------------------ View Auto Withdraw ----------------------------------------------- */

    function getNumberOfManualWithdrawal() public view returns (uint256) {
        return pending_manual_withdrawals.length;
    }

    /* ----------------------------------------------- Add Manual Withdraw ----------------------------------------------- */

    function addManualWithdrawal(bytes32 id, address payable eth_address, uint256 amount) public onlyOwners returns (bool) {
        require(eth_address != address(0), "Eth Address cannot be null");
        require(amount > 0, "Amount must be greater than 0");
        require(!manual_withdrawals[id].isWithdrawal, "Withdrawal request already exists");

        manual_withdrawals[id].eth_address = eth_address;
        manual_withdrawals[id].amount = amount;
        manual_withdrawals[id].date_Received = block.timestamp;
        manual_withdrawals[id].isCredited = false;
        manual_withdrawals[id].numberOfConfirms = 0;

        pending_manual_withdrawals.push(id);
        manual_withdrawals[id].index = pending_manual_withdrawals.length - 1;
        manual_withdrawals[id].isWithdrawal = true;

        emit AddManualWithdrawal(id, eth_address, amount);
        return true;
    }

    /* --------------------------------------------- Confirm Manual Withdraw --------------------------------------------- */

    function confirmManualWithdrawal(bytes32 id) public onlyOwners returns (bool) {
		require(!pause_Withdrawals, "Withdrawals are currently paused");
        require(manual_withdrawals[id].isWithdrawal, "Withdrawal does not exist");
        require(!manual_withdrawals[id].isCredited, "Withdrawal has been processed");
        //require(!manual_withdrawals[id].confirms[msg.sender], "WIthdrawal has been confirmed by the caller");
        if (!manual_withdrawals[id].confirms[msg.sender]) {
			manual_withdrawals[id].confirms[msg.sender] = true;
			manual_withdrawals[id].numberOfConfirms++;
		}

        emit ConfirmManualWithdrawal(id, msg.sender, manual_withdrawals[id].numberOfConfirms);

		//if the required number of confirms is reached, then complete the withdrawal
		if (manual_withdrawals[id].numberOfConfirms * 2 > numberOfOwners) {
			if ((manual_withdrawals[id].date_Received + required_NumberofMinsManual * 1 minutes) < block.timestamp) {
				if (address(this).balance >= manual_withdrawals[id].amount) {
					if (manual_withdrawals[id].eth_address.send(manual_withdrawals[id].amount)) {
						manual_withdrawals[id].isCredited = true;
						manual_withdrawals[id].date_Credited = block.timestamp;

                        uint256 i = manual_withdrawals[id].index;
						manual_withdrawals[id].index = 2**256 - 1;

						pending_manual_withdrawals[i] = pending_manual_withdrawals[pending_manual_withdrawals.length - 1];
						manual_withdrawals[pending_manual_withdrawals[i]].index = i;
						pending_manual_withdrawals.pop();

						total_withdraw += manual_withdrawals[id].amount;

						emit ProcessManualWithdrawal(id, manual_withdrawals[id].eth_address, manual_withdrawals[id].amount);
					}
					else {
						revert("Failed manual withdrawals (transfer).");
					}
				}
			}
		}

        return true;
    }

    /* --------------------------------------------- Remove Manual Withdraw --------------------------------------------- */

    function removeManualWithdrawal(bytes32 id) public onlyOwners returns (bool) {
        require(manual_withdrawals[id].isWithdrawal, "Withdrawal does not exist");
        require(!manual_withdrawals[id].isCredited, "Withdrawal has been processed");

        uint256 count = pending_manual_withdrawals.length;
        if (count > 0) {
            for (uint256 i = count; i > 0; i--) {
                if (id == pending_manual_withdrawals[i - 1]) {

                        //manual_withdrawals[id].index = 2**256 - 1;

                        pending_manual_withdrawals[i - 1] = pending_manual_withdrawals[pending_manual_withdrawals.length - 1];
                        manual_withdrawals[pending_manual_withdrawals[i - 1]].index = i - 1;
                        pending_manual_withdrawals.pop();

                        emit RemoveManualWithdrawal(id, manual_withdrawals[id].eth_address, manual_withdrawals[id].amount);

                }
            }
        }
        return true;

    }
	
}
