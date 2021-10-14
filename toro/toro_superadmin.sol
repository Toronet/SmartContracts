// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Token Super Admin Management Contract
/// @author Wenhai Li
/// @notice These are the super admin only functions to manage the toro token
/// @dev 06/24/2021
contract ToroTokenSuperAdmin {

    /* --------------------------------------------------- Variables --------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from super admin
    modifier onlySuperAdmin {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))), "[toro.superadmin] The function can only be called by a super admin");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to set the default minimum transfer allowance
    /// @param from original value
    /// @param to new value
    event SetMinimumAllowance(uint256 from, uint256 to);

    /// @notice Event to set the default maximum transfer allowance
    /// @param from original value
    /// @param to new value
    event SetMaximumAllowance(uint256 from, uint256 to);

    /// @notice Event to set the default minimum and maximum transfer allowance
    /// @param oldMin original minimum value
    /// @param newMin new minimum value
    /// @param oldMax original maximum value
    /// @param newMax new maximum value
    event SetAllowance(uint256 oldMin, uint256 newMin, uint256 oldMax, uint256 newMax);

    /// @notice Event to set the default fixed transactio fee
    /// @param from original value
    /// @param to new value
    event SetTransactionFeeFixed(uint256 from, uint256 to);

    /// @notice Event to set the default percentage transactio fee
    /// @param from original value
    /// @param to new value
    event SetTransactionFeePercentage(uint256 from, uint256 to);

    /// @notice Event to set the default fixed and percentage transaction fee
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetTransactionFee(uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to set the toller address
    /// @param from original value
    /// @param to new value
    event SetToller(address indexed from, address indexed to);

    /// @notice Event to set the commission address
    /// @param from original value
    /// @param to new value
    event SetCommissionAddress(address indexed from, address indexed to);


    /// @notice Event to set the commission percentage
    /// @param from original value
    /// @param to new value
    event SetCommissionPercentage(uint256 from, uint256 to);


    /// @notice Event to set the commission address
    /// @param oldAddr original commission address
    /// @param newAddr new commission address
    /// @param oldPercent original commission percentage
    /// @param newPercent new commission percentage
    event SetCommission(address indexed oldAddr, address indexed newAddr, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to allow automatic toro account enroll
    event AllowSelfEnroll();

    /// @notice Event to disallow automatic toro account enroll
    event DisallowSelfEnroll();

    /// @notice Event to set the transfer switch on
    event SetTransferOn();

    /// @notice Event to set the transfer switch off
    event SetTransferOff();

    /// @notice Event to set the mint switch on
    event SetMintOn();

    /// @notice Event to set the mint switch off
    event SetMintOff();

    /// @notice Event to set the burn switch on
    event SetBurnOn();

    /// @notice Event to set the burn switch off
    event SetBurnOff();

    /// @notice Event to mint reserve
    /// @param reserve reserve
    /// @param value mint amount
    event MintReserve(address indexed reserve, uint256 value);

    /// @notice Event to burn reserve
    /// @param reserve reserve
    /// @param value burn amount
    event BurnReserve(address indexed reserve, uint256 value);

    /// @notice Event to transfer toro from reserve to an account
    /// @param reserve reserve
    /// @param addr Address to transfer to
    /// @param value Value to transfer
    event TransferFromReserve(address indexed reserve, address indexed addr, uint256 value);

    /// @notice Event to transfer toro from an account to reserve
    /// @param reserve reserve
    /// @param addr Address to transfer from
    /// @param value Value to transfer
    event TransferToReserve(address indexed reserve, address indexed addr, uint256 value);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[toro.superadmin] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.toro.superadmin")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ---------------------------------------------- Management Functions ----------------------------------------------- */

    /// @notice Set the default minimum allowance for toro transfer
    /// @param newMinimumAmount The default minimum allowance
    function setMinimumAllowance(uint256 newMinimumAmount) public onlySuperAdmin returns (bool) {
        uint256 oldMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default")));
        require(newMinimumAmount != oldMinimumAmount, "[toro.superadmin] The minimum allowance is not changed");
        uint256 currentMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default")));
        require(newMinimumAmount < currentMaximumAmount, "[toro.superadmin] The minimum allowance value is too large");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default")), newMinimumAmount);
        emit SetMinimumAllowance(oldMinimumAmount, newMinimumAmount);
        return true;
    }

    /// @notice Set the default maximum allowance for toro transfer
    /// @param newMaximumAmount The default maximum allowance
    function setMaximumAllowance(uint256 newMaximumAmount) public onlySuperAdmin returns (bool) {
        uint256 oldMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default")));
        require(newMaximumAmount != oldMaximumAmount, "[toro.superadmin] The maximum allowance is not changed");
        uint256 currentMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default")));
        require(newMaximumAmount > currentMinimumAmount, "[toro.superadmin] The maximum allowance value is too small");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default")), newMaximumAmount);
        emit SetMaximumAllowance(oldMaximumAmount, newMaximumAmount);
        return true;
    }

    /// @notice Set the default minimum and maximum allowance for toro transfer
    /// @param newMaximumAmount The default maximum allowance
    /// @param newMaximumAmount The default maximum allowance
    function setAllowance(uint256 newMinimumAmount, uint256 newMaximumAmount) public onlySuperAdmin returns (bool) {
        require(newMinimumAmount < newMaximumAmount, "[toro.superadmin] The max/min values are invalid");
        uint256 oldMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default")));
        uint256 oldMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default")));
        require (newMinimumAmount != oldMinimumAmount || newMaximumAmount != oldMaximumAmount, "[toro.superadmin] No change in allowance values");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default")), newMinimumAmount);
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default")), newMaximumAmount);
        emit SetAllowance(oldMinimumAmount, newMinimumAmount, oldMaximumAmount, newMaximumAmount);
        return true;
    }

    /// @notice Set the default fixed transaction fee for toro transfer
    /// @param newTransactionFeeFixed The default fixed transaction fee
    function setTransactionFeeFixed(uint256 newTransactionFeeFixed) public onlySuperAdmin returns (bool) {
        uint256 oldTransactionFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default")));
        require(newTransactionFeeFixed != oldTransactionFeeFixed, "[toro.superadmin] The fixed transaction fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default")), newTransactionFeeFixed);
        emit SetTransactionFeeFixed(oldTransactionFeeFixed, newTransactionFeeFixed);
        return true;
    }

    /// @notice Set the default percentage transaction fee for toro transfer
    /// @param newTransactionFeePercentage The default percentage transaction fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setTransactionFeePercentage(uint256 newTransactionFeePercentage) public onlySuperAdmin returns (bool) {
        require(newTransactionFeePercentage <= 100 * 1 ether, "[toro.superadmin] The percentage value is invalid");
        uint256 oldTransactionFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default")));
        require(newTransactionFeePercentage != oldTransactionFeePercentage, "[toro.superadmin] The percentage transaction fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default")), newTransactionFeePercentage);
        emit SetTransactionFeePercentage(oldTransactionFeePercentage, newTransactionFeePercentage);
        return true;
    }

    /// @notice Set the default fixed and percentage transaction fee for toro transfer
    /// @param newTransactionFeeFixed The default fixed transaction fee
    /// @param newTransactionFeePercentage The default percentage transaction fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setTransactionFee(uint256 newTransactionFeeFixed, uint256 newTransactionFeePercentage) public onlySuperAdmin returns (bool) {
        require(newTransactionFeePercentage <= 100 * 1 ether, "[toro.superadmin] The percentage value is invalid");
        uint256 oldTransactionFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default")));
        uint256 oldTransactionFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default")));
        require(newTransactionFeeFixed != oldTransactionFeeFixed || newTransactionFeePercentage != oldTransactionFeePercentage, "[toro.superadmin] No change in transaction fee");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.fixed.default")), newTransactionFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.txfee.percent.default")), newTransactionFeePercentage);
        emit SetTransactionFee(oldTransactionFeeFixed, newTransactionFeeFixed, oldTransactionFeePercentage, newTransactionFeePercentage);
        return true;
    }

    /// @notice Set the transaction fee toller address for toro transfer
    /// @param newToller The toller address
    function setToller(address newToller) public onlySuperAdmin returns (bool) {
        require(newToller != address(0), "[toro.superadmin] The toller address cannnot be null");
        address oldToller = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.toller")));
        require(newToller != oldToller, "[toro.superadmin] The toller address is not changed");
        storageContract.setAddress(keccak256(abi.encodePacked("token.toro.toller")), newToller);
        emit SetToller(oldToller, newToller);
        return true;
    }

    /// @notice Set the transaction fee commission address for toro transfer
    /// @param newCommissionAddress The commission address
    function setCommissionAddress(address newCommissionAddress) public onlySuperAdmin returns (bool) {
        require(newCommissionAddress != address(0), "[toro.superadmin] The commission address cannnot be null");
        address oldCommissionAddress = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.commission.address")));
        require(newCommissionAddress != oldCommissionAddress, "[toro.superadmin] The commission address is not changed");
        storageContract.setAddress(keccak256(abi.encodePacked("token.toro.commission.address")), newCommissionAddress);
        emit SetCommissionAddress(oldCommissionAddress, newCommissionAddress);
        return true;
    }

    /// @notice Set the transaction fee commission percentage for toro transfer
    /// @param newCommissionPercentage The commission percentage
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setCommissionPercentage(uint256 newCommissionPercentage) public onlySuperAdmin returns (bool) {
        require(newCommissionPercentage <= 100 * 1 ether, "[toro.superadmin] The commission percentage value is invalid");
        uint256 oldCommissionPercentage = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.commission.percent")));
        require(newCommissionPercentage != oldCommissionPercentage, "[toro.superadmin] The commission percentage is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.commission.percent")), newCommissionPercentage);
        emit SetCommissionPercentage(oldCommissionPercentage, newCommissionPercentage);
        return true;
    }

    /// @notice Set the transaction fee commission address and commission percentage for toro transfer
    /// @param newCommissionAddress The commission address
    /// @param newCommissionPercentage The commission percentage
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setCommission(address newCommissionAddress, uint256 newCommissionPercentage) public onlySuperAdmin returns (bool) {
        require(newCommissionAddress != address(0), "[toro.superadmin] The commission address cannnot be null");
        require(newCommissionPercentage <= 100 * 1 ether, "[toro.superadmin] The commission percentage value is invalid");
        address oldCommissionAddress = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.commission.address")));
        uint256 oldCommissionPercentage = storageContract.getUint256(keccak256(abi.encodePacked("token.toro.commission.percent")));
        require(newCommissionAddress != oldCommissionAddress || newCommissionPercentage != oldCommissionPercentage, "[toro.superadmin] No change in commission fee");
        storageContract.setAddress(keccak256(abi.encodePacked("token.toro.commission.address")), newCommissionAddress);
        storageContract.setUint256(keccak256(abi.encodePacked("token.toro.commission.percent")), newCommissionPercentage);
        emit SetCommission(oldCommissionAddress, newCommissionAddress, oldCommissionPercentage, newCommissionPercentage);
        return true;
    }

    /// @notice Allow an account to be automatically enrolled as a toro account
    function allowSelfEnroll() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")), true);
        emit AllowSelfEnroll();
        return true;
    }

    /// @notice Disallow an account to be automatically enrolled as a toro account
    function disallowSelfEnroll() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.allowself.enroll")), false);
        emit DisallowSelfEnroll();
        return true;
    }

    /// @notice Set the transfer switch on
    function setTransferOn() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.transfer")), true);
        emit SetTransferOn();
        return true;
    }

    /// @notice Set the transfer switch off
    function setTransferOff() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.transfer")), false);
        emit SetTransferOff();
        return true;
    }

    /// @notice Set the mint switch on
    function setMintOn() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.mint")), true);
        emit SetMintOn();
        return true;
    }

    /// @notice Set the mint switch off
    function setMintOff() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.mint")), false);
        emit SetMintOff();
        return true;
    }

    /// @notice Set the burn switch on
    function setBurnOn() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.burn")), true);
        emit SetBurnOn();
        return true;
    }

    /// @notice Set the burn switch off
    function setBurnOff() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("token.toro.on.burn")), false);
        emit SetBurnOff();
        return true;
    }

    /* ----------------------------------------Reserve Mint/Burn Functions ----------------------------------------------- */

    /// @notice Mint toro in toro reserve
    /// @param value amount to mint
    function mintReserve(uint256 value) public onlySuperAdmin returns (bool) {
        require(value > 0, "[toro.superadmin] Mint value cannot be zero");
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", reserve)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.totalcap")), value);
        emit MintReserve(reserve, value);
        return true;
    }

    /// @notice Burn toro in toro reserve
    /// @param value amount to burn
    function burnReserve(uint256 value) public onlySuperAdmin returns (bool) {
        require(value > 0, "[toro.superadmin] Burn value cannot be zero");
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", reserve))) >= value, "[toro.superadmin] Mint value is too large");
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.totalcap"))) >= value, "[toro.superadmin] Mint value is too large");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", reserve)), value);
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.totalcap")), value);
        emit BurnReserve(reserve, value);
        return true;
    }

    /* ----------------------------------------Reserve Transfer Functions ----------------------------------------------- */

    /// @notice Transfer toro from reserve to an adress
    /// @param addr address to transfer to
    /// @param value amount to transfer
    /// @dev Note that no toro enrollment check, no minimum/maximum allowance check, no frozen/unfrozen check, no client account only check
    function transferFromReserve(address addr, uint256 value) public onlySuperAdmin returns (bool) {
        require(addr != address(0), "[toro.superadmin] The address cannot be null");
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        require(addr != reserve, "[toro.superadmin] The address cannot be the toro reserve itself");
        require(value > 0, "[toro.superadmin] The transfer ammount cannot be zero");
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", reserve))) >= value, "[toro.superadmin] Insufficient reserve balance");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", reserve)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", addr)), value);
        emit TransferFromReserve(reserve, addr, value);
        return true;
    }

    /// @notice Transfer toro from an address to reserve
    /// @param addr address to transfer from
    /// @param value amount to transfer
    /// @dev Note that no toro enrollment check, no minimum/maximum allowance check, no frozen/unfrozen check, no client account only check
    function transferToReserve(address addr, uint256 value) public onlySuperAdmin returns (bool) {
        require(addr != address(0), "[toro.superadmin] The address cannot be null");
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        require(addr != reserve, "[toro.superadmin] The address cannot be the toro reserve itself");
        require(value > 0, "[toro.superadmin] The transfer ammount cannot be zero");
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", addr))) >= value, "[toro.superadmin] Insufficient account balance");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", addr)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", reserve)), value);
        emit TransferToReserve(reserve, addr, value);
        return true;
    }
}