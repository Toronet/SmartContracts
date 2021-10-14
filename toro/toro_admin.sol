// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Token Super Admin Management Contract
/// @author Wenhai Li
/// @notice These are the admin only functions to manage the toro token
/// @dev 06/24/2021
contract ToroTokenAdmin {

    /* --------------------------------------------------- Variables --------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from admin
    modifier onlyAdmin {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[toro.admin] The function can only be called by an admin");
        _;
    }

    /// @notice Only allow calls from digital admin
    modifier onlyDigitalAdmin {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[toro.admin] The function can only be called by an admin");
        _;
    }

    /// @notice Only allow calls from client
    modifier onlyClient (address addr) {
        require(addr != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[dollar.admin] Address is not a valid client address");
        _;
    }

    /// @notice Only allow calls from approved client
    modifier onlyApprovedClient (address addr) {
        require(addr != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[toro.admin] Address is not a valid client address");
        require(!(storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.client.isapproved", addr)))), "[toro.admin] Admin calls are not approved by the client");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to manually enroll an address as a toro account
    /// @param addr address to enroll
    event EnrollToroAccount(address indexed addr);

    /// @notice Event to manually disenroll an address as a toro account
    /// @param addr address to disenroll
    event DisenrollToroAccount(address indexed addr);

    /// @notice Event to freeze a toro account
    /// @param addr address to freeze
    event FreezeToroAccount(address indexed addr);

    /// @notice Event to unfreeze a toro account
    /// @param addr address to unfreeze
    event UnfreezeToroAccount(address indexed addr);

    /// @notice Event to allow account-specified transfer allowance for an account
    /// @param addr address to allow
    event AllowSelfAllowance(address indexed addr);

    /// @notice Event to disallow account-specified transfer allowance for an account
    /// @param addr address to allow
    event DisallowSelfAllowance(address indexed addr);

    /// @notice Event to set the account-specified minimum transfer allowance
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfMinimumAllowance(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified maximum transfer allowance
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfMaximumAllowance(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified minimum and maximum transfer allowance
    /// @param addr address to set
    /// @param oldMin original minimum value
    /// @param newMin new minimum value
    /// @param oldMax original maximum value
    /// @param newMax new maximum value
    event SetSelfAllowance(address indexed addr, uint256 oldMin, uint256 newMin, uint256 oldMax, uint256 newMax);

    /// @notice Event to allow account-specified transaction fee
    /// @param addr address to allow
    event AllowSelfTransactionFee(address indexed addr);

    /// @notice Event to disallow account-specified transaction fee
    /// @param addr address to disallow
    event DisallowSelfTransactionFee(address indexed addr);

    /// @notice Event to set the account-specified fixed transactio fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfTransactionFeeFixed(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified percentage transactio fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfTransactionFeePercentage(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified fixed and percentage transactio fee
    /// @param addr address to set
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetSelfTransactionFee(address indexed addr, uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to transfer toro by admin
    /// @param from sender address
    /// @param to receiver address
    /// @param value transfer amount
    /// @param fee transfer fee
    event AdminTransfer(address indexed from, address indexed to, uint256 value, uint256 fee);

    /// @notice Event to transfer toro by admin with custom transaction fee
    /// @param from sender address
    /// @param to receiver address
    /// @param value transfer amount
    /// @param fee custom transfer fee
    event AdminTransferWithCustomFee(address indexed from, address indexed to, uint256 value, uint256 fee);

    /// @notice Event to mint toro in an account by admin
    /// @param addr address to mint
    /// @param value mint amount
    event Mint(address addr, uint256 value);

    /// @notice Event to burn toro in an account by admin
    /// @param addr address to burn
    /// @param value burn amount
    event Burn(address addr, uint256 value);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[toro.admin] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.toro.admin")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ---------------------------------------------- Management Functions ----------------------------------------------- */

    /// @notice Manually enroll an address as a toro account
    /// @param addr The address to enroll
    /// @dev The function is only used when AllowSelfEnroll is false
    function enrollToroAccount(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled", addr)), true);
        emit EnrollToroAccount(addr);
        return true;
    }

    /// @notice Manually disenroll an address as a toro account
    /// @param addr The address to disenroll
    /// @dev The function is only used when AllowSelfEnroll is false
    function disenrollToroAccount(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled", addr)), false);
        emit DisenrollToroAccount(addr);
        return true;
    }

    /// @notice Freeze a toro account
    /// @param addr The address to freeze
    function freezeToroAccount(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr)), true);
        emit FreezeToroAccount(addr);
        return true;
    }

    /// @notice Unfreeze a toro account
    /// @param addr The address to unfreeze
    function unfreezeToroAccount(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr)), false);
        emit UnfreezeToroAccount(addr);
        return true;
    }

    /// @notice Allow account-specified transfer allowance for an account
    /// @param addr The address of the account
    function allowSelfAllowance(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr))), "[toro.admin] The account-specified allowance is currently activated");
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr)), true);
        if (storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr)), storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))));
        }
        if (storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr)), storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))));
        }
        emit AllowSelfAllowance(addr);
        return true;
    }

    /// @notice Disallow account-specified transfer allowance for an account
    /// @param addr The address of the account
    function disallowSelfAllowance(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr))), "[toro.admin] The account-specified allowance is currently deactivated");
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr)), false);
        emit DisallowSelfAllowance(addr);
        return true;
    }

    /// @notice Set account-specified transfer minimum allowance for an account
    /// @param addr The address of the account
    /// @param newMinimumAmount the new minimum allowance
    function setSelfMinimumAllowance(address addr, uint256 newMinimumAmount) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr)));
        require(newMinimumAmount != oldMinimumAmount, "[toro.admin] The account-specified minimum allowance is not changed");
        uint256 currentMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr)));
        require(newMinimumAmount < currentMaximumAmount, "[toro.admin] The account-specified minimum allowance value is too large");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr)), newMinimumAmount);
        emit SetSelfMinimumAllowance(addr, oldMinimumAmount, newMinimumAmount);
        return true;
    }

    /// @notice Set account-specified transfer maximum allowance for an account
    /// @param addr The address of the account
    /// @param newMaximumAmount the new maximum allowance
    function setSelfMaximumAllowance(address addr, uint256 newMaximumAmount) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr)));
        require(newMaximumAmount != oldMaximumAmount, "[toro.admin] The account-specified maximum allowance is not changed");
        uint256 currentMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr)));
        require(newMaximumAmount > currentMinimumAmount, "[toro.admin] The account-specified maximum allowance value is too small");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr)), newMaximumAmount);
        emit SetSelfMaximumAllowance(addr, oldMaximumAmount, newMaximumAmount);
        return true;
    }

    /// @notice Set account-specified transfer minimum and maximum allowance for an account
    /// @param addr The address of the account
    /// @param newMinimumAmount the new minimum allowance
    /// @param newMaximumAmount the new maximum allowance
    function setSelfAllowance(address addr, uint256 newMinimumAmount, uint256 newMaximumAmount) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newMinimumAmount < newMaximumAmount, "[toro.admin] The max/min values are invalid");
        uint256 oldMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr)));
        uint256 oldMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr)));
        require (newMinimumAmount != oldMinimumAmount || newMaximumAmount != oldMaximumAmount, "[toro.admin] No change in account-specified allowance values");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr)), newMinimumAmount);
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr)), newMaximumAmount);
        emit SetSelfAllowance(addr, oldMinimumAmount, newMinimumAmount, oldMaximumAmount, newMaximumAmount);
        return true;
    }

    /// @notice Allow account-specified transfer fee for an account
    /// @param addr The address of the account
    function allowSelfTransactionFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.txfee", addr))), "[toro.admin] The account-specified transaction fee is currently activated");
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.allowself.txfee", addr)), true);
        if (storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", addr)), storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default"))));
        }
        if (storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", addr)), storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default"))));
        }
        emit AllowSelfTransactionFee(addr);
        return true;
    }

    /// @notice Disallow account-specified transfer fee for an account
    /// @param addr The address of the account
    function disallowSelfTransactionFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.txfee", addr))), "[toro.admin] The account-specified transaction fee is currently deactivated");
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.allowself.txfee", addr)), false);
        emit DisallowSelfTransactionFee(addr);
        return true;
    }

    /// @notice Set account-specified fixed transaction fee for an account
    /// @param addr The address of the account
    /// @param newTransactionFeeFixed the new fixed transaction fee
    function setSelfTransactionFeeFixed(address addr, uint256 newTransactionFeeFixed) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldTransactionFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", addr)));
        require(newTransactionFeeFixed != oldTransactionFeeFixed, "[toro.admin] The account-specified fixed transaction fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", addr)), newTransactionFeeFixed);
        emit SetSelfTransactionFeeFixed(addr, oldTransactionFeeFixed, newTransactionFeeFixed);
        return true;
    }

    /// @notice Set account-specified percentage transaction fee for an account
    /// @param addr The address of the account
    /// @param newTransactionFeePercentage the new percentage transaction fee
    function setSelfTransactionFeePercentage(address addr, uint256 newTransactionFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newTransactionFeePercentage <= 100 * 1 ether, "[toro.admin] The account-specified percentage transaction fee is invalid");
        uint256 oldTransactionFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", addr)));
        require(newTransactionFeePercentage != oldTransactionFeePercentage, "[toro.admin] The account-specified percentage transaction fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", addr)), newTransactionFeePercentage);
        emit SetSelfTransactionFeePercentage(addr, oldTransactionFeePercentage, newTransactionFeePercentage);
        return true;
    }

    /// @notice Set account-specified fixed and percentage transaction fee for an account
    /// @param addr The address of the account
    /// @param newTransactionFeeFixed the new fixed transaction fee
    /// @param newTransactionFeePercentage the new percentage transaction fee
    function setSelfTransactionFee(address addr, uint256 newTransactionFeeFixed, uint256 newTransactionFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newTransactionFeePercentage <= 100 * 1 ether, "[toro.admin] The account-specified percentage transaction fee is invalid");
        uint256 oldTransactionFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", addr)));
        uint256 oldTransactionFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", addr)));
        require(newTransactionFeeFixed != oldTransactionFeeFixed || newTransactionFeePercentage != oldTransactionFeePercentage, "[toro.admin] No change in account-specified transaction fee");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", addr)), newTransactionFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", addr)), newTransactionFeePercentage);
        emit SetSelfTransactionFee(addr, oldTransactionFeeFixed, newTransactionFeeFixed, oldTransactionFeePercentage, newTransactionFeePercentage);
        return true;
    }

    /* -------------------------------------------- Admin Transfer Functions --------------------------------------------- */

    /// @notice Transfer toro from one address to another by admin
    /// @param from the sender address
    /// @param to the receiver address
    /// @param value the transfer amount
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, toro enrollment, transfer allowance, account frozen
    function adminTransfer(address from, address to, uint256 value) public onlyAdmin onlyApprovedClient(from) returns (bool) {
        require(from != address(0), "[toro.admin] The sender address cannot be null");
        require(to != address(0), "[toro.admin] The receiver address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", from))), "[toro.admin] The sender address cannot be a reserve");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", to))), "[toro.admin] The receiver address cannot be a reserve");
        require(from != to, "[toro.admin] An address cannot send toro to itself");
        require(value > 0, "[toro.admin] The ammount to send cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", from))), "[toro.admin] Invalid address to send toro");
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", to))), "[toro.admin] Invalid address to receive toro");
            require(storageContract.getBool(keccak256(abi.encodePacked("token.toro.on.transfer"))), "[toro.admin] The toro transfer is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled",from)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isenrolled", from)))) {
                    revert("[toro.admin] The sender address has not been enrolled as an toro account");
                }
            }
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled",to)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isenrolled", to)))) {
                    revert("[toro.admin] The receiver address has not been enrolled as an toro account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", from))), "[toro.admin] The sender account has been freezed");
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", to))), "[toro.admin] The receiver account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", from)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", from))), "[toro.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", from))), "[toro.admin] The ammount to send is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))), "[toro.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))), "[toro.admin] The ammount to send is too large");
            }
        }

        uint256 txfee = _calculateTxFee(from, value);
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", from))) >= value + txfee, "[toro.admin] Insufficient sender account balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", from)), value + txfee);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", to)), value);

        if (txfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(txfee);
                require(comm <= txfee, "[toro.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toller)), txfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toller)), txfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.totalfee")), txfee);
        }

        emit AdminTransfer(from, to, value, txfee);
        return true;
    }

    /// @notice Transfer toro from one address to another by admin with custom transaction fee
    /// @param from the sender address
    /// @param to the receiver address
    /// @param value the transfer amount
    /// @param txfee the custom transaction fee
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, toro enrollment, transfer allowance, account frozen
    function adminTransferWithCustomFee(address from, address to, uint256 value, uint256 txfee) public onlyAdmin onlyApprovedClient(from) returns (bool) {
        require(from != address(0), "[toro.admin] The sender address cannot be null");
        require(to != address(0), "[toro.admin] The receiver address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", from))), "[toro.admin] The sender address cannot be a reserve");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", to))), "[toro.admin] The receiver address cannot be a reserve");
        require(from != to, "[toro.admin] An address cannot send toro to itself");
        require(value > 0, "[toro.admin] The ammount to send cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", from))), "[toro.admin] Invalid address to send toro");
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", to))), "[toro.admin] Invalid address to receive toro");
            require(storageContract.getBool(keccak256(abi.encodePacked("token.toro.on.transfer"))), "[toro.admin] The toro transfer is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled",from)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isenrolled", from)))) {
                    revert("[toro.admin] The sender address has not been enrolled as an toro account");
                }
            }
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled",to)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isenrolled", to)))) {
                    revert("[toro.admin] The receiver address has not been enrolled as an toro account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", from))), "[toro.admin] The sender account has been freezed");
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", to))), "[toro.admin] The receiver account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", from)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", from))), "[toro.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", from))), "[toro.admin] The ammount to send is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))), "[toro.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))), "[toro.admin] The ammount to send is too large");
            }
        }

        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", from))) >= value + txfee, "[toro.admin] Insufficient sender account balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", from)), value + txfee);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", to)), value);

        if (txfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(txfee);
                require(comm <= txfee, "[toro.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toller)), txfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toller)), txfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.totalfee")), txfee);
        }

        emit AdminTransferWithCustomFee(from, to, value, txfee);
        return true;
    }

    /// @notice Calculate transfer fee
    /// @param from Sender account
    /// @param val Transfer amount
    /// @dev Admin can use this function before the transaction to get the potential transaction fee
    function adminCalculateTxFee(address from, uint256 val) public view returns (uint256) {
        return (_calculateTxFee(from, val));
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

    /* ------------------------------------------- Client Mint/Burn Functions -------------------------------------------- */

    /// @notice Mint toro in an account
    /// @param addr address to mint
    /// @param value amount to mint
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, toro enrollment, transfer allowance, account frozen
    function mint(address addr, uint256 value) public onlyDigitalAdmin onlyClient(addr) returns (bool) {
        require(addr != address(0), "[toro.admin] The mint address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[toro.admin] The mint address cannot be a reserve");
        require(value > 0, "[toro.admin] The mint value cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[toro.admin] Invalid address to mint toro");
            require(storageContract.getBool(keccak256(abi.encodePacked("token.toro.on.mint"))), "[toro.admin] The toro mint is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled",addr)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isenrolled", addr)))) {
                    revert("[toro.admin] The mint address has not been enrolled as an toro account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr))), "[toro.admin] The mint account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr))), "[toro.admin] The ammount to mint is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr))), "[toro.admin] The ammount to mint is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))), "[toro.admin] The ammount to mint is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))), "[toro.admin] The ammount to mint is too large");
            }
        }
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", addr)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.totalcap")), value);
        emit Mint(addr, value);
        return true;
    }

    /// @notice Burn toro in an account
    /// @param addr address to burn
    /// @param value amount to burn
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, toro enrollment, transfer allowance, account frozen
    function burn(address addr, uint256 value) public onlyDigitalAdmin onlyClient(addr) returns (bool) {
        require(addr != address(0), "[toro.admin] The burn address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[toro.admin] The burn address cannot be a reserve");
        require(value > 0, "[toro.admin] The burn value cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[toro.admin] Invalid address to mint toro");
            require(storageContract.getBool(keccak256(abi.encodePacked("token.toro.on.burn"))), "[toro.admin] The toro burn is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("token.toro.isenrolled",addr)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isenrolled", addr)))) {
                    revert("[toro.admin] The burn address has not been enrolled as an toro account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr))), "[toro.admin] The burn account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr))), "[toro.admin] The ammount to burn is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr))), "[toro.admin] The ammount to burn is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))), "[toro.admin] The ammount to burn is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))), "[toro.admin] The ammount to burn is too large");
            }
        }
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", addr))) >= value, "[toro.admin] Burn value is too large");
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.totalcap"))) >= value, "[toro.admin] Burn value is too large");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", addr)), value);
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.totalcap")), value);
        emit Burn(addr, value);
        return true;
    }
}