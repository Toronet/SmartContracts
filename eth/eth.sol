// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Ethereum Crypto Contract
/// @author Wenhai Li
/// @notice These are the functions for eth crypto
/// @dev 06/26/2021
contract EthCrypto {

    /* ---------------------------------------------------- Variables ---------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from contract owner
    modifier onlyOwner {
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[eth] The function can only be called by the owner");
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
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[eth] Contract creator must be the storage owner");
        storageContract.setBytes32(keccak256(abi.encodePacked("crypto.eth.name")), "Ethereum");
        storageContract.setBytes32(keccak256(abi.encodePacked("crypto.eth.symbol")), "ETH");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.decimal")), 18);
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.eth", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))))), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ----------------------------------------------- Initialize Contract ----------------------------------------------- */

    /// @notice Initialize debugger contract
    /// @dev only called when the first time deploy the contract, do not call it during the contract update process
    function initEthCrypto() public onlyOwner returns (bool) {
        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.reserve")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("role.isreserve", address(this))), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", address(this))), true);

        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")), 3000.0 ether);

        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), 0);


        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default")), uint256(2**256 - 1));

        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default")), 0);

        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.reserve")), address(this));
        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.toller")), address(this));
        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")), address(this));
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.commission.percent")), 0);

        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default")), 0);

        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default")), 0);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default")), 0);

        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.transfer")), true);
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.buy")), true);
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.sell")), true);
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.import")), true);
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.on.export")), true);

        storageContract.setBool(keccak256(abi.encodePacked("role.isreserve", address(this))), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", address(this))), true);

        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")), true);

        emit Init();
        return true;
    }

    /* -------------------------------------------------- Get Balance ---------------------------------------------------- */

    /// @notice Get the eth balance of the account
    /// @param addr address of the account
    /// @return val is the eth balance
    /// @return err is the error code; 0 - no error; 1 - the address is not enrolled as a eth account yet
    function getBalance(address addr) public view returns (uint256 val, uint256 err) {
        val = 0;
        err = 0;
        if (!_isEnrolled(addr)) {
            err = 1;
            return (val, err);
        }
        val = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)));
        return (val, err);
    }

    /* ------------------------------------------------- View Functions -------------------------------------------------- */

    /// @notice Get crypto name
    function getName() public view returns (bytes32) {
        return storageContract.getBytes32(keccak256(abi.encodePacked("crypto.eth.name")));
    }

    /// @notice Get crypto symbol
    function getSymbol() public view returns (bytes32) {
        return storageContract.getBytes32(keccak256(abi.encodePacked("crypto.eth.symbol")));
    }

    /// @notice Get crypto number of decimals
    function getDecimal() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.decimal")));
    }

    /// @notice Get the current eth to toro excanger rate [toro/eth]
    function getExchangeRate() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));
    }

    /// @notice Get the default/universal minimum transfer allowance
    function getMinimumAllowance() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default")));
    }

    /// @notice Get the default/universal maximum transfer allowance
    function getMaximumAllowance() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default")));
    }

    /// @notice Get the default/universal minimum and maximum transfer allowance
    function getAllowance() public view returns (uint256, uint256) {
        uint256 min = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default")));
        uint256 max = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default")));
        return (min, max);
    }

    /// @notice Get the default/universal fixed transaction fee
    function getTransactionFeeFixed() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default")));
    }

    /// @notice Get the default/universal percentage transaction fee
    function getTransactionFeePercentage() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default")));
    }

    /// @notice Get the default/universal fixed and percentage transaction fee
    function getTransactionFee() public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default")));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default")));
        return (fix, percent);
    }

    /// @notice Get the additional comission address for the transaction fee
    function getCommissionAddress() public view returns (address) {
        return storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
    }

    /// @notice Get the comission percentage for the commission address
    function getCommissionPercentage() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.commission.percent")));
    }

    /// @notice Get the toro buy fixed transaction fee
    function getToroBuyFeeFixed() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default")));
    }

    /// @notice Get the toro buy percentage transaction fee
    function getToroBuyFeePercentage() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default")));
    }

    /// @notice Get the default/universal fixed and percentage toro buy fee
    function getToroBuyFee() public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default")));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default")));
        return (fix, percent);
    }

    /// @notice Get the toro sell fixed transaction fee
    function getToroSellFeeFixed() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default")));
    }

    /// @notice Get the toro sell percentage transaction fee
    function getToroSellFeePercentage() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default")));
    }

    /// @notice Get the default/universal fixed and percentage toro sell fee
    function getToroSellFee() public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default")));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default")));
        return (fix, percent);
    }

    /// @notice Get the crypto import fixed transaction fee
    function getCryptoImportFeeFixed() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default")));
    }

    /// @notice Get the crypto import percentage transaction fee
    function getCryptoImportFeePercentage() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default")));
    }

    /// @notice Get the default/universal fixed and percentage crypto import fee
    function getCryptoImportFee() public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default")));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default")));
        return (fix, percent);
    }

    /// @notice Get the crypto export fixed transaction fee
    function getCryptoExportFeeFixed() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default")));
    }

    /// @notice Get the crypto export percentage transaction fee
    function getCryptoExportFeePercentage() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default")));
    }

    /// @notice Get the default/universal fixed and percentage crypto export fee
    function getCryptoExportFee() public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default")));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default")));
        return (fix, percent);
    }

    /// @notice Get the reserve address of crypto
    function getReserve() public view returns (address) {
        return storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
    }

    /// @notice Get the reserve address of crypto
    function getToller() public view returns (address) {
        return storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
    }

    /// @notice Get the total cap of crypto
    function getTotalCap() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")));
    }

    /// @notice Get the total reserving of crypto
    function getTotalReserving() public view returns (uint256) {
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", reserve)));
    }

    /// @notice Get the total circulating of crypto
    /// @return val the total circulating
    /// @return err is the error code; 0 - no error; 1 - invalid record
    function getTotalCirculating() public view returns (uint256 val, uint256 err) {
        val = 0;
        err = 0;
        uint256 cap = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")));
        address reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        uint256 reserve_bal = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", reserve)));
        if (reserve_bal > cap) {
            err = 1;
            return (val, err);
        }
        val = cap - reserve_bal;
        return (val, err);
    }

    /// @notice Get the total fee of crypto
    function getTotalFee() public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")));
    }

    /// @notice Check if the address has enrolled as a crypto account
    /// @param addr address of the account
    function isEnrolled(address addr) public view returns (bool) {
        return (_isEnrolled(addr));
    }

    function _isEnrolled(address addr) internal view returns (bool) {
        if (addr == address(0)) {
            return false;
        }
        bool isautocrypto = storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr)));
        isautocrypto = isautocrypto || storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr)));
        isautocrypto = isautocrypto || storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr)));
        isautocrypto = isautocrypto || storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr)));
        isautocrypto = isautocrypto || storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr)));
        if (isautocrypto) {
            return true;
        }
        return (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll"))) || storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", addr))));
    }

    /// @notice Check if the address has been frozen
    /// @param addr address of the account
    function isFrozen(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr)));
    }

    /// @notice Check if the automatic crypto enrollment is enabled
    function getAllowSelfEnroll() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")));
    }

    /// @notice Check if the account-specified transaction fee has been set for an address
    /// @param addr address of the account
    function getAllowSelfTransactionFee(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.txfee", addr)));
    }

    /// @notice Get the account-specified fixed transaction fee
    /// @param addr address of the account
    function getSelfTransactionFeeFixed(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", addr)));
    }

    /// @notice Get the account-specified percentage transaction fee
    /// @param addr address of the account
    function getSelfTransactionFeePercentage(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", addr)));
    }

    /// @notice Get the account-specified fixed and percentage transaction fee
    /// @param addr address of the account
    function getSelfTransactionFee(address addr) public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", addr)));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", addr)));
        return (fix, percent);
    }

     /// @notice Check if the account-specified transaction allowance has been set for an address
    /// @param addr address of the account
    function getAllowSelfAllowance(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)));
    }

    /// @notice Get the account-specified minimum transfer allowance
    /// @param addr address of the account
    function getSelfMinimumAllowance(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr)));
    }

    /// @notice Get the account-specified maximum transfer allowance
    /// @param addr address of the account
    function getSelfMaximumAllowance(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr)));
    }

    /// @notice Get the account-specified minimum and maximum transfer allowance
    /// @param addr address of the account
    function getSelfAllowance(address addr) public view returns (uint256, uint256) {
        uint256 min = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr)));
        uint256 max = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr)));
        return (min, max);
    }

    /// @notice Check if the account-specified toro buy fee has been set for an address
    /// @param addr address of the account
    function getAllowSelfToroBuyFee(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.buyfee", addr)));
    }

    /// @notice Get the account-specified fixed toro buy fee
    /// @param addr address of the account
    function getSelfToroBuyFeeFixed(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", addr)));
    }

    /// @notice Get the account-specified percentage toro buy fee
    /// @param addr address of the account
    function getSelfToroBuyFeePercentage(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", addr)));
    }

    /// @notice Get the account-specified fixed and percentage toro buy fee
    /// @param addr address of the account
    function getSelfToroBuyFee(address addr) public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", addr)));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", addr)));
        return (fix, percent);
    }

    /// @notice Check if the account-specified toro sell fee has been set for an address
    /// @param addr address of the account
    function getAllowSelfToroSellFee(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.sellfee", addr)));
    }

    /// @notice Get the account-specified fixed toro sell fee
    /// @param addr address of the account
    function getSelfToroSellFeeFixed(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", addr)));
    }

    /// @notice Get the account-specified percentage toro sell fee
    /// @param addr address of the account
    function getSelfToroSellFeePercentage(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", addr)));
    }

    /// @notice Get the account-specified fixed and percentage toro sell fee
    /// @param addr address of the account
    function getSelfToroSellFee(address addr) public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", addr)));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", addr)));
        return (fix, percent);
    }

    /// @notice Check if the account-specified crypto import fee has been set for an address
    /// @param addr address of the account
    function getAllowSelfCryptoImportFee(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.importfee", addr)));
    }

    /// @notice Get the account-specified fixed crypto import fee
    /// @param addr address of the account
    function getSelfCryptoImportFeeFixed(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", addr)));
    }

    /// @notice Get the account-specified percentage crypto import fee
    /// @param addr address of the account
    function getSelfCryptoImportFeePercentage(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", addr)));
    }

    /// @notice Get the account-specified fixed and percentage crypto import fee
    /// @param addr address of the account
    function getSelfCryptoImportFee(address addr) public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", addr)));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", addr)));
        return (fix, percent);
    }

    /// @notice Check if the account-specified crypto export fee has been set for an address
    /// @param addr address of the account
    function getAllowSelfCryptoExportFee(address addr) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.exportfee", addr)));
    }

    /// @notice Get the account-specified fixed crypto export fee
    /// @param addr address of the account
    function getSelfCryptoExportFeeFixed(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", addr)));
    }

    /// @notice Get the account-specified percentage crypto export fee
    /// @param addr address of the account
    function getSelfCryptoExportFeePercentage(address addr) public view returns (uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", addr)));
    }

    /// @notice Get the account-specified fixed and percentage crypto export fee
    /// @param addr address of the account
    function getSelfCryptoExportFee(address addr) public view returns (uint256, uint256) {
        uint256 fix = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", addr)));
        uint256 percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", addr)));
        return (fix, percent);
    }

    /// @notice Check if the transfer switch is turned on
    function isTransferOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.transfer")));
    }

    /// @notice Check if the buy switch is turned on
    function isBuyOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.buy")));
    }

    /// @notice Check if the sell switch is turned on
    function isSellOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.sell")));
    }

    /// @notice Check if the import switch is turned on
    function isImportOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.import")));
    }

    /// @notice Check if the export switch is turned on
    function isExportOn() public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.export")));
    }

    /* ------------------------------------------------- Change Reserve -------------------------------------------------- */

    /// @notice Change the crypto reserve
    /// @param newReserve address of the new reserve
    /// @dev note that the function will not transfer the crypto balance
    function setReserve(address newReserve) public onlyOwner returns (bool) {
        require(newReserve != address(0), "[eth] The new reserve address cannot be null");
        address oldReserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));
        require(newReserve != oldReserve, "[eth] The new reserve address is the same as the older reserver address");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isassigned", newReserve))), "[eth] The new reserve address has been assigned a role");

        storageContract.deleteBool(keccak256(abi.encodePacked("role.isreserve", oldReserve)));
        storageContract.deleteBool(keccak256(abi.encodePacked("role.isassigned", oldReserve)));

        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.reserve")), newReserve);
        storageContract.setBool(keccak256(abi.encodePacked("role.isreserve", newReserve)), true);
        storageContract.setBool(keccak256(abi.encodePacked("role.isassigned", newReserve)), true);

        emit SetReserve(oldReserve, newReserve);
        return true;
    }

    /* ---------------------------------------- Linked External Crypto Accounts ------------------------------------------ */

    /// @notice Check if an external crypto address has been linked to the toronet address
    /// @param toro toronet address
    /// @param crypto external crypto address
    function hasExtLink(address toro, address crypto) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", toro, crypto)));
    }

    /// @notice Get the total number of linked external crypto accounts
    /// @param toro toronet address
    function getNumberOfExtLink(address toro) public view returns(uint256) {
        return storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", toro)));
    }

    /// @notice Get the index of the crypto address linked to the toronet address
    /// @param toro toronet address
    /// @param crypto external crypto address
    /// @return index is the index of the admin
    /// @return err is the error code; 0 - no error; 1 - the crypto address is not linked to the toronet address
    function getExtLinkIndex(address toro, address crypto) public view returns(uint256 index, uint256 err) {
        index = uint256(2**256 - 1);
        err = 0;
        if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", toro, crypto)))) {
            err = 1;
            return (index, err);
        } else {
            index = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", toro, crypto)));
            return (index, 0);
        }
    }

    /// @notice Get the external linked crypto address by given index
    /// @param toro toronet address
    /// @param index the index of extlink
    /// @return crypto is the external crypto address
    /// @return err is the error code; 0 - no error; 1 - no existing extlink found; 2 - invalid index
    function getExtLinkByIndex(address toro, uint256 index) public view returns (address crypto, uint256 err) {
        crypto = address(0x0);
        err = 0;
        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", toro)));
        if (number == 0) {
            err = 1;
            return (crypto, err);
        }
        if (index > number - 1) {
            err = 2;
            return (crypto, err);
        }
        crypto = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", toro, index)));
        return (crypto, err);
    }

    /// @notice Check if an external crypto address has been linked to any toro address
    /// @param crypto external crypto address
    function isCryptoExtLinked(address crypto) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto)));
    }

    /// @notice Get the toronet address that an external crypto address has linked
    /// @param crypto external crypto address
    /// @return toro is the toronet address
    /// @return err is the error code; 0 - no error; 1 - the external crypto address has not been linked
    function getCryptoExtLinked(address crypto) public view returns (address toro, uint256 err) {
        toro = address(0);
        err = 0;

        if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto)))) {
            err = 1;
            return (toro, err);
        } else {
            toro = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.ext.linked", crypto)));
            return (toro, 0);
        }
    }

    /* -------------------------------------------- External Deposit Record ---------------------------------------------- */

    function isExtDeposited(bytes32 id) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.deposit", id)));
    }

    /* ------------------------------------------- External Withdraw Record ---------------------------------------------- */

    function isExtWithdrawn(bytes32 id) public view returns (bool) {
        return storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.withdraw", id)));
    }
}