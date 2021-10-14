// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Token Super Admin Management Contract
/// @author Wenhai Li
/// @notice These are the admin only functions to manage the eth crypto
/// @dev 06/24/2021
contract EthCryptoAdmin {

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

    /// @notice Event to manually enroll an address as a crypto account
    /// @param addr address to enroll
    event EnrollCryptoAccount(address indexed addr);

    /// @notice Event to manually disenroll an address as a crypto account
    /// @param addr address to disenroll
    event DisenrollCryptoAccount(address indexed addr);

    /// @notice Event to freeze a crypto account
    /// @param addr address to freeze
    event FreezeCryptoAccount(address indexed addr);

    /// @notice Event to unfreeze a crypto account
    /// @param addr address to unfreeze
    event UnfreezeCryptoAccount(address indexed addr);

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

    /// @notice Event to allow account-specified buy fee
    /// @param addr address to allow
    event AllowSelfToroBuyFee(address indexed addr);

    /// @notice Event to disallow account-specified buy fee
    /// @param addr address to disallow
    event DisallowSelfToroBuyFee(address indexed addr);

    /// @notice Event to set the account-specified fixed buy fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfToroBuyFeeFixed(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified percentage buy fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfToroBuyFeePercentage(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified fixed and percentage buy fee
    /// @param addr address to set
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetSelfToroBuyFee(address indexed addr, uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to allow account-specified sell fee
    /// @param addr address to allow
    event AllowSelfToroSellFee(address indexed addr);

    /// @notice Event to disallow account-specified sell fee
    /// @param addr address to disallow
    event DisallowSelfToroSellFee(address indexed addr);

    /// @notice Event to set the account-specified fixed sell fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfToroSellFeeFixed(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified percentage sell fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfToroSellFeePercentage(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified fixed and percentage sell fee
    /// @param addr address to set
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetSelfToroSellFee(address indexed addr, uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to allow account-specified import fee
    /// @param addr address to allow
    event AllowSelfCryptoImportFee(address indexed addr);

    /// @notice Event to disallow account-specified import fee
    /// @param addr address to disallow
    event DisallowSelfCryptoImportFee(address indexed addr);

    /// @notice Event to set the account-specified fixed import fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfCryptoImportFeeFixed(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified percentage import fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfCryptoImportFeePercentage(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified fixed and percentage import fee
    /// @param addr address to set
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetSelfCryptoImportFee(address indexed addr, uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to allow account-specified export fee
    /// @param addr address to allow
    event AllowSelfCryptoExportFee(address indexed addr);

    /// @notice Event to disallow account-specified export fee
    /// @param addr address to disallow
    event DisallowSelfCryptoExportFee(address indexed addr);

    /// @notice Event to set the account-specified fixed export fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfCryptoExportFeeFixed(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified percentage export fee
    /// @param addr address to set
    /// @param from original value
    /// @param to new value
    event SetSelfCryptoExportFeePercentage(address indexed addr, uint256 from, uint256 to);

    /// @notice Event to set the account-specified fixed and percentage export fee
    /// @param addr address to set
    /// @param oldFixed original fixed value
    /// @param newFixed new fixed value
    /// @param oldPercent original percentage value
    /// @param newPercent new percentage value
    event SetSelfCryptoExportFee(address indexed addr, uint256 oldFixed, uint256 newFixed, uint256 oldPercent, uint256 newPercent);

    /// @notice Event to transfer crypto by admin
    /// @param from sender address
    /// @param to receiver address
    /// @param value transfer amount
    /// @param fee transfer fee
    event AdminTransfer(address indexed from, address indexed to, uint256 value, uint256 fee);

    /// @notice Event to transfer crypto by admin with custom transaction fee
    /// @param from sender address
    /// @param to receiver address
    /// @param value transfer amount
    /// @param fee custom transfer fee
    event AdminTransferWithCustomFee(address indexed from, address indexed to, uint256 value, uint256 fee);

    /// @notice Event to import crypto in an account by admin
    /// @param addr address to import
    /// @param value import amount
    /// @param fee impport fee
    event ImportCrypto(address addr, uint256 value, uint256 fee);

    /// @notice Event to import crypto in an account by admin with custom fee
    /// @param addr address to import
    /// @param value import amount
    /// @param fee custom impport fee
    event ImportCryptoWithCustomFee(address addr, uint256 value, uint256 fee);

    /// @notice Event to export crypto in an account by admin
    /// @param addr address to export
    /// @param value export amount
    /// @param fee export fee
    event ExportCrypto(address addr, uint256 value, uint256 fee);

    /// @notice Event to export crypto in an account by admin
    /// @param addr address to export
    /// @param value export amount
    /// @param fee custom export fee
    event ExportCryptoWithCustomFee(address addr, uint256 value, uint256 fee);

    /// @notice Event to buy toro with the crypto by admin
    /// @param addr account address
    /// @param crypto amount of crypto to spend
    /// @param toro amount of toro obtained
    /// @param fee purchase fee [eth]
    event AdminBuyToro(address indexed addr, uint256 crypto, uint256 toro, uint256 fee);

    /// @notice Event to buy toro with the crypto by admin
    /// @param addr account address
    /// @param crypto amount of crypto to spend
    /// @param toro amount of toro obtained
    /// @param fee custom purchase fee [eth]
    event AdminBuyTororWithCustomFee(address indexed addr, uint256 crypto, uint256 toro, uint256 fee);


    /// @notice Event to sell toro to the crypto by admin
    /// @param addr account address
    /// @param toro amount of toro to spend
    /// @param crypto amount of crypto obtained
    /// @param fee sell fee [eth]
    event AdminSellToro(address indexed addr, uint256 toro, uint256 crypto, uint256 fee);


    /// @notice Event to sell toro to the crypto by admin
    /// @param addr account address
    /// @param toro amount of toro to spend
    /// @param crypto amount of crypto obtained
    /// @param fee sell fee [eth]
    event AdminSellToroWithCustomFee(address indexed addr, uint256 toro, uint256 crypto, uint256 fee);

    /// @notice Event to register an external crypto address
    /// @param toro toronet address
    /// @param crypto external crypto address
    event AdminAddExtLink(address indexed toro, address indexed crypto);

    /// @notice Event to unregister an external crypto address
    /// @param toro toronet address
    /// @param crypto external crypto address
    event AdminRemoveExtLink(address indexed toro, address indexed crypto);


    /// @notice Event to unregister all external crypto addresses
    /// @param toro toronet address
    /// @param num originial number of registered external addressses
    event AdminRemoveAllExtLinks(address indexed toro, uint256 num);

    /// @notice Event to deposit external crypto in an account by admin
    /// @param addr address to import
    /// @param value import amount
    /// @param id deposit transaction id
    /// @param fee impport fee
    event DepositCrypto(address addr, uint256 value, bytes32 id, uint256 fee);


    /// @notice Event to withdraw crypto to external account by admin
    /// @param toro_addr toronet address to export
    /// @param eth_addr external eth address to deposit
    /// @param value export amount
    /// @param fee export fee
    event AdminWithdrawCrypto(address toro_addr, address eth_addr,  uint256 value, uint256 fee);

    /// @notice Event to confirm withdraw
    /// @param id withdraw id
    event ConfirmWithdraw(bytes32 id);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[eth.admin] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.eth.admin")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* ---------------------------------------------- Management Functions ----------------------------------------------- */

    /// @notice Manually enroll an address as a crypto account
    /// @param addr The address to enroll
    /// @dev The function is only used when AllowSelfEnroll is false
    function enrollCryptoAccount(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", addr)), true);
        emit EnrollCryptoAccount(addr);
        return true;
    }

    /// @notice Manually disenroll an address as a crypto account
    /// @param addr The address to disenroll
    /// @dev The function is only used when AllowSelfEnroll is false
    function disenrollCryptoAccount(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", addr)), false);
        emit DisenrollCryptoAccount(addr);
        return true;
    }

    /// @notice Freeze a crypto account
    /// @param addr The address to freeze
    function freezeCryptoAccount(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr)), true);
        emit FreezeCryptoAccount(addr);
        return true;
    }

    /// @notice Unfreeze a crypto account
    /// @param addr The address to unfreeze
    function unfreezeCryptoAccount(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr)), false);
        emit UnfreezeCryptoAccount(addr);
        return true;
    }

    /// @notice Allow account-specified transfer allowance for an account
    /// @param addr The address of the account
    function allowSelfAllowance(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr))), "[eth.admin] The account-specified allowance is currently activated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)), true);
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))));
        }
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))));
        }
        emit AllowSelfAllowance(addr);
        return true;
    }

    /// @notice Disallow account-specified transfer allowance for an account
    /// @param addr The address of the account
    function disallowSelfAllowance(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr))), "[eth.admin] The account-specified allowance is currently deactivated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)), false);
        emit DisallowSelfAllowance(addr);
        return true;
    }

    /// @notice Set account-specified transfer minimum allowance for an account
    /// @param addr The address of the account
    /// @param newMinimumAmount the new minimum allowance
    function setSelfMinimumAllowance(address addr, uint256 newMinimumAmount) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr)));
        require(newMinimumAmount != oldMinimumAmount, "[eth.admin] The account-specified minimum allowance is not changed");
        uint256 currentMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr)));
        require(newMinimumAmount < currentMaximumAmount, "[eth.admin] The account-specified minimum allowance value is too large");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr)), newMinimumAmount);
        emit SetSelfMinimumAllowance(addr, oldMinimumAmount, newMinimumAmount);
        return true;
    }

    /// @notice Set account-specified transfer maximum allowance for an account
    /// @param addr The address of the account
    /// @param newMaximumAmount the new maximum allowance
    function setSelfMaximumAllowance(address addr, uint256 newMaximumAmount) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr)));
        require(newMaximumAmount != oldMaximumAmount, "[eth.admin] The account-specified maximum allowance is not changed");
        uint256 currentMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr)));
        require(newMaximumAmount > currentMinimumAmount, "[eth.admin] The account-specified maximum allowance value is too small");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr)), newMaximumAmount);
        emit SetSelfMaximumAllowance(addr, oldMaximumAmount, newMaximumAmount);
        return true;
    }

    /// @notice Set account-specified transfer minimum and maximum allowance for an account
    /// @param addr The address of the account
    /// @param newMinimumAmount the new minimum allowance
    /// @param newMaximumAmount the new maximum allowance
    function setSelfAllowance(address addr, uint256 newMinimumAmount, uint256 newMaximumAmount) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newMinimumAmount < newMaximumAmount, "[eth.admin] The max/min values are invalid");
        uint256 oldMinimumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr)));
        uint256 oldMaximumAmount = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr)));
        require (newMinimumAmount != oldMinimumAmount || newMaximumAmount != oldMaximumAmount, "[eth.admin] No change in account-specified allowance values");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr)), newMinimumAmount);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr)), newMaximumAmount);
        emit SetSelfAllowance(addr, oldMinimumAmount, newMinimumAmount, oldMaximumAmount, newMaximumAmount);
        return true;
    }

    /// @notice Allow account-specified transfer fee for an account
    /// @param addr The address of the account
    function allowSelfTransactionFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.txfee", addr))), "[eth.admin] The account-specified transaction fee is currently activated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.txfee", addr)), true);
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default"))));
        }
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default"))));
        }
        emit AllowSelfTransactionFee(addr);
        return true;
    }

    /// @notice Disallow account-specified transfer fee for an account
    /// @param addr The address of the account
    function disallowSelfTransactionFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.txfee", addr))), "[eth.admin] The account-specified transaction fee is currently deactivated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.txfee", addr)), false);
        emit DisallowSelfTransactionFee(addr);
        return true;
    }

    /// @notice Set account-specified fixed transaction fee for an account
    /// @param addr The address of the account
    /// @param newTransactionFeeFixed the new fixed transaction fee
    function setSelfTransactionFeeFixed(address addr, uint256 newTransactionFeeFixed) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldTransactionFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", addr)));
        require(newTransactionFeeFixed != oldTransactionFeeFixed, "[eth.admin] The account-specified fixed transaction fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", addr)), newTransactionFeeFixed);
        emit SetSelfTransactionFeeFixed(addr, oldTransactionFeeFixed, newTransactionFeeFixed);
        return true;
    }

    /// @notice Set account-specified percentage transaction fee for an account
    /// @param addr The address of the account
    /// @param newTransactionFeePercentage the new percentage transaction fee
    function setSelfTransactionFeePercentage(address addr, uint256 newTransactionFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newTransactionFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage transaction fee is invalid");
        uint256 oldTransactionFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", addr)));
        require(newTransactionFeePercentage != oldTransactionFeePercentage, "[eth.admin] The account-specified percentage transaction fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", addr)), newTransactionFeePercentage);
        emit SetSelfTransactionFeePercentage(addr, oldTransactionFeePercentage, newTransactionFeePercentage);
        return true;
    }

    /// @notice Set account-specified fixed and percentage transaction fee for an account
    /// @param addr The address of the account
    /// @param newTransactionFeeFixed the new fixed transaction fee
    /// @param newTransactionFeePercentage the new percentage transaction fee
    function setSelfTransactionFee(address addr, uint256 newTransactionFeeFixed, uint256 newTransactionFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newTransactionFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage transaction fee is invalid");
        uint256 oldTransactionFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", addr)));
        uint256 oldTransactionFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", addr)));
        require(newTransactionFeeFixed != oldTransactionFeeFixed || newTransactionFeePercentage != oldTransactionFeePercentage, "[eth.admin] No change in account-specified transaction fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", addr)), newTransactionFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", addr)), newTransactionFeePercentage);
        emit SetSelfTransactionFee(addr, oldTransactionFeeFixed, newTransactionFeeFixed, oldTransactionFeePercentage, newTransactionFeePercentage);
        return true;
    }

    /// @notice Allow account-specified transfer fee for an account
    /// @param addr The address of the account
    function allowSelfToroBuyFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.buyfee", addr))), "[eth.admin] The account-specified buy fee is currently activated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.buyfee", addr)), true);
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default"))));
        }
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default"))));
        }
        emit AllowSelfToroBuyFee(addr);
        return true;
    }

    /// @notice Disallow account-specified transfer fee for an account
    /// @param addr The address of the account
    function disallowSelfToroBuyFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.buyfee", addr))), "[eth.admin] The account-specified buy fee is currently deactivated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.buyfee", addr)), false);
        emit DisallowSelfToroBuyFee(addr);
        return true;
    }

    /// @notice Set account-specified fixed buy fee for an account
    /// @param addr The address of the account
    /// @param newToroBuyFeeFixed the new fixed buy fee
    function setSelfToroBuyFeeFixed(address addr, uint256 newToroBuyFeeFixed) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldToroBuyFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", addr)));
        require(newToroBuyFeeFixed != oldToroBuyFeeFixed, "[eth.admin] The account-specified fixed buy fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", addr)), newToroBuyFeeFixed);
        emit SetSelfToroBuyFeeFixed(addr, oldToroBuyFeeFixed, newToroBuyFeeFixed);
        return true;
    }

    /// @notice Set account-specified percentage buy fee for an account
    /// @param addr The address of the account
    /// @param newToroBuyFeePercentage the new percentage buy fee
    function setSelfToroBuyFeePercentage(address addr, uint256 newToroBuyFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newToroBuyFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage buy fee is invalid");
        uint256 oldToroBuyFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", addr)));
        require(newToroBuyFeePercentage != oldToroBuyFeePercentage, "[eth.admin] The account-specified percentage buy fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", addr)), newToroBuyFeePercentage);
        emit SetSelfToroBuyFeePercentage(addr, oldToroBuyFeePercentage, newToroBuyFeePercentage);
        return true;
    }

    /// @notice Set account-specified fixed and percentage buy fee for an account
    /// @param addr The address of the account
    /// @param newToroBuyFeeFixed the new fixed buy fee
    /// @param newToroBuyFeePercentage the new percentage buy fee
    function setSelfToroBuyFee(address addr, uint256 newToroBuyFeeFixed, uint256 newToroBuyFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newToroBuyFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage buy fee is invalid");
        uint256 oldToroBuyFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", addr)));
        uint256 oldToroBuyFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", addr)));
        require(newToroBuyFeeFixed != oldToroBuyFeeFixed || newToroBuyFeePercentage != oldToroBuyFeePercentage, "[eth.admin] No change in account-specified buy fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", addr)), newToroBuyFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", addr)), newToroBuyFeePercentage);
        emit SetSelfToroBuyFee(addr, oldToroBuyFeeFixed, newToroBuyFeeFixed, oldToroBuyFeePercentage, newToroBuyFeePercentage);
        return true;
    }

    /// @notice Allow account-specified transfer fee for an account
    /// @param addr The address of the account
    function allowSelfToroSellFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.sellfee", addr))), "[eth.admin] The account-specified sell fee is currently activated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.sellfee", addr)), true);
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default"))));
        }
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default"))));
        }
        emit AllowSelfToroSellFee(addr);
        return true;
    }

    /// @notice Disallow account-specified transfer fee for an account
    /// @param addr The address of the account
    function disallowSelfToroSellFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.sellfee", addr))), "[eth.admin] The account-specified sell fee is currently deactivated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.sellfee", addr)), false);
        emit DisallowSelfToroSellFee(addr);
        return true;
    }

    /// @notice Set account-specified fixed sell fee for an account
    /// @param addr The address of the account
    /// @param newToroSellFeeFixed the new fixed sell fee
    function setSelfToroSellFeeFixed(address addr, uint256 newToroSellFeeFixed) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldToroSellFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", addr)));
        require(newToroSellFeeFixed != oldToroSellFeeFixed, "[eth.admin] The account-specified fixed sell fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", addr)), newToroSellFeeFixed);
        emit SetSelfToroSellFeeFixed(addr, oldToroSellFeeFixed, newToroSellFeeFixed);
        return true;
    }

    /// @notice Set account-specified percentage sell fee for an account
    /// @param addr The address of the account
    /// @param newToroSellFeePercentage the new percentage sell fee
    function setSelfToroSellFeePercentage(address addr, uint256 newToroSellFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newToroSellFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage sell fee is invalid");
        uint256 oldToroSellFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", addr)));
        require(newToroSellFeePercentage != oldToroSellFeePercentage, "[eth.admin] The account-specified percentage sell fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", addr)), newToroSellFeePercentage);
        emit SetSelfToroSellFeePercentage(addr, oldToroSellFeePercentage, newToroSellFeePercentage);
        return true;
    }

    /// @notice Set account-specified fixed and percentage sell fee for an account
    /// @param addr The address of the account
    /// @param newToroSellFeeFixed the new fixed sell fee
    /// @param newToroSellFeePercentage the new percentage sell fee
    function setSelfToroSellFee(address addr, uint256 newToroSellFeeFixed, uint256 newToroSellFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newToroSellFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage sell fee is invalid");
        uint256 oldToroSellFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", addr)));
        uint256 oldToroSellFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", addr)));
        require(newToroSellFeeFixed != oldToroSellFeeFixed || newToroSellFeePercentage != oldToroSellFeePercentage, "[eth.admin] No change in account-specified sell fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", addr)), newToroSellFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", addr)), newToroSellFeePercentage);
        emit SetSelfToroSellFee(addr, oldToroSellFeeFixed, newToroSellFeeFixed, oldToroSellFeePercentage, newToroSellFeePercentage);
        return true;
    }

    /// @notice Allow account-specified transfer fee for an account
    /// @param addr The address of the account
    function allowSelfCryptoImportFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.importfee", addr))), "[eth.admin] The account-specified import fee is currently activated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.importfee", addr)), true);
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default"))));
        }
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default"))));
        }
        emit AllowSelfCryptoImportFee(addr);
        return true;
    }

    /// @notice Disallow account-specified transfer fee for an account
    /// @param addr The address of the account
    function disallowSelfCryptoImportFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.importfee", addr))), "[eth.admin] The account-specified import fee is currently deactivated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.importfee", addr)), false);
        emit DisallowSelfCryptoImportFee(addr);
        return true;
    }

    /// @notice Set account-specified fixed import fee for an account
    /// @param addr The address of the account
    /// @param newCryptoImportFeeFixed the new fixed import fee
    function setSelfCryptoImportFeeFixed(address addr, uint256 newCryptoImportFeeFixed) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldCryptoImportFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", addr)));
        require(newCryptoImportFeeFixed != oldCryptoImportFeeFixed, "[eth.admin] The account-specified fixed import fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", addr)), newCryptoImportFeeFixed);
        emit SetSelfCryptoImportFeeFixed(addr, oldCryptoImportFeeFixed, newCryptoImportFeeFixed);
        return true;
    }

    /// @notice Set account-specified percentage import fee for an account
    /// @param addr The address of the account
    /// @param newCryptoImportFeePercentage the new percentage import fee
    function setSelfCryptoImportFeePercentage(address addr, uint256 newCryptoImportFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newCryptoImportFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage import fee is invalid");
        uint256 oldCryptoImportFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", addr)));
        require(newCryptoImportFeePercentage != oldCryptoImportFeePercentage, "[eth.admin] The account-specified percentage import fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", addr)), newCryptoImportFeePercentage);
        emit SetSelfCryptoImportFeePercentage(addr, oldCryptoImportFeePercentage, newCryptoImportFeePercentage);
        return true;
    }

    /// @notice Set account-specified fixed and percentage import fee for an account
    /// @param addr The address of the account
    /// @param newCryptoImportFeeFixed the new fixed import fee
    /// @param newCryptoImportFeePercentage the new percentage import fee
    function setSelfCryptoImportFee(address addr, uint256 newCryptoImportFeeFixed, uint256 newCryptoImportFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newCryptoImportFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage import fee is invalid");
        uint256 oldCryptoImportFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", addr)));
        uint256 oldCryptoImportFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", addr)));
        require(newCryptoImportFeeFixed != oldCryptoImportFeeFixed || newCryptoImportFeePercentage != oldCryptoImportFeePercentage, "[eth.admin] No change in account-specified import fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", addr)), newCryptoImportFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", addr)), newCryptoImportFeePercentage);
        emit SetSelfCryptoImportFee(addr, oldCryptoImportFeeFixed, newCryptoImportFeeFixed, oldCryptoImportFeePercentage, newCryptoImportFeePercentage);
        return true;
    }

    /// @notice Allow account-specified transfer fee for an account
    /// @param addr The address of the account
    function allowSelfCryptoExportFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.exportfee", addr))), "[eth.admin] The account-specified export fee is currently activated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.exportfee", addr)), true);
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default"))));
        }
        if (storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", addr))) == 0) {
            storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", addr)), storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default"))));
        }
        emit AllowSelfCryptoExportFee(addr);
        return true;
    }

    /// @notice Disallow account-specified transfer fee for an account
    /// @param addr The address of the account
    function disallowSelfCryptoExportFee(address addr) public onlyAdmin onlyClient(addr) returns (bool) {
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.exportfee", addr))), "[eth.admin] The account-specified export fee is currently deactivated");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.allowself.exportfee", addr)), false);
        emit DisallowSelfCryptoExportFee(addr);
        return true;
    }

    /// @notice Set account-specified fixed export fee for an account
    /// @param addr The address of the account
    /// @param newCryptoExportFeeFixed the new fixed export fee
    function setSelfCryptoExportFeeFixed(address addr, uint256 newCryptoExportFeeFixed) public onlyAdmin onlyClient(addr) returns (bool) {
        uint256 oldCryptoExportFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", addr)));
        require(newCryptoExportFeeFixed != oldCryptoExportFeeFixed, "[eth.admin] The account-specified fixed export fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", addr)), newCryptoExportFeeFixed);
        emit SetSelfCryptoExportFeeFixed(addr, oldCryptoExportFeeFixed, newCryptoExportFeeFixed);
        return true;
    }

    /// @notice Set account-specified percentage export fee for an account
    /// @param addr The address of the account
    /// @param newCryptoExportFeePercentage the new percentage export fee
    function setSelfCryptoExportFeePercentage(address addr, uint256 newCryptoExportFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newCryptoExportFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage export fee is invalid");
        uint256 oldCryptoExportFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", addr)));
        require(newCryptoExportFeePercentage != oldCryptoExportFeePercentage, "[eth.admin] The account-specified percentage export fee is not changed");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", addr)), newCryptoExportFeePercentage);
        emit SetSelfCryptoExportFeePercentage(addr, oldCryptoExportFeePercentage, newCryptoExportFeePercentage);
        return true;
    }

    /// @notice Set account-specified fixed and percentage export fee for an account
    /// @param addr The address of the account
    /// @param newCryptoExportFeeFixed the new fixed export fee
    /// @param newCryptoExportFeePercentage the new percentage export fee
    function setSelfCryptoExportFee(address addr, uint256 newCryptoExportFeeFixed, uint256 newCryptoExportFeePercentage) public onlyAdmin onlyClient(addr) returns (bool) {
        require(newCryptoExportFeePercentage <= 100 * 1 ether, "[eth.admin] The account-specified percentage export fee is invalid");
        uint256 oldCryptoExportFeeFixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", addr)));
        uint256 oldCryptoExportFeePercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", addr)));
        require(newCryptoExportFeeFixed != oldCryptoExportFeeFixed || newCryptoExportFeePercentage != oldCryptoExportFeePercentage, "[eth.admin] No change in account-specified export fee");
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", addr)), newCryptoExportFeeFixed);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", addr)), newCryptoExportFeePercentage);
        emit SetSelfCryptoExportFee(addr, oldCryptoExportFeeFixed, newCryptoExportFeeFixed, oldCryptoExportFeePercentage, newCryptoExportFeePercentage);
        return true;
    }

    /* -------------------------------------------- Admin Transfer Functions --------------------------------------------- */

    /// @notice Transfer crypto from one address to another by admin
    /// @param from the sender address
    /// @param to the receiver address
    /// @param value the transfer amount
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function adminTransfer(address from, address to, uint256 value) public onlyAdmin onlyApprovedClient(from) returns (bool) {
        require(from != address(0), "[eth.admin] The sender address cannot be null");
        require(to != address(0), "[eth.admin] The receiver address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", from))), "[eth.admin] The sender address cannot be a reserve");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", to))), "[eth.admin] The receiver address cannot be a reserve");
        require(from != to, "[eth.admin] An address cannot send crypto to itself");
        require(value > 0, "[eth.admin] The ammount to send cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", from))), "[eth.admin] Invalid address to send crypto");
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", to))), "[eth.admin] Invalid address to receive crypto");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.transfer"))), "[eth.admin] The eth transfer is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",from)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", from)))) {
                    revert("[eth.admin] The sender address has not been enrolled as an crypto account");
                }
            }
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",to)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", to)))) {
                    revert("[eth.admin] The receiver address has not been enrolled as an crypto account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", from))), "[eth.admin] The sender account has been freezed");
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", to))), "[eth.admin] The receiver account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", from)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", from))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", from))), "[eth.admin] The ammount to send is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to send is too large");
            }
        }

        uint256 txfee = _calculateTxFee(from, value);
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", from))) >= value + txfee, "[eth.admin] Insufficient sender account balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", from)), value + txfee);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", to)), value);

        if (txfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(txfee);
                require(comm <= txfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), txfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), txfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), txfee);
        }

        emit AdminTransfer(from, to, value, txfee);
        return true;
    }

    /// @notice Transfer crypto from one address to another by admin with custom transaction fee
    /// @param from the sender address
    /// @param to the receiver address
    /// @param value the transfer amount
    /// @param txfee the custom transaction fee
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function adminTransferWithCustomFee(address from, address to, uint256 value, uint256 txfee) public onlyAdmin onlyApprovedClient(from) returns (bool) {
        require(from != address(0), "[eth.admin] The sender address cannot be null");
        require(to != address(0), "[eth.admin] The receiver address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", from))), "[eth.admin] The sender address cannot be a reserve");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", to))), "[eth.admin] The receiver address cannot be a reserve");
        require(from != to, "[eth.admin] An address cannot send crypto to itself");
        require(value > 0, "[eth.admin] The ammount to send cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", from))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", from))), "[eth.admin] Invalid address to send crypto");
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", to))), "[eth.admin] Invalid address to receive crypto");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.transfer"))), "[eth.admin] The eth transfer is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",from)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", from)))) {
                    revert("[eth.admin] The sender address has not been enrolled as an crypto account");
                }
            }
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",to)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", to)))) {
                    revert("[eth.admin] The receiver address has not been enrolled as an crypto account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", from))), "[eth.admin] The sender account has been freezed");
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", to))), "[eth.admin] The receiver account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", from)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", from))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", from))), "[eth.admin] The ammount to send is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to send is too large");
            }
        }

        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", from))) >= value + txfee, "[eth.admin] Insufficient sender account balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", from)), value + txfee);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", to)), value);

        if (txfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(txfee);
                require(comm <= txfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), txfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), txfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), txfee);
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
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.txfee", from)))) {
            txfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed", from)));
            txfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent", from)));
        }
        else {
            txfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.fixed.default")));
            txfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.txfee.percent.default")));
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
        uint256 commissionPercentage = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.commission.percent")));
        uint256 commissionShare = txfee * commissionPercentage / 100 / 1 ether;
        return commissionShare;
    }

    /* ---------------------------------------------- Admin Import Functions --------------------------------------------- */

    /// @notice Import crypto in an account
    /// @param addr address to import
    /// @param value amount to import
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function importCrypto(address addr, uint256 value) public onlyDigitalAdmin onlyClient(addr) returns (bool) {
        require(addr != address(0), "[eth.admin] The import address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The import address cannot be a reserve");
        require(value > 0, "[eth.admin] The import value cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid address to import crypto");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.import"))), "[eth.admin] The eth import is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",addr)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", addr)))) {
                    revert("[eth.admin] The import address has not been enrolled as an crypto account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The import account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr))), "[eth.admin] The ammount to import is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr))), "[eth.admin] The ammount to import is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to import is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to import is too large");
            }
        }

        uint256 importfee = _calculateImportFee(addr, value);
        require(importfee < value, "[eth.admin] Insufficient import amount");
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value - importfee);
        if (importfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(importfee);
                require(comm <= importfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), importfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), importfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), importfee);
        }

        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value);
        emit ImportCrypto(addr, value, importfee);
        return true;
    }

    /// @notice Calculate import fee
    /// @param addr Account address
    /// @param val Transfer amount
    /// @dev Client can use this function before the crypto import to get the potential import fee
    function adminCalculateImportFee(address addr, uint256 val) public view returns (uint256) {
        return (_calculateImportFee(addr, val));
    }

    function _calculateImportFee(address from, uint256 val) internal view returns (uint256) {
        uint256 importfee;
        uint256 importfee_fixed;
        uint256 importfee_percent;
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.importfee", from)))) {
            importfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed", from)));
            importfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent", from)));
        }
        else {
            importfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.fixed.default")));
            importfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.importfee.percent.default")));
        }

        uint256 percent = val * importfee_percent / 100 / 1 ether;
        if (percent > importfee_fixed) {
            importfee = percent;
        }
        else {
            importfee = importfee_fixed;
        }
        return importfee;
    }

    /// @notice Import crypto in an account with custom fee
    /// @param addr address to import
    /// @param value amount to import
    /// @param importfee custom fee
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function importCryptoWithCustomFee(address addr, uint256 value, uint256 importfee) public onlyDigitalAdmin onlyClient(addr) returns (bool) {
        require(addr != address(0), "[eth.admin] The import address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The import address cannot be a reserve");
        require(value > 0, "[eth.admin] The import value cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid address to import crypto");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.import"))), "[eth.admin] The eth import is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",addr)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", addr)))) {
                    revert("[eth.admin] The import address has not been enrolled as an crypto account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The import account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr))), "[eth.admin] The ammount to import is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr))), "[eth.admin] The ammount to import is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to import is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to import is too large");
            }
        }

        require(importfee < value, "[eth.admin] Insufficient import amount");
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value - importfee);
        if (importfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(importfee);
                require(comm <= importfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), importfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), importfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), importfee);
        }

        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value);
        emit ImportCryptoWithCustomFee(addr, value, importfee);
        return true;
    }


    /* ---------------------------------------------- Admin Export Functions --------------------------------------------- */

    /// @notice Export crypto in an account
    /// @param addr address to export
    /// @param value amount to export
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function exportCrypto(address addr, uint256 value) public onlyDigitalAdmin onlyClient(addr) returns (bool) {
        require(addr != address(0), "[eth.admin] The export address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The export address cannot be a reserve");
        require(value > 0, "[eth.admin] The export value cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid address to import crypto");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.export"))), "[eth.admin] The eth export is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",addr)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", addr)))) {
                    revert("[eth.admin] The export address has not been enrolled as an crypto account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The export account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr))), "[eth.admin] The ammount to export is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr))), "[eth.admin] The ammount to export is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to export is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to export is too large");
            }
        }
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr))) >= value, "[eth.admin] Export value is too large");

        uint256 exportfee = _calculateExportFee(addr, value);
        require(exportfee < value, "[eth.admin] Insufficient export amount");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalcap"))) >= value - exportfee, "[eth.admin] Export value is too large");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value);
        if (exportfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(exportfee);
                require(comm <= exportfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), exportfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), exportfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), exportfee);
        }

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value - exportfee);
        emit ExportCrypto(addr, value, exportfee);
        return true;
    }

    /// @notice Calculate export fee
    /// @param addr Account address
    /// @param val Transfer amount
    /// @dev Client can use this function before the crypto export to get the potential export fee
    function adminCalculateExportFee(address addr, uint256 val) public view returns (uint256) {
        return (_calculateExportFee(addr, val));
    }

    function _calculateExportFee(address from, uint256 val) internal view returns (uint256) {
        uint256 exportfee;
        uint256 exportfee_fixed;
        uint256 exportfee_percent;
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.exportfee", from)))) {
            exportfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed", from)));
            exportfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent", from)));
        }
        else {
            exportfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.fixed.default")));
            exportfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exportfee.percent.default")));
        }

        uint256 percent = val * exportfee_percent / 100 / 1 ether;
        if (percent > exportfee_fixed) {
            exportfee = percent;
        }
        else {
            exportfee = exportfee_fixed;
        }
        return exportfee;
    }

    /// @notice Export crypto in an account with custom fee
    /// @param addr address to export
    /// @param value amount to export
    /// @param exportfee custom export fee
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function exportCryptoWithCustomFee(address addr, uint256 value, uint256 exportfee) public onlyDigitalAdmin onlyClient(addr) returns (bool) {
        require(addr != address(0), "[eth.admin] The export address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The export address cannot be a reserve");
        require(value > 0, "[eth.admin] The export value cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid address to import crypto");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.export"))), "[eth.admin] The eth export is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",addr)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", addr)))) {
                    revert("[eth.admin] The export address has not been enrolled as an crypto account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The export account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr))), "[eth.admin] The ammount to export is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr))), "[eth.admin] The ammount to export is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to export is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to export is too large");
            }
        }
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr))) >= value, "[eth.admin] Export value is too large");

        require(exportfee < value, "[eth.admin] Insufficient export amount");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalcap"))) >= value - exportfee, "[eth.admin] Export value is too large");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value);
        if (exportfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(exportfee);
                require(comm <= exportfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), exportfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), exportfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), exportfee);
        }

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value - exportfee);
        emit ExportCryptoWithCustomFee(addr, value, exportfee);
        return true;
    }

    /* -------------------------------------------- Admin Toro Buy Functions --------------------------------------------- */

    /// @notice Admin buy toro with the crypto
    /// @param addr Account address
    /// @param value Amount of crypto to spend
    /// @dev note that during the purchase, client's crypto balance is moved to reserve, and toro reserve send the toro to client
    /// @dev note that the additional sell fee is charged in the crypto, not the toro
    function adminBuyToro(address addr, uint256 value) public onlyAdmin onlyApprovedClient(addr) returns (bool) {
        require(addr != address(0), "[eth.admin] The account address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The account address cannot be a reserve");
        require(value > 0, "[eth.admin] The ammount to purchase cannot be zero");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr))) >= value, "[eth.admin] Insufficient account crypto balance");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid account address");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.buy"))), "[eth.admin] The toro purchase is currently unavailable");
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The crypto account has been freezed");
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr))), "[eth.admin] The toro account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr))), "[eth.admin] The ammount to send is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to send is too large");
            }
        }

        uint256 buyfee = _calculateBuyFee(addr, value);
        require(buyfee < value, "[eth.admin] Insufficient purchase amount");

        uint256 toro_amount = (value - buyfee) * storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate"))) / 1 ether;

        address toro_reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        address crypto_reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));

        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve))) >= toro_amount, "[eth.admin] Insufficient toro reserve balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve)), value - buyfee);

        if (buyfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(buyfee);
                require(comm <= buyfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), buyfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), buyfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), buyfee);
        }

        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", addr)), toro_amount);
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve)), toro_amount);

        emit AdminBuyToro(addr, value, toro_amount, buyfee);

        return true;
    }

    function _calculateBuyFee(address from, uint256 val) internal view returns (uint256) {
        uint256 buyfee;
        uint256 buyfee_fixed;
        uint256 buyfee_percent;
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.buyfee", from)))) {
            buyfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed", from)));
            buyfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent", from)));
        }
        else {
            buyfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.fixed.default")));
            buyfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.buyfee.percent.default")));
        }

        uint256 percent = val * buyfee_percent / 100 / 1 ether;
        if (percent > buyfee_fixed) {
            buyfee = percent;
        }
        else {
            buyfee = buyfee_fixed;
        }
        return buyfee;
    }

    /// @notice Calculate buy fee
    /// @param addr Account address
    /// @param val Amount to buy with the crypto
    /// @dev Admin can use this function before the crypto buy to get the potential buy fee
    function adminCalculateBuyFee(address addr, uint256 val) public view returns (uint256) {
        return (_calculateBuyFee(addr, val));
    }

    /// @notice Calculate buy result
    /// @param addr Account address
    /// @param val Amount to buy with the crypto
    /// @return amount is the toro amount to obtain
    /// @return err is the error code; 0 - no error; 1 - insufficient purchase amount
    /// @dev Admin can use this function before the toro buy to estimate the toro amount to obtain
    function adminCalculateBuyResult(address addr, uint256 val) public view returns (uint256 amount, uint256 err) {
        amount = 0;
        err = 0;

        uint256 buyfee = _calculateBuyFee(addr, val);
        if (buyfee > val) {
            err = 1;
            return (amount, err);
        }

        amount = (val - buyfee) * storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate"))) / 1 ether;
        return (amount, err);
    }

    /// @notice Admin buy toro with the crypto
    /// @param addr Account address
    /// @param value Amount of crypto to spend
    /// @param buyfee Custom buy fee
    /// @dev note that during the purchase, client's crypto balance is moved to reserve, and toro reserve send the toro to client
    /// @dev note that the additional sell fee is charged in the crypto, not the toro
    function adminBuyToroWithCustomFee(address addr, uint256 value, uint256 buyfee) public onlyAdmin onlyApprovedClient(addr) returns (bool) {
        require(addr != address(0), "[eth.admin] The account address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The account address cannot be a reserve");
        require(value > 0, "[eth.admin] The ammount to purchase cannot be zero");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr))) >= value, "[eth.admin] Insufficient account crypto balance");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid account address");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.buy"))), "[eth.admin] The toro purchase is currently unavailable");
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The crypto account has been freezed");
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr))), "[eth.admin] The toro account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr))), "[eth.admin] The ammount to send is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to send is too large");
            }
        }

        require(buyfee < value, "[eth.admin] Insufficient purchase amount");

        uint256 toro_amount = (value - buyfee) * storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate"))) / 1 ether;

        address toro_reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        address crypto_reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));

        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve))) >= toro_amount, "[eth.admin] Insufficient toro reserve balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve)), value - buyfee);

        if (buyfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(buyfee);
                require(comm <= buyfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), buyfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), buyfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), buyfee);
        }

        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", addr)), toro_amount);
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve)), toro_amount);

        emit AdminBuyTororWithCustomFee(addr, value, toro_amount, buyfee);

        return true;
    }

    /// @notice Calculate buy result
    /// @param val Amount to buy with the crypto
    /// @param buyfee Custom buy fee
    /// @return amount is the toro amount to obtain
    /// @return err is the error code; 0 - no error; 1 - insufficient purchase amount
    /// @dev Admin can use this function before the toro buy to estimate the toro amount to obtain
    function adminCalculateBuyResultWithCustomFee(uint256 val, uint256 buyfee) public view returns (uint256 amount, uint256 err) {
        amount = 0;
        err = 0;

        if (buyfee > val) {
            err = 1;
            return (amount, err);
        }

        amount = (val - buyfee) * storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate"))) / 1 ether;
        return (amount, err);
    }

    /* -------------------------------------------- Admin Toro Sell Functions -------------------------------------------- */

    /// @notice Admin sell toro to the crypto
    /// @param addr Account address
    /// @param value Amount of toro to spend
    /// @dev note that during the sell, client's toro balance is moved to reserve, and crypto reserve send the crypto to client
    /// @dev note that the additional sell fee is charged in the crypto, not the toro
    function adminSellToro(address addr, uint256 value) public onlyAdmin onlyApprovedClient(addr) returns (bool) {
        require(addr != address(0), "[eth.admin] The account address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The account address cannot be a reserve");
        require(value > 0, "[eth.admin] The ammount to purchase cannot be zero");
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", addr))) >= value, "[eth.admin] Insufficient account toro balance");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid account address");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.sell"))), "[eth.admin] The toro sell is currently unavailable");
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The crypto account has been freezed");
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr))), "[eth.admin] The toro account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr))), "[eth.admin] The ammount to send is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))), "[eth.admin] The ammount to send is too large");
            }
        }

        uint256 crypto_amount = 1 ether * value / storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));

        address toro_reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        address crypto_reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));

        uint256 sellfee = _calculateSellFee(addr, crypto_amount);
        require(sellfee < crypto_amount, "[eth.admin] Insufficient sell amount");

        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve))) >= crypto_amount, "[eth.admin] Insufficient crypto reserve balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve)), crypto_amount);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), crypto_amount - sellfee);

        if (sellfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(sellfee);
                require(comm <= sellfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), sellfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), sellfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), sellfee);
        }

        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", addr)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve)), value);

        emit AdminSellToro(addr, value, crypto_amount, sellfee);
        return true;
    }

    function _calculateSellFee(address from, uint256 val) internal view returns (uint256) {
        uint256 sellfee;
        uint256 sellfee_fixed;
        uint256 sellfee_percent;
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.sellfee", from)))) {
            sellfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed", from)));
            sellfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent", from)));
        }
        else {
            sellfee_fixed = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.fixed.default")));
            sellfee_percent = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.sellfee.percent.default")));
        }

        uint256 percent = val * sellfee_percent / 100 / 1 ether;
        if (percent > sellfee_fixed) {
            sellfee = percent;
        }
        else {
            sellfee = sellfee_fixed;
        }
        return sellfee;
    }

    /// @notice Calculate sell fee by admin
    /// @param addr Account address
    /// @param val toro sell amount
    /// @dev Client can use this function before the toro sell to get the potential sell fee
    function adminCalculateSellFee(address addr, uint256 val) public view returns (uint256) {
        return (_calculateSellFee(addr, val));
    }

    /// @notice Calculate sell result by admin
    /// @param addr Account address
    /// @param val toro amount to sell
    /// @return amount is the eth amount to obtain
    /// @return err is the error code; 0 - no error; 1 - insufficient sell amount
    /// @dev Client can use this function before the toro sell to estimate the eth amount to obtain
    function adminCalculateSellResult(address addr, uint256 val) public view returns (uint256 amount, uint256 err) {
        amount = 0;
        err = 0;

        uint256 crypto_amount = 1 ether * val / storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));

        uint256 sellfee = _calculateSellFee(addr, crypto_amount);
        if (sellfee > crypto_amount) {
            err = 1;
            return (amount, err);
        }

        amount = crypto_amount - sellfee;
        return (amount, err);
    }

    /// @notice Admin sell toro to the crypto with custom fee
    /// @param addr Account address
    /// @param value Amount of toro to spend
    /// @param sellfee Custom sell fee
    /// @dev note that during the sell, client's toro balance is moved to reserve, and crypto reserve send the crypto to client
    /// @dev note that the additional sell fee is charged in the crypto, not the toro
    function adminSellToroWithCustomFee(address addr, uint256 value, uint256 sellfee) public onlyAdmin onlyApprovedClient(addr) returns (bool) {
        require(addr != address(0), "[eth.admin] The account address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The account address cannot be a reserve");
        require(value > 0, "[eth.admin] The ammount to purchase cannot be zero");
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", addr))) >= value, "[eth.admin] Insufficient account toro balance");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid account address");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.sell"))), "[eth.admin] The toro sell is currently unavailable");
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The crypto account has been freezed");
            require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", addr))), "[eth.admin] The toro account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", addr))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", addr))), "[eth.admin] The ammount to send is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))), "[eth.admin] The ammount to send is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))), "[eth.admin] The ammount to send is too large");
            }
        }

        uint256 crypto_amount = 1 ether * value / storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));

        address toro_reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        address crypto_reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));

        require(sellfee < crypto_amount, "[eth.admin] Insufficient sell amount");

        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve))) >= crypto_amount, "[eth.admin] Insufficient crypto reserve balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve)), crypto_amount);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), crypto_amount - sellfee);

        if (sellfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(sellfee);
                require(comm <= sellfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), sellfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), sellfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), sellfee);
        }

        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", addr)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve)), value);

        emit AdminSellToroWithCustomFee(addr, value, crypto_amount, sellfee);
        return true;
    }

    /// @notice Calculate sell result by admin with custom sell fee
    /// @param val toro amount to sell
    /// @param sellfee custom sell fee
    /// @return amount is the eth amount to obtain
    /// @return err is the error code; 0 - no error; 1 - insufficient sell amount
    /// @dev Client can use this function before the toro sell to estimate the eth amount to obtain
    function adminCalculateSellResultWithCustomFee(uint256 val, uint256 sellfee) public view returns (uint256 amount, uint256 err) {
        amount = 0;
        err = 0;

        uint256 crypto_amount = 1 ether * val / storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));

        if (sellfee > crypto_amount) {
            err = 1;
            return (amount, err);
        }

        amount = crypto_amount - sellfee;
        return (amount, err);
    }

    /* ----------------------------------------- Admin Register/Remove ExtLinks ------------------------------------------ */

    /// @notice Admin register an external crypto address for a toro address
    /// @param toro Toronet address
    /// @param crypto External crypto address
    function adminAddExtLink(address toro, address crypto) public onlyAdmin onlyApprovedClient(toro) returns (bool) {
        require(toro != address(0), "[eth.admin] The toro address cannot be null");

        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", toro))), "[eth.admin] Invalid toro address");
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", toro))), "[eth.admin] The crypto account has been freezed");
        }

        require(crypto != address(0), "[eth.client] Invalid external crypto address to register");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto))), "[eth.client] The external crypto address has been already registered");

        uint256 currentIndex = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", toro)));

        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", toro, currentIndex)), crypto);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", toro, crypto)), currentIndex);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", toro)), 1);

        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", toro, crypto)), true);

        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.ext.linked", crypto)), toro);
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto)), true);

        emit AdminAddExtLink(toro, crypto);
        return true;
    }

    /// @notice Admin unregister an external crypto address for a toro address
    /// @param toro Toronet address
    /// @param crypto External crypto address
    function adminRemoveExtLink(address toro, address crypto) public onlyAdmin onlyApprovedClient(toro) returns (bool) {
        require(toro != address(0), "[eth.admin] The toro address cannot be null");

        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", toro))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", toro))), "[eth.admin] Invalid toro address");
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", toro))), "[eth.admin] The crypto account has been freezed");
        }

        require(crypto != address(0), "[eth.client] Invalid external crypto address to register");
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", toro, crypto))), "[eth.client] The external crypto address has not been registered");

        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", toro)));
        address lastAddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", toro, number - 1)));
        uint256 currIndex = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", toro, crypto)));

        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", toro, currIndex)), lastAddr);
        storageContract.deleteAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", toro, number - 1)));
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", toro, lastAddr)), currIndex);
        storageContract.deleteUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", toro, crypto)));

        storageContract.deleteBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", toro, crypto)));

        storageContract.deleteAddress(keccak256(abi.encodePacked("crypto.eth.ext.linked", crypto)));
        storageContract.deleteBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto)));

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", toro)), 1);

        emit AdminRemoveExtLink(toro, crypto);
        return true;
    }

    /// @notice Remove all existing admins
    /// @dev can only be called by a super admin, a debugger or the contract owner
    function adminRemoveAllExtLinks(address toro) public onlyAdmin onlyApprovedClient(toro) returns(bool) {

        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", toro)));
        if (number > 0) {
            for (uint256 i = number; i > 0; i--) {
                address crypto = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", toro, i - 1)));
                storageContract.deleteAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", toro, i - 1)));
                storageContract.deleteUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", toro, crypto)));

                storageContract.deleteBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", toro, crypto)));

                storageContract.deleteAddress(keccak256(abi.encodePacked("crypto.eth.ext.linked", crypto)));
                storageContract.deleteBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto)));
            }
        }
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", toro)), 0);

        emit AdminRemoveAllExtLinks(toro, number);
        return true;
    }

    /* ------------------------------------------ External Deposit / Withdraw -------------------------------------------- */

    /// @notice deposit external crypto in an account
    /// @param addr address to deposit
    /// @param value amount to deposit
    /// @param txid deposit transaction id
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function depositCrypto(address addr, uint256 value, bytes32 txid) public onlyDigitalAdmin onlyClient(addr) returns (bool) {
        require(txid != bytes32(0) || txid != bytes32(""), "[eth.admin] The transaction id cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.deposit", txid))), "[eth.admin] The transaction has been processed");

        require(addr != address(0), "[eth.admin] The import address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", addr))), "[eth.admin] The import address cannot be a reserve");
        require(value > 0, "[eth.admin] The import value cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", addr))), "[eth.admin] Invalid address to import crypto");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.import"))), "[eth.admin] The eth import is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",addr)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", addr)))) {
                    revert("[eth.admin] The import address has not been enrolled as an crypto account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", addr))), "[eth.admin] The import account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", addr))), "[eth.admin] The ammount to import is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", addr))), "[eth.admin] The ammount to import is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to import is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to import is too large");
            }
        }

        uint256 importfee = _calculateImportFee(addr, value);
        require(importfee < value, "[eth.admin] Insufficient import amount");
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", addr)), value - importfee);
        if (importfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(importfee);
                require(comm <= importfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), importfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), importfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), importfee);
        }

        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value);

        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.ext.deposit", txid)), true);

        emit DepositCrypto(addr, value, txid, importfee);
        return true;
    }

    /// @notice Withdraw crypto to external account
    /// @param toro_addr toronet address to withdraw
    /// @param eth_addr external eth address to deposit
    /// @param value amount to withdraw
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function adminWithdrawCrypto(address toro_addr, address eth_addr, uint256 value) public onlyAdmin onlyApprovedClient(toro_addr) returns (bool) {
        require(toro_addr != address(0), "[eth.admin] The export address cannot be null");
        require(eth_addr != address(0), "[eth.admin] The export deposit address cannot be null");
        require(!storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", toro_addr))), "[eth.admin] The export address cannot be a reserve");
        require(value > 0, "[eth.admin] The export value cannot be zero");
        if (!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender)))) {
            require(!storageContract.getBool(keccak256(abi.encodePacked("role.isowner", toro_addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", toro_addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", toro_addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", toro_addr))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", toro_addr))), "[eth.admin] Invalid address to import crypto");
            require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.export"))), "[eth.admin] The eth export is currently unavailable");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
                storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",toro_addr)), true);
            }
            else {
                if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", toro_addr)))) {
                    revert("[eth.admin] The export address has not been enrolled as an crypto account");
                }
            }
            require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", toro_addr))), "[eth.admin] The export account has been freezed");
            if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", toro_addr)))) {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", toro_addr))), "[eth.admin] The ammount to export is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", toro_addr))), "[eth.admin] The ammount to export is too large");
            }
            else {
                require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.admin] The ammount to export is too small");
                require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.admin] The ammount to export is too large");
            }
        }
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", toro_addr))) >= value, "[eth.admin] Export value is too large");

        uint256 exportfee = _calculateExportFee(toro_addr, value);
        require(exportfee < value, "[eth.admin] Insufficient export amount");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalcap"))) >= value - exportfee, "[eth.admin] Export value is too large");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toro_addr)), value);
        if (exportfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(exportfee);
                require(comm <= exportfee, "[eth.admin] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), exportfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), exportfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), exportfee);
        }

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value - exportfee);

        emit AdminWithdrawCrypto(toro_addr, eth_addr, value, exportfee);
        return true;
    }

    /// @notice Confirm the completion of the withdraw
    /// @param id withdraw id
    /// @dev Eth_bridge will use this to avoid double withdraw
    function confirmWithdraw(bytes32 id) public onlyDigitalAdmin returns (bool) {
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.withdraw", id))), "[eth.admin] Withdraw has been confirmed");
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.ext.withdraw", id)), true);
        emit ConfirmWithdraw(id);
        return true;
    }
}