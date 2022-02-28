// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract AccountModel {

    //registry
    address public registryAddress;

    uint32 public totalUsers;

    mapping(uint256 => address) public userIdMap;

    mapping(address => uint256) public userAddressMap;

    mapping(address => uint256) public userExploreLevelMap;

    mapping(address => mapping(uint256 => uint256)) public userExploreTimeMap;

    mapping(address => bytes[]) public userBattleHistoryMap;
}