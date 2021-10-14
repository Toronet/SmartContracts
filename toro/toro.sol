// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Token Contract
/// @author Wenhai Li
/// @notice These are the functions for toro token
/// @dev 06/22/2021
contract ToroToken {

    /* ---------------------------------------------------- Variables ---------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from contract owner
    modifier onlyOwner {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[toro] The function can only be called by the owner");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to initialize contract
    event Init();

    /// @notice Event to deploy contract
    /// @param from original reserve address
    /// @param to new reserve address
    event SetReserve(address indexed from, address indexed to);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[toro] Contract creator must be the storage owner");
        storageContract.setBytes32(keccak256(abi.encodePacked("token.toro.name")), "Toro");
        storageContract.setBytes32(keccak256(abi.encodePacked("token.toro.symbol")), "TORO");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.decimal")), 18);
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.toro", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))))), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ----------------------------------------------- Initialize Contract ----------------------------------------------- */

    /// @notice Initialize debugger contract
    /// @dev only called when the first time deploy the contract, do not call it during the contract update process
    function initToroToken() public onlyOwner returns (bool) {
        storageContract.setAddress(keccak256(abi.encodePacked("token.toro.reserve")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("role.isreserve", address(this))), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", address(this))), true);

        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.totalcap")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.totalfee")), 0);

        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default")), uint256(2**256 - 1));

        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default")), 0);

        storageContract.setAddress(keccak256(abi.encodePacked("token.toro.reserve")), address(this));
        storageContract.setAddress(keccak256(abi.encodePacked("token.toro.toller")), address(this));
        storageContract.setAddress(keccak256(abi.encodePacked("token.toro.commission.address")), address(this));
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.commission.percent")), 0);

        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.transfer")), true);
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.mint")), true);
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.burn")), true);

        storageContract.setBool(keccak256(abi.encodePacked("role.isreserve", address(this))), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", address(this))), true);

        storageContract.setBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")), true);

        emit Init();
        return true;
    }

    /* -------------------------------------------------- Get Balance ---------------------------------------------------- */

    /// @notice Get the toro balance of the account
    /// @param addr address of the account
    /// @return val is the toro balance
    /// @return err is the error code; 0 - no error; 1 - the address is not enrolled as a toro account yet
    function getBalance(address addr) public view returns (uint256 val, uint256 err) {
        val = 0;
        err = 0;
        if (!_isEnrolled(addr)) {
            err = 1;
            return (val, err);
        }
        val = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", addr)));
        return (val, err);
    }

    /* ------------------------------------------------- View Functions -------------------------------------------------- */

    /// @notice Get token name
    function getName() public view returns (bytes32) {
        return storageContract.getBytes32(keccak256(abi.encodePacked("token.toro.name")));
    }

    /// @notice Get token symbol
    function getSymbol() public view returns (bytes32) {
        return storageContract.getBytes32(keccak256(abi.encodePacked("token.toro.symbol")));
    }

    /// @notice Get token number of decimals
    function getDecimal() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.decimal")));
    }

    /// @notice Get the default/universal minimum transfer allowance
    function getMinimumAllowance() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default")));
    }

    /// @notice Get the default/universal maximum transfer allowance
    function getMaximumAllowance() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default")));
    }

    /// @notice Get the default/universal minimum and maximum transfer allowance
    function getAllowance() public view returns (uint256, uint256) {
        uint256 min = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default")));
        uint256 max = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default")));
        return (min, max);
    }

    /// @notice Get the default/universal fixed transaction fee
    function getTransactionFeeFixed() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default")));
    }

    /// @notice Get the default/universal percentage transaction fee
    function getTransactionFeePercentage() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default")));
    }

    /// @notice Get the default/universal fixed and percentage transaction fee
    function getTransactionFee() public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default")));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default")));
        return (fix, percent);
    }

    /// @notice Get the additional comission address for the transaction fee
    function getCommissionAddress() public view returns (address) {
        return storageContract.getAddress(keccak256(abi.encodePacked("token.toro.commission.address")));
    }

    /// @notice Get the comission percentage for the commission address
    function getCommissionPercentage() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.commission.percent")));
    }

    /// @notice Get the reserve address of toro
    function getReserve() public view returns (address) {
        return storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
    }

    /// @notice Get the reserve address of toro
    function getToller() public view returns (address) {
        return storageContract.getAddress(keccak256(abi.encodePacked("token.toro.toller")));
    }

    /// @notice Get the total cap of toro
    function getTotalCap() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.totalcap")));
    }

    /// @notice Get the total reserving of toro
    function getTotalReserving() public view returns (uint256) {
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", reserve)));
    }

    /// @notice Get the total circulating of toro
    /// @return val the total circulating
    /// @return err is the error code; 0 - no error; 1 - invalid record
    function getTotalCirculating() public view returns (uint256 val, uint256 err) {
        val = 0;
        err = 0;
        uint256 cap = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.totalcap")));
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        uint256 reserve_bal = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", reserve)));
        if (reserve_bal > cap) {
            err = 1;
            return (val, err);
        }
        val = cap - reserve_bal;
        return (val, err);
    }

    /// @notice Get the total fee of toro
    function getTotalFee() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.totalfee")));
    }

    /// @notice Check if the address has enrolled as a toro account
    /// @param addr address of the account
    function isEnrolled(address addr) public view returns (bool) {
        return (_isEnrolled(addr));
    }

    function _isEnrolled(address addr) internal view returns (bool) {
        if (addr == address(0)) {
            return false;
        }
        bool isautotoro = storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr)));
        isautotoro = isautotoro || storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr)));
        isautotoro = isautotoro || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr)));
        isautotoro = isautotoro || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr)));
        isautotoro = isautotoro || storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr)));
        if (isautotoro) {
            return true;
        }
        return (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll"))) || storageContract.getBool(keccak256(abi.encodePacked("token.toro.isenrolled", addr))));
    }

    /// @notice Check if the address has been frozen
    /// @param addr address of the account
    function isFrozen(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr)));
    }

    /// @notice Check if the automatic toro enrollment is enabled
    function getAllowSelfEnroll() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")));
    }

    /// @notice Check if the account-specified transaction fee has been set for an address
    /// @param addr address of the account
    function getAllowSelfTransactionFee(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.txfee", addr)));
    }

    /// @notice Get the account-specified fixed transaction fee
    /// @param addr address of the account
    function getSelfTransactionFeeFixed(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", addr)));
    }

    /// @notice Get the account-specified percentage transaction fee
    /// @param addr address of the account
    function getSelfTransactionFeePercentage(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", addr)));
    }

    /// @notice Get the account-specified fixed and percentage transaction fee
    /// @param addr address of the account
    function getSelfTransactionFee(address addr) public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed", addr)));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent", addr)));
        return (fix, percent);
    }

     /// @notice Check if the account-specified transaction allowance has been set for an address
    /// @param addr address of the account
    function getAllowSelfAllowance(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr)));
    }

    /// @notice Get the account-specified minimum transfer allowance
    /// @param addr address of the account
    function getSelfMinimumAllowance(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr)));
    }

    /// @notice Get the account-specified maximum transfer allowance
    /// @param addr address of the account
    function getSelfMaximumAllowance(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr)));
    }

    /// @notice Get the account-specified minimum and maximum transfer allowance
    /// @param addr address of the account
    function getSelfAllowance(address addr) public view returns (uint256, uint256) {
        uint256 min = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr)));
        uint256 max = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr)));
        return (min, max);
    }

    /// @notice Check if the transfer switch is turned on
    function isTransferOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("token.toro.on.transfer")));
    }

    /// @notice Check if the mint switch is turned on
    function isMintOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("token.toro.on.mint")));
    }

    /// @notice Check if the burn switch is turned on
    function isBurnOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("token.toro.on.burn")));
    }


    /* ------------------------------------------------- Change Reserve -------------------------------------------------- */

    /// @notice Change the toro reserve
    /// @param newReserve address of the new reserve
    /// @dev note that the function will not transfer the toro balance
    function setReserve(address newReserve) public onlyOwner returns (bool) {
        require(newReserve != address(0), "[toro] The new reserve address cannot be null");
        address oldReserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        require(newReserve != oldReserve, "[toro] The new reserve address is the same as the older reserver address");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isassigned", newReserve))), "[toro] The new reserve address has been assigned a role");

        storageContract.deleteBool(keccak256(abi.encodePacked("role.isreserve", oldReserve)));
        storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", oldReserve)));

        storageContract.setAddress(keccak256(abi.encodePacked("token.toro.reserve")), newReserve);
        storageContract.setBool(keccak256(abi.encodePacked("role.isreserve", newReserve)), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", newReserve)), true);

        emit SetReserve(oldReserve, newReserve);
        return true;
    }
}