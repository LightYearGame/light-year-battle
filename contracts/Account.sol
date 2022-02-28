// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./model/AccountModel.sol";
import "./interface/IAccount.sol";
import "./interface/IRegistry.sol";

contract Account is AccountModel, IAccount {

    function getTotalUsers() public override view returns (uint256){
        return totalUsers;
    }

    function getUserId(address addr_) external override view returns (uint256) {
        return userAddressMap[addr_];
    }

    function getUserAddress(uint256 userId_) external override view returns (address){
        return userIdMap[userId_];
    }

    function userExploreLevel(address addr_) external override view returns (uint256){
        return userExploreLevelMap[addr_];
    }

    function userExploreTime(address addr_, uint256 fleetIndex_) external override view returns (uint256){
        return userExploreTimeMap[addr_][fleetIndex_];
    }

    function addUser(address addr_) public override {
        require(msg.sender==IRegistry(registryAddress).fleets(), "require fleets");
        require(userAddressMap[addr_] == 0, "addUser: user already exists.");
        uint32 userId = totalUsers + 1;
        userIdMap[userId] = addr_;
        userAddressMap[addr_] = userId;
        totalUsers++;
    }

    function addExploreLevel(address addr_) external override {
        require(msg.sender==IRegistry(registryAddress).explore(), "require explore");
        userExploreLevelMap[addr_]++;
    }

    function saveBattleHistory(address addr_, bytes memory history_) external override {
        require(msg.sender==IRegistry(registryAddress).battle(), "require battle");
        userBattleHistoryMap[addr_].push(history_);
    }

    function setUserExploreTime(address addr_, uint256 fleetIndex_, uint256 time_) external override {
        require(msg.sender==IRegistry(registryAddress).explore(), "require explore");
        userExploreTimeMap[addr_][fleetIndex_] = time_;
    }
}