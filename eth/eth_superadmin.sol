// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Eth Crypto Super Admin Management Contract
/// @author Wenhai Li
/// @notice These are the super admin only functions to manage the eth crypto
/// @dev 06/26/2021
contract EthCryptoSuperAdmin {

    /* --------------------------------------------------- Variables --------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from super admin
    modifier onlySuperAdmin {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))), "[eth.superadmin] The function can only be called by a super admin");
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to set the exchange rate to toro [toro/eth]
    /// @param from original value
    /// @param to new value
    event SetExchangeRate(uint256 from, uint256 to);

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

    /// @notice Event to set the default fixed toro buy fee
    /// @param from original value
    /// @param to new value
    event SetToroBuyFeeFixed(uint256 from, uint256 to);

    /// @notice Event to set the default percentage toro buy fee
    /// @param from original value
    /// @param to new value
    event SetToroBuyFeePercentage(uint256 from, uint256 to);

    /// @notice Event to set the default fixed and percentage toro buy fee
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetToroBuyFee(uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to set the default fixed toro sell fee
    /// @param from original value
    /// @param to new value
    event SetToroSellFeeFixed(uint256 from, uint256 to);

    /// @notice Event to set the default percentage toro sell fee
    /// @param from original value
    /// @param to new value
    event SetToroSellFeePercentage(uint256 from, uint256 to);

    /// @notice Event to set the default fixed and percentage toro sell fee
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetToroSellFee(uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to set the default fixed toro import fee
    /// @param from original value
    /// @param to new value
    event SetCryptoImportFeeFixed(uint256 from, uint256 to);

    /// @notice Event to set the default percentage toro import fee
    /// @param from original value
    /// @param to new value
    event SetCryptoImportFeePercentage(uint256 from, uint256 to);

    /// @notice Event to set the default fixed and percentage toro import fee
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetCryptoImportFee(uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to set the default fixed toro export fee
    /// @param from original value
    /// @param to new value
    event SetCryptoExportFeeFixed(uint256 from, uint256 to);

    /// @notice Event to set the default percentage toro export fee
    /// @param from original value
    /// @param to new value
    event SetCryptoExportFeePercentage(uint256 from, uint256 to);

    /// @notice Event to set the default fixed and percentage toro export fee
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetCryptoExportFee(uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to allow automatic crypto account enroll
    event AllowSelfEnroll();

    /// @notice Event to disallow automatic crypto account enroll
    event DisallowSelfEnroll();

    /// @notice Event to set the transfer switch on
    event SetTransferOn();

    /// @notice Event to set the transfer switch off
    event SetTransferOff();

    /// @notice Event to set the buy switch on
    event SetBuyOn();

    /// @notice Event to set the buy switch off
    event SetBuyOff();

    /// @notice Event to set the sell switch on
    event SetSellOn();

    /// @notice Event to set the sell switch off
    event SetSellOff();

    /// @notice Event to set the import switch on
    event SetImportOn();

    /// @notice Event to set the import switch off
    event SetImportOff();

    /// @notice Event to set the export switch on
    event SetExportOn();

    /// @notice Event to set the export switch off
    event SetExportOff();

    /// @notice Event to import reserve
    /// @param reserve reserve
    /// @param value import amount
    event ImportReserve(address reserve, uint256 value);

    /// @notice Event to export reserve
    /// @param reserve reserve
    /// @param value export amount
    event ExportReserve(address reserve, uint256 value);

    /// @notice Event to transfer currency from reserve to an account
    /// @param reserve reserve
    /// @param addr Address to transfer to
    /// @param value Value to transfer
    event TransferFromReserve(address reserve, address indexed addr, uint256 value);

    /// @notice Event to transfer currency from an account to reserve
    /// @param reserve reserve
    /// @param addr Address to transfer from
    /// @param value Value to transfer
    event TransferToReserve(address reserve, address indexed addr, uint256 value);

    /// @notice Event to exchange dollar to toro between reserves
    /// @param cryptoreserve crypto reserve
    /// @param tororeserve toro reserve
    /// @param crypto Ammout of crypto to exchange
    /// @param toro Amount of toro is exchanted
    event ReserveBuyToro(address cryptoreserve, address tororeserve, uint256 crypto, uint256 toro);

    /// @notice Event to exchange toro to dollar between reserves
    /// @param tororeserve tororeserve
    /// @param cryptoreserve crypto reserve
    /// @param toro Amount of toro to exchange
    /// @param crypto Ammout of crypto is exchanged
    event ReserveSellToro(address tororeserve, address cryptoreserve, uint256 toro, uint256 crypto);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[eth.superadmin] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.eth.superadmin")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ---------------------------------------------- Management Functions ----------------------------------------------- */

    /// @notice Set the exchange rate to toro [toro/eth]
    /// @param newExchangeRate The exchange rate
    function setExchangeRate(uint256 newExchangeRate) public onlySuperAdmin returns (bool) {
        require(newExchangeRate > 0, "[eth.superadmin] The exchange rate cannot be zero");
        uint256 oldExchangeRate = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));
        require(newExchangeRate != oldExchangeRate, "[eth.superadmin] The exchange rate is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")), newExchangeRate);
        emit SetExchangeRate(oldExchangeRate, newExchangeRate);
        return true;
    }

    /// @notice Set the default minimum allowance for crypto transfer
    /// @param newMinimumAmount The default minimum allowance
    function setMinimumAllowance(uint256 newMinimumAmount) public onlySuperAdmin returns (bool) {
        uint256 oldMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default")));
        require(newMinimumAmount != oldMinimumAmount, "[eth.superadmin] The minimum allowance is not changed");
        uint256 currentMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default")));
        require(newMinimumAmount < currentMaximumAmount, "[eth.superadmin] The minimum allowance value is too large");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default")), newMinimumAmount);
        emit SetMinimumAllowance(oldMinimumAmount, newMinimumAmount);
        return true;
    }

    /// @notice Set the default maximum allowance for crypto transfer
    /// @param newMaximumAmount The default maximum allowance
    function setMaximumAllowance(uint256 newMaximumAmount) public onlySuperAdmin returns (bool) {
        uint256 oldMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default")));
        require(newMaximumAmount != oldMaximumAmount, "[eth.superadmin] The maximum allowance is not changed");
        uint256 currentMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default")));
        require(newMaximumAmount > currentMinimumAmount, "[eth.superadmin] The maximum allowance value is too small");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default")), newMaximumAmount);
        emit SetMaximumAllowance(oldMaximumAmount, newMaximumAmount);
        return true;
    }

    /// @notice Set the default minimum and maximum allowance for crypto transfer
    /// @param newMaximumAmount The default maximum allowance
    /// @param newMaximumAmount The default maximum allowance
    function setAllowance(uint256 newMinimumAmount, uint256 newMaximumAmount) public onlySuperAdmin returns (bool) {
        require(newMinimumAmount < newMaximumAmount, "[eth.superadmin] The max/min values are invalid");
        uint256 oldMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default")));
        uint256 oldMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default")));
        require (newMinimumAmount != oldMinimumAmount || newMaximumAmount != oldMaximumAmount, "[eth.superadmin] No change in allowance values");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default")), newMinimumAmount);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default")), newMaximumAmount);
        emit SetAllowance(oldMinimumAmount, newMinimumAmount, oldMaximumAmount, newMaximumAmount);
        return true;
    }

    /// @notice Set the default fixed transaction fee for crypto transfer
    /// @param newTransactionFeeFixed The default fixed transaction fee
    function setTransactionFeeFixed(uint256 newTransactionFeeFixed) public onlySuperAdmin returns (bool) {
        uint256 oldTransactionFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default")));
        require(newTransactionFeeFixed != oldTransactionFeeFixed, "[eth.superadmin] The fixed transaction fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default")), newTransactionFeeFixed);
        emit SetTransactionFeeFixed(oldTransactionFeeFixed, newTransactionFeeFixed);
        return true;
    }

    /// @notice Set the default percentage transaction fee for crypto transfer
    /// @param newTransactionFeePercentage The default percentage transaction fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setTransactionFeePercentage(uint256 newTransactionFeePercentage) public onlySuperAdmin returns (bool) {
        require(newTransactionFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldTransactionFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default")));
        require(newTransactionFeePercentage != oldTransactionFeePercentage, "[eth.superadmin] The percentage transaction fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default")), newTransactionFeePercentage);
        emit SetTransactionFeePercentage(oldTransactionFeePercentage, newTransactionFeePercentage);
        return true;
    }

    /// @notice Set the default fixed and percentage transaction fee for crypto transfer
    /// @param newTransactionFeeFixed The default fixed transaction fee
    /// @param newTransactionFeePercentage The default percentage transaction fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setTransactionFee(uint256 newTransactionFeeFixed, uint256 newTransactionFeePercentage) public onlySuperAdmin returns (bool) {
        require(newTransactionFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldTransactionFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default")));
        uint256 oldTransactionFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default")));
        require(newTransactionFeeFixed != oldTransactionFeeFixed || newTransactionFeePercentage != oldTransactionFeePercentage, "[eth.superadmin] No change in transaction fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default")), newTransactionFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default")), newTransactionFeePercentage);
        emit SetTransactionFee(oldTransactionFeeFixed, newTransactionFeeFixed, oldTransactionFeePercentage, newTransactionFeePercentage);
        return true;
    }

    /// @notice Set the transaction fee toller address for crypto transfer
    /// @param newToller The toller address
    function setToller(address newToller) public onlySuperAdmin returns (bool) {
        require(newToller != address(0), "[eth.superadmin] The toller address cannnot be null");
        address oldToller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
        require(newToller != oldToller, "[eth.superadmin] The toller address is not changed");
        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.toller")), newToller);
        emit SetToller(oldToller, newToller);
        return true;
    }

    /// @notice Set the transaction fee commission address for crypto transfer
    /// @param newCommissionAddress The commission address
    function setCommissionAddress(address newCommissionAddress) public onlySuperAdmin returns (bool) {
        require(newCommissionAddress != address(0), "[eth.superadmin] The commission address cannnot be null");
        address oldCommissionAddress = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
        require(newCommissionAddress != oldCommissionAddress, "[eth.superadmin] The commission address is not changed");
        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")), newCommissionAddress);
        emit SetCommissionAddress(oldCommissionAddress, newCommissionAddress);
        return true;
    }

    /// @notice Set the transaction fee commission percentage for crypto transfer
    /// @param newCommissionPercentage The commission percentage
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setCommissionPercentage(uint256 newCommissionPercentage) public onlySuperAdmin returns (bool) {
        require(newCommissionPercentage <= 100 * 1 ether, "[eth.superadmin] The commission percentage value is invalid");
        uint256 oldCommissionPercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.commission.percent")));
        require(newCommissionPercentage != oldCommissionPercentage, "[eth.superadmin] The commission percentage is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.commission.percent")), newCommissionPercentage);
        emit SetCommissionPercentage(oldCommissionPercentage, newCommissionPercentage);
        return true;
    }

    /// @notice Set the transaction fee commission address and commission percentage for crypto transfer
    /// @param newCommissionAddress The commission address
    /// @param newCommissionPercentage The commission percentage
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setCommission(address newCommissionAddress, uint256 newCommissionPercentage) public onlySuperAdmin returns (bool) {
        require(newCommissionAddress != address(0), "[eth.superadmin] The commission address cannnot be null");
        require(newCommissionPercentage <= 100 * 1 ether, "[eth.superadmin] The commission percentage value is invalid");
        address oldCommissionAddress = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
        uint256 oldCommissionPercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.commission.percent")));
        require(newCommissionAddress != oldCommissionAddress || newCommissionPercentage != oldCommissionPercentage, "[eth.superadmin] No change in commission fee");
        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")), newCommissionAddress);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.commission.percent")), newCommissionPercentage);
        emit SetCommission(oldCommissionAddress, newCommissionAddress, oldCommissionPercentage, newCommissionPercentage);
        return true;
    }

    /// @notice Set the default fixed toro buy fee for crypto transfer
    /// @param newToroBuyFeeFixed The default fixed toro buy fee
    function setToroBuyFeeFixed(uint256 newToroBuyFeeFixed) public onlySuperAdmin returns (bool) {
        uint256 oldToroBuyFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default")));
        require(newToroBuyFeeFixed != oldToroBuyFeeFixed, "[eth.superadmin] The fixed toro buy fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default")), newToroBuyFeeFixed);
        emit SetToroBuyFeeFixed(oldToroBuyFeeFixed, newToroBuyFeeFixed);
        return true;
    }

    /// @notice Set the default percentage toro buy fee for crypto transfer
    /// @param newToroBuyFeePercentage The default percentage toro buy fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setToroBuyFeePercentage(uint256 newToroBuyFeePercentage) public onlySuperAdmin returns (bool) {
        require(newToroBuyFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldToroBuyFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default")));
        require(newToroBuyFeePercentage != oldToroBuyFeePercentage, "[eth.superadmin] The percentage toro buy fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default")), newToroBuyFeePercentage);
        emit SetToroBuyFeePercentage(oldToroBuyFeePercentage, newToroBuyFeePercentage);
        return true;
    }

    /// @notice Set the default fixed and percentage toro buy fee for crypto transfer
    /// @param newToroBuyFeeFixed The default fixed toro buy fee
    /// @param newToroBuyFeePercentage The default percentage toro buy fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setToroBuyFee(uint256 newToroBuyFeeFixed, uint256 newToroBuyFeePercentage) public onlySuperAdmin returns (bool) {
        require(newToroBuyFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldToroBuyFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default")));
        uint256 oldToroBuyFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default")));
        require(newToroBuyFeeFixed != oldToroBuyFeeFixed || newToroBuyFeePercentage != oldToroBuyFeePercentage, "[eth.superadmin] No change in toro buy fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default")), newToroBuyFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default")), newToroBuyFeePercentage);
        emit SetToroBuyFee(oldToroBuyFeeFixed, newToroBuyFeeFixed, oldToroBuyFeePercentage, newToroBuyFeePercentage);
        return true;
    }

    /// @notice Set the default fixed toro sell fee for crypto transfer
    /// @param newToroSellFeeFixed The default fixed toro sell fee
    function setToroSellFeeFixed(uint256 newToroSellFeeFixed) public onlySuperAdmin returns (bool) {
        uint256 oldToroSellFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default")));
        require(newToroSellFeeFixed != oldToroSellFeeFixed, "[eth.superadmin] The fixed toro sell fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default")), newToroSellFeeFixed);
        emit SetToroSellFeeFixed(oldToroSellFeeFixed, newToroSellFeeFixed);
        return true;
    }

    /// @notice Set the default percentage toro sell fee for crypto transfer
    /// @param newToroSellFeePercentage The default percentage toro sell fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setToroSellFeePercentage(uint256 newToroSellFeePercentage) public onlySuperAdmin returns (bool) {
        require(newToroSellFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldToroSellFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default")));
        require(newToroSellFeePercentage != oldToroSellFeePercentage, "[eth.superadmin] The percentage toro sell fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default")), newToroSellFeePercentage);
        emit SetToroSellFeePercentage(oldToroSellFeePercentage, newToroSellFeePercentage);
        return true;
    }

    /// @notice Set the default fixed and percentage toro sell fee for crypto transfer
    /// @param newToroSellFeeFixed The default fixed toro sell fee
    /// @param newToroSellFeePercentage The default percentage toro sell fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setToroSellFee(uint256 newToroSellFeeFixed, uint256 newToroSellFeePercentage) public onlySuperAdmin returns (bool) {
        require(newToroSellFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldToroSellFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default")));
        uint256 oldToroSellFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default")));
        require(newToroSellFeeFixed != oldToroSellFeeFixed || newToroSellFeePercentage != oldToroSellFeePercentage, "[eth.superadmin] No change in toro sell fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default")), newToroSellFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default")), newToroSellFeePercentage);
        emit SetToroSellFee(oldToroSellFeeFixed, newToroSellFeeFixed, oldToroSellFeePercentage, newToroSellFeePercentage);
        return true;
    }

    /// @notice Set the default fixed crypto import fee for crypto transfer
    /// @param newCryptoImportFeeFixed The default fixed crypto import fee
    function setCryptoImportFeeFixed(uint256 newCryptoImportFeeFixed) public onlySuperAdmin returns (bool) {
        uint256 oldCryptoImportFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default")));
        require(newCryptoImportFeeFixed != oldCryptoImportFeeFixed, "[eth.superadmin] The fixed crypto import fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default")), newCryptoImportFeeFixed);
        emit SetCryptoImportFeeFixed(oldCryptoImportFeeFixed, newCryptoImportFeeFixed);
        return true;
    }

    /// @notice Set the default percentage crypto import fee for crypto transfer
    /// @param newCryptoImportFeePercentage The default percentage crypto import fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setCryptoImportFeePercentage(uint256 newCryptoImportFeePercentage) public onlySuperAdmin returns (bool) {
        require(newCryptoImportFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldCryptoImportFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default")));
        require(newCryptoImportFeePercentage != oldCryptoImportFeePercentage, "[eth.superadmin] The percentage crypto import fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default")), newCryptoImportFeePercentage);
        emit SetCryptoImportFeePercentage(oldCryptoImportFeePercentage, newCryptoImportFeePercentage);
        return true;
    }

    /// @notice Set the default fixed and percentage crypto import fee for crypto transfer
    /// @param newCryptoImportFeeFixed The default fixed crypto import fee
    /// @param newCryptoImportFeePercentage The default percentage crypto import fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setCryptoImportFee(uint256 newCryptoImportFeeFixed, uint256 newCryptoImportFeePercentage) public onlySuperAdmin returns (bool) {
        require(newCryptoImportFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldCryptoImportFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default")));
        uint256 oldCryptoImportFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default")));
        require(newCryptoImportFeeFixed != oldCryptoImportFeeFixed || newCryptoImportFeePercentage != oldCryptoImportFeePercentage, "[eth.superadmin] No change in crypto import fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default")), newCryptoImportFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default")), newCryptoImportFeePercentage);
        emit SetCryptoImportFee(oldCryptoImportFeeFixed, newCryptoImportFeeFixed, oldCryptoImportFeePercentage, newCryptoImportFeePercentage);
        return true;
    }


    /// @notice Set the default fixed crypto export fee for crypto transfer
    /// @param newCryptoExportFeeFixed The default fixed crypto export fee
    function setCryptoExportFeeFixed(uint256 newCryptoExportFeeFixed) public onlySuperAdmin returns (bool) {
        uint256 oldCryptoExportFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default")));
        require(newCryptoExportFeeFixed != oldCryptoExportFeeFixed, "[eth.superadmin] The fixed crypto export fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default")), newCryptoExportFeeFixed);
        emit SetCryptoExportFeeFixed(oldCryptoExportFeeFixed, newCryptoExportFeeFixed);
        return true;
    }

    /// @notice Set the default percentage crypto export fee for crypto transfer
    /// @param newCryptoExportFeePercentage The default percentage crypto export fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setCryptoExportFeePercentage(uint256 newCryptoExportFeePercentage) public onlySuperAdmin returns (bool) {
        require(newCryptoExportFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldCryptoExportFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default")));
        require(newCryptoExportFeePercentage != oldCryptoExportFeePercentage, "[eth.superadmin] The percentage crypto export fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default")), newCryptoExportFeePercentage);
        emit SetCryptoExportFeePercentage(oldCryptoExportFeePercentage, newCryptoExportFeePercentage);
        return true;
    }

    /// @notice Set the default fixed and percentage crypto export fee for crypto transfer
    /// @param newCryptoExportFeeFixed The default fixed crypto export fee
    /// @param newCryptoExportFeePercentage The default percentage crypto export fee
    /// @dev the percentage value is between 0 and 100 in bignumber format
    function setCryptoExportFee(uint256 newCryptoExportFeeFixed, uint256 newCryptoExportFeePercentage) public onlySuperAdmin returns (bool) {
        require(newCryptoExportFeePercentage <= 100 * 1 ether, "[eth.superadmin] The percentage value is invalid");
        uint256 oldCryptoExportFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default")));
        uint256 oldCryptoExportFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default")));
        require(newCryptoExportFeeFixed != oldCryptoExportFeeFixed || newCryptoExportFeePercentage != oldCryptoExportFeePercentage, "[eth.superadmin] No change in crypto export fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default")), newCryptoExportFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default")), newCryptoExportFeePercentage);
        emit SetCryptoExportFee(oldCryptoExportFeeFixed, newCryptoExportFeeFixed, oldCryptoExportFeePercentage, newCryptoExportFeePercentage);
        return true;
    }

    /// @notice Allow an account to be automatically enrolled as a crypto account
    function allowSelfEnroll() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")), true);
        emit AllowSelfEnroll();
        return true;
    }

    /// @notice Disallow an account to be automatically enrolled as a crypto account
    function disallowSelfEnroll() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")), false);
        emit DisallowSelfEnroll();
        return true;
    }

    /// @notice Set the transfer switch on
    function setTransferOn() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.transfer")), true);
        emit SetTransferOn();
        return true;
    }

    /// @notice Set the transfer switch off
    function setTransferOff() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.transfer")), false);
        emit SetTransferOff();
        return true;
    }

    /// @notice Set the buy switch on
    function setBuyOn() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.buy")), true);
        emit SetBuyOn();
        return true;
    }

    /// @notice Set the buy switch off
    function setBuyOff() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.buy")), false);
        emit SetBuyOff();
        return true;
    }

    /// @notice Set the sell switch on
    function setSellOn() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.sell")), true);
        emit SetSellOn();
        return true;
    }

    /// @notice Set the sell switch off
    function setSellOff() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.sell")), false);
        emit SetSellOff();
        return true;
    }

    /// @notice Set the import switch on
    function setImportOn() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.import")), true);
        emit SetImportOn();
        return true;
    }

    /// @notice Set the import switch off
    function setImportOff() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.import")), false);
        emit SetImportOff();
        return true;
    }

    /// @notice Set the export switch on
    function setExportOn() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.export")), true);
        emit SetExportOn();
        return true;
    }

    /// @notice Set the export switch off
    function setExportOff() public onlySuperAdmin returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.export")), false);
        emit SetExportOff();
        return true;
    }

    /* ----------------------------------------Reserve Mint/Burn Functions ----------------------------------------------- */

    /// @notice Import crypto in crypto reserve
    /// @param value amount to import
    function importReserve(uint256 value) public onlySuperAdmin returns (bool) {
        require(value > 0, "[eth.superadmin] Import value cannot be zero");
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", reserve)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value);
        emit ImportReserve(reserve, value);
        return true;
    }

    /// @notice Export crypto in crypto reserve
    /// @param value amount to export
    function exportReserve(uint256 value) public onlySuperAdmin returns (bool) {
        require(value > 0, "[eth.superadmin] Export value cannot be zero");
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", reserve))) >= value, "[eth.superadmin] Export value is too large");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalcap"))) >= value, "[eth.superadmin] Export value is too large");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", reserve)), value);
        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value);
        emit ExportReserve(reserve, value);
        return true;
    }

    /* ----------------------------------------Reserve Transfer Functions ----------------------------------------------- */

    /// @notice Transfer crypto from reserve to an adress
    /// @param addr address to transfer to
    /// @param value amount to transfer
    /// @dev Note that no crypto enrollment check, no minimum/maximum allowance check, no frozen/unfrozen check, no client account only check
    function transferFromReserve(address addr, uint256 value) public onlySuperAdmin returns (bool) {
        require(addr != address(0), "[eth.superadmin] The address cannot be null");
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        require(addr != reserve, "[eth.superadmin] The address cannot be the crypto reserve itself");
        require(value > 0, "[eth.superadmin] The transfer ammount cannot be zero");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", reserve))) >= value, "[eth.superadmin] Insufficient reserve balance");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", reserve)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value);
        emit TransferFromReserve(reserve, addr, value);
        return true;
    }

    /// @notice Transfer crypto from an address to reserve
    /// @param addr address to transfer from
    /// @param value amount to transfer
    /// @dev Note that no crypto enrollment check, no minimum/maximum allowance check, no frozen/unfrozen check, no client account only check
    function transferToReserve(address addr, uint256 value) public onlySuperAdmin returns (bool) {
        require(addr != address(0), "[eth.superadmin] The address cannot be null");
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        require(addr != reserve, "[eth.superadmin] The address cannot be the crypto reserve itself");
        require(value > 0, "[eth.superadmin] The transfer ammount cannot be zero");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr))) >= value, "[eth.superadmin] Insufficient account balance");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", reserve)), value);
        emit TransferToReserve(reserve, addr, value);
        return true;
    }

    /* ----------------------------------------- Reserve Toro Buy/Sell Functions ----------------------------------------- */

    /// @notice Exchange crypto in the crypto reserve to toro in the toro reserve
    /// @param value Amount of crypto to exchange
    function reserveBuyToro(uint256 value) public onlySuperAdmin returns (bool) {
        require(value > 0, "[eth.superadmin] The ammount to purchase cannot be zero");
        address crypto_reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        address toro_reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve))) >= value, "[eth.superadmin] Insufficient reserve crypto balance");

        uint256 toro_amount = value * storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate"))) / 1 ether;

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve)), toro_amount);

        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalcap"))) >= value, "[eth.superadmin] Error in eth totol cap");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.totalcap")), toro_amount);

        emit ReserveBuyToro(crypto_reserve, toro_reserve, value, toro_amount);

        return true;
    }

    /// @notice Calculate reserve buy result
    /// @param val Amount to buy with the crypto
    /// @dev note  Super admin can use this function before the reserve toro buy to estimate the toro amount can be exchanged
    function calculateReserveBuyResult(uint256 val) public view returns (uint256 amount) {
        amount = val * storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate"))) / 1 ether;
        return amount;
    }

    /// @notice Exchange crypto in the crypto reserve to toro in the toro reserve
    /// @param value Amount of crypto to exchange
    function reserveSellToro(uint256 value) public onlySuperAdmin returns (bool) {
        require(value > 0, "[eth.superadmin] The ammount to purchase cannot be zero");
        address crypto_reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        address toro_reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve))) >= value, "[eth.superadmin] Insufficient reserve toro balance");

        uint256 crypto_amount = 1 ether * value / storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));

        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve)), crypto_amount);

        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.totalcap"))) >= value, "[eth.superadmin] Error in toro totol cap");
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.totalcap")), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), crypto_amount);

        emit ReserveSellToro(toro_reserve, crypto_reserve, value, crypto_amount);
        return true;
    }

    /// @notice Calculate reserve sell result
    /// @param val Amount to sell with toro
    /// @dev note  Super admin can use this function before the reserve toro sell to estimate the crypto amount can be exchanged
    function calculateReserveSellResult(uint256 val) public view returns (uint256 amount) {
        amount = 1 ether * val / storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));
        return amount;
    }

}