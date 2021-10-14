// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;


/// @title Toronet Storage Contract Functio Signature
/// @author Wenhai Li
/// @notice This is the data storage functio signature for other toronet contracts to call
/// @dev 06/17/2021
abstract contract ToronetStorage {

    function getUint256(bytes32 key) external view virtual returns (uint256);

    function setUint256(bytes32 key, uint256 value) external virtual;

    function increaseUint256(bytes32 key, uint256 value) external virtual;

    function decreaseUint256(bytes32 key, uint256 value) external virtual;

    function deleteUint256(bytes32 key) external virtual;

    function getUint8(bytes32 key) external view virtual returns (uint8);

    function setUint8(bytes32 key, uint8 value) external virtual;

    function increaseUint8(bytes32 key, uint8 value) external virtual;

    function decreaseUint8(bytes32 key, uint8 value) external virtual;

    function deleteUint8(bytes32 key) external virtual;

    function getAddress(bytes32 key) external view virtual returns (address);

    function setAddress(bytes32 key, address value) external virtual;

    function deleteAddress(bytes32 key) external virtual;

    function getBool(bytes32 key) external view virtual returns (bool);

    function setBool(bytes32 key, bool value) external virtual;

    function deleteBool(bytes32 key) external virtual;

    function getBytes32(bytes32 key) external view virtual returns (bytes32);

    function setBytes32(bytes32 key, bytes32 value) external virtual;

    function deleteBytes32(bytes32 key) external virtual;

}