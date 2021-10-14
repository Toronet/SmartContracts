// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import "./storage_abstract.sol";

/// @title Toronet Token Client Contract
/// @author Wenhai Li
/// @notice These are the client only functions to use the crypto token
/// @dev 06/24/2021
contract EthCryptoClient {

    /* --------------------------------------------------- Variables --------------------------------------------------- */

    /// @notice Storage contract address
    address public storageContractAddress;

    /// @notice Storage contract reference
    ToronetStorage storageContract;

    /* ---------------------------------------------------- Modifiers ---------------------------------------------------- */

    /// @notice Only allow calls from crypto enrolled account
    modifier onlyEnrolled {
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
            storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", msg.sender)), true);
        }
        else {
            if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", msg.sender)))) {
                revert("[eth.client] The address has not been enrolled as a crypto account");
            }
        }
        _;
    }

    /* ----------------------------------------------------- Events ------------------------------------------------------ */

    /// @notice Event to deploy contract
    /// @param addr contract address
    event Deploy(address indexed addr);

    /// @notice Event to transfer crypto
    /// @param from sender address
    /// @param to receiver address
    /// @param value transfer amount
    /// @param fee transfer fee
    event Transfer(address indexed from, address indexed to, uint256 value, uint256 fee);

    /// @notice Event to buy toro with the crypto
    /// @param addr account address
    /// @param crypto amount of crypto to spend
    /// @param toro amount of toro obtained
    /// @param fee purchase fee [eth]
    event BuyToro(address indexed addr, uint256 crypto, uint256 toro, uint256 fee);

    /// @notice Event to sell toro to the crypto
    /// @param addr account address
    /// @param toro amount of toro to spend
    /// @param crypto amount of crypto obtained
    /// @param fee sell fee [eth]
    event SellToro(address indexed addr, uint256 toro, uint256 crypto, uint256 fee);

    /// @notice Event to register an external crypto address
    /// @param toro toronet address
    /// @param crypto external crypto address
    event AddExtLink(address indexed toro, address indexed crypto);

    /// @notice Event to unregister an external crypto address
    /// @param toro toronet address
    /// @param crypto external crypto address
    event RemoveExtLink(address indexed toro, address indexed crypto);

    /// @notice Event to withdraw crypto to external account by admin
    /// @param toro_addr toronet address to export
    /// @param eth_addr external eth address to deposit
    /// @param value export amount
    /// @param fee export fee
    event WithdrawCrypto(address toro_addr, address eth_addr,  uint256 value, uint256 fee);

    /* --------------------------------------------------- Constructor --------------------------------------------------- */

    /// @notice Contract constructor
    /// @param storageAddress The address of the deployed storage contract
    constructor(address storageAddress) {
        storageContractAddress = storageAddress;
        storageContract = ToronetStorage(storageAddress);
        require(storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))), "[eth.client] Contract creator must be the storage owner");
        storageContract.setAddress(keccak256(abi.encodePacked("storage.contract.eth.client")), address(this));
        storageContract.setBool(keccak256(abi.encodePacked("storage.contract", storageContract.getUint8(keccak256(abi.encodePacked("storage.version"))), address(this))), true);
        emit Deploy(address(this));
    }

    /* --------------------------------------------- Client Transfer Function -------------------------------------------- */

    /// @notice Client crypto transfer
    /// @param to Receiver address
    /// @param value Transfer amount
    /// @dev note that only check allowance for sender, no allowance check for receiver
    function transfer(address to, uint256 value) public onlyEnrolled returns (bool) {
        require(msg.sender != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[eth.client] Invalid address to send crypto");
        require(to != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", to))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", to))), "[eth.client] Invalid address to receive crypto");
        require(msg.sender != to, "[eth.client] An address cannot send crypto to itself");
        require(value > 0, "[eth.client] The ammount to send cannot be zero");
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.transfer"))), "[eth.client] The eth transfer is currently unavailable");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", msg.sender))), "[eth.client] The sender account has been freezed");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", to))), "[eth.client] The receiver account has been freezed");
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", msg.sender)))) {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", msg.sender))), "[eth.client] The ammount to send is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", msg.sender))), "[eth.client] The ammount to send is too large");
        }
        else {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.client] The ammount to send is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.client] The ammount to send is too large");
        }
        uint256 txfee = _calculateTxFee(msg.sender, value);
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", msg.sender))) >= value + txfee, "[eth.client] Insufficient sender account balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", msg.sender)), value + txfee);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", to)), value);

        if (txfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(txfee);
                require(comm <= txfee, "[eth.client] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), txfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), txfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), txfee);
        }

        emit Transfer(msg.sender, to, value, txfee);
        return true;
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

    /// @notice Calculate transfer fee
    /// @param val Transfer amount
    /// @dev Client can use this function before the transaction to get the potential transaction fee
    function calculateTxFee(uint256 val) public view returns (uint256) {
        return (_calculateTxFee(msg.sender, val));
    }

    /* --------------------------------------------- Client Toro Buy Function -------------------------------------------- */

    /// @notice Client buy toro with the crypto
    /// @param value Amount of crypto to spend
    /// @dev note that buy fee is charged in crypto contract, not in toro contract
    /// @dev note that during the purchase, client's crypto balance is moved to reserve, and toro reserve send the toro to client
    /// @dev note that the additional sell fee is charged in the crypto, not the toro
    function buyToro(uint256 value) public onlyEnrolled returns (bool) {
        require(msg.sender != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[eth.client] Invalid address to send crypto");
        require(value > 0, "[eth.client] The ammount to purchase cannot be zero");
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.buy"))), "[eth.client] The toro purchase is currently unavailable");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", msg.sender))) >= value, "[eth.client] Insufficient account crypto balance");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", msg.sender))), "[eth.client] The crypto account has been freezed");
        require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", msg.sender))), "[eth.client] The toro account has been freezed");
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", msg.sender)))) {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", msg.sender))), "[eth.client] The ammount to send is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", msg.sender))), "[eth.client] The ammount to send is too large");
        }
        else {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.client] The ammount to send is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.client] The ammount to send is too large");
        }

        uint256 buyfee = _calculateBuyFee(msg.sender, value);
        require(buyfee < value, "[eth.client] Insufficient purchase amount");

        uint256 toro_amount = (value - buyfee) * storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate"))) / 1 ether;

        address toro_reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        address crypto_reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));

        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve))) >= toro_amount, "[eth.client] Insufficient toro reserve balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", msg.sender)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve)), value - buyfee);

        if (buyfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(buyfee);
                require(comm <= buyfee, "[eth.client] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), buyfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), buyfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), buyfee);
        }

        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", msg.sender)), toro_amount);
        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve)), toro_amount);

        emit BuyToro(msg.sender, value, toro_amount, buyfee);

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
    /// @param val Amount to buy with the crypto
    /// @dev Client can use this function before the crypto buy to get the potential buy fee
    function calculateBuyFee(uint256 val) public view returns (uint256) {
        return (_calculateBuyFee(msg.sender, val));
    }

    /// @notice Calculate buy result
    /// @param val Amount to buy with the crypto
    /// @return amount is the toro amount to obtain
    /// @return err is the error code; 0 - no error; 1 - insufficient purchase amount
    /// @dev Client can use this function before the toro buy to estimate the toro amount to obtain
    function calculateBuyResult(uint256 val) public view returns (uint256 amount, uint256 err) {
        amount = 0;
        err = 0;

        uint256 buyfee = _calculateBuyFee(msg.sender, val);
        if (buyfee > val) {
            err = 1;
            return (amount, err);
        }

        amount = (val - buyfee) * storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate"))) / 1 ether;
        return (amount, err);
    }

    /* --------------------------------------------- Client Toro Sell Function -------------------------------------------- */

    /// @notice Client sell toro to the crypto
    /// @param value Amount of toro to spend
    /// @dev note that buy fee is charged in crypto contract, not in toro contract
    /// @dev note that during the sell, client's toro balance is moved to reserve, and crypto reserve send the crypto to client
    /// @dev note that the additional sell fee is charged in the crypto, not the toro
    function sellToro(uint256 value) public onlyEnrolled returns (bool) {
        require(msg.sender != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[eth.client] Invalid address to send crypto");
        require(value > 0, "[eth.client] The ammount to sell cannot be zero");
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.sell"))), "[eth.client] The toro sell is currently unavailable");
        require(storageContract.getUint256(keccak256(abi.encodePacked("token.toro.balance", msg.sender))) >= value, "[eth.client] Insufficient account toro balance");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", msg.sender))), "[eth.client] The crypto account has been freezed");
        require(!storageContract.getBool(keccak256(abi.encodePacked("token.toro.isfrozen", msg.sender))), "[eth.client] The toro account has been freezed");
        if (storageContract.getBool(keccak256(abi.encodePacked("token.toro.allowself.allowance", msg.sender)))) {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum", msg.sender))), "[eth.client] The ammount to send is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum", msg.sender))), "[eth.client] The ammount to send is too large");
        }
        else {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.minimum.default"))), "[eth.client] The ammount to send is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("token.toro.allowance.maximum.default"))), "[eth.client] The ammount to send is too large");
        }

        uint256 crypto_amount = 1 ether * value / storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));

        address toro_reserve = storageContract.getAddress(keccak256(abi.encodePacked("token.toro.reserve")));
        address crypto_reserve = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.reserve")));

        uint256 sellfee = _calculateSellFee(msg.sender, crypto_amount);
        require(sellfee < crypto_amount, "[eth.client] Insufficient sell amount");

        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve))) >= crypto_amount, "[eth.client] Insufficient crypto reserve balance");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", crypto_reserve)), crypto_amount);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", msg.sender)), crypto_amount - sellfee);

        if (sellfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(sellfee);
                require(comm <= sellfee, "[eth.client] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), sellfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), sellfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), sellfee);
        }

        storageContract.decreaseUint256(keccak256(abi.encodePacked("token.toro.balance", msg.sender)), value);
        storageContract.increaseUint256(keccak256(abi.encodePacked("token.toro.balance", toro_reserve)), value);

        emit SellToro(msg.sender, value, crypto_amount, sellfee);
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

    /// @notice Calculate sell fee
    /// @param val toro sell amount
    /// @dev Client can use this function before the toro sell to get the potential sell fee
    function calculateSellFee(uint256 val) public view returns (uint256) {
        return (_calculateSellFee(msg.sender, val));
    }

    /// @notice Calculate sell result
    /// @param val toro amount to sell
    /// @return amount is the eth amount to obtain
    /// @return err is the error code; 0 - no error; 1 - insufficient sell amount
    /// @dev Client can use this function before the toro sell to estimate the eth amount to obtain
    function calculateSellResult(uint256 val) public view returns (uint256 amount, uint256 err) {
        amount = 0;
        err = 0;

        uint256 crypto_amount = 1 ether * val / storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.exchangerate")));

        uint256 sellfee = _calculateSellFee(msg.sender, crypto_amount);
        if (sellfee > crypto_amount) {
            err = 1;
            return (amount, err);
        }

        amount = crypto_amount - sellfee;
        return (amount, err);
    }

    /* ----------------------------------------- Client Register/Remove ExtLinks ----------------------------------------- */

    /// @notice Client register an external crypto address
    /// @param crypto External crypto address
    function addExtLink(address crypto) public onlyEnrolled returns (bool) {
        require(msg.sender != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[eth.client] Invalid address to send crypto");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", msg.sender))), "[eth.client] The crypto account has been freezed");
        require(crypto != address(0), "[eth.client] Invalid external crypto address to register");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto))), "[eth.client] The external crypto address has been already registered");

        uint256 currentIndex = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", msg.sender)));

        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", msg.sender, currentIndex)), crypto);
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", msg.sender, crypto)), currentIndex);
        storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", msg.sender)), 1);

        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", msg.sender, crypto)), true);

        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.ext.linked", crypto)), msg.sender);
        storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto)), true);

        emit AddExtLink(msg.sender, crypto);
        return true;
    }

    /// @notice Client unregister an external crypto address
    /// @param crypto External crypto address
    function removeExtLink(address crypto) public onlyEnrolled returns (bool) {
        require(msg.sender != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[eth.client] Invalid address to send crypto");
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", msg.sender))), "[eth.client] The crypto account has been freezed");
        require(crypto != address(0), "[eth.client] Invalid external crypto address to register");
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", msg.sender, crypto))), "[eth.client] The external crypto address has not been registered");

        uint256 number = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", msg.sender)));
        address lastAddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", msg.sender, number - 1)));
        uint256 currIndex = storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", msg.sender, crypto)));

        storageContract.setAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", msg.sender, currIndex)), lastAddr);
        storageContract.deleteAddress(keccak256(abi.encodePacked("crypto.eth.ext.link.list", msg.sender, number - 1)));
        storageContract.setUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", msg.sender, lastAddr)), currIndex);
        storageContract.deleteUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.index", msg.sender, crypto)));

        storageContract.deleteBool(keccak256(abi.encodePacked("crypto.eth.ext.haslink", msg.sender, crypto)));

        storageContract.deleteAddress(keccak256(abi.encodePacked("crypto.eth.ext.linked", crypto)));
        storageContract.deleteBool(keccak256(abi.encodePacked("crypto.eth.ext.islinked", crypto)));

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.ext.link.number", msg.sender)), 1);

        emit RemoveExtLink(msg.sender, crypto);
        return true;
    }

    /* ------------------------------------------------ Client Withdrawal ------------------------------------------------ */

    /// @notice Calculate import fee
    /// @param val Transfer amount
    /// @dev Client can use this function before the crypto import to get the potential import fee
    function calculateImportFee(uint256 val) public view returns (uint256) {
        return (_calculateImportFee(msg.sender, val));
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

    /// @notice Calculate export fee
    /// @param val Transfer amount
    /// @dev Client can use this function before the crypto export to get the potential export fee
    function calculateExportFee(uint256 val) public view returns (uint256) {
        return (_calculateExportFee(msg.sender, val));
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

    /// @notice Withdraw crypto to external account
    /// @param eth_addr external eth address to deposit
    /// @param value amount to withdraw
    /// @dev When owner/debugger/superadmin call the function, there will be no checks on client address, crypto enrollment, transfer allowance, account frozen
    function withdrawCrypto(address eth_addr, uint256 value)public onlyEnrolled returns (bool) {
        require(msg.sender != address(0) && !storageContract.getBool(keccak256(abi.encodePacked("role.isreserve", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isowner", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdebugger", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.issuperadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isadmin", msg.sender))) && !storageContract.getBool(keccak256(abi.encodePacked("role.isdigitaladmin", msg.sender))), "[eth.client] Invalid address to send crypto");
        require(eth_addr != address(0), "[eth.client] The export deposit address cannot be null");
        require(value > 0, "[eth.client] The export value cannot be zero");
        require(storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.on.export"))), "[eth.client] The eth export is currently unavailable");
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.enroll")))) {
            storageContract.setBool(keccak256(abi.encodePacked("crypto.eth.isenrolled",msg.sender)), true);
        }
        else {
            if (!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isenrolled", msg.sender)))) {
                revert("[eth.client] The export address has not been enrolled as an crypto account");
            }
        }
        require(!storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.isfrozen", msg.sender))), "[eth.client] The export account has been freezed");
        if (storageContract.getBool(keccak256(abi.encodePacked("crypto.eth.allowself.allowance", msg.sender)))) {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum", msg.sender))), "[eth.client] The ammount to export is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum", msg.sender))), "[eth.client] The ammount to export is too large");
        }
        else {
            require(value >= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.minimum.default"))), "[eth.client] The ammount to export is too small");
            require(value <= storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.allowance.maximum.default"))), "[eth.client] The ammount to export is too large");
        }
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.balance", msg.sender))) >= value, "[eth.client] Export value is too large");

        uint256 exportfee = _calculateExportFee(msg.sender, value);
        require(exportfee < value, "[eth.client] Insufficient export amount");
        require(storageContract.getUint256(keccak256(abi.encodePacked("crypto.eth.totalcap"))) >= value - exportfee, "[eth.client] Export value is too large");

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", msg.sender)), value);
        if (exportfee > 0) {
            address toller = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.toller")));
            address commaddr = storageContract.getAddress(keccak256(abi.encodePacked("crypto.eth.commission.address")));
            if (commaddr != toller) {
                uint256 comm = _calculateComm(exportfee);
                require(comm <= exportfee, "[eth.client] Invalid transaction commission value");
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", commaddr)), comm);
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), exportfee - comm);
            }
            else {
                storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.balance", toller)), exportfee);
            }
            storageContract.increaseUint256(keccak256(abi.encodePacked("crypto.eth.totalfee")), exportfee);
        }

        storageContract.decreaseUint256(keccak256(abi.encodePacked("crypto.eth.totalcap")), value - exportfee);

        emit WithdrawCrypto(msg.sender, eth_addr, value, exportfee);
        return true;
    }

}