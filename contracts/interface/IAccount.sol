// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IAccount {

    function getTotalUsers() external view returns (uint256);

    function addUser(address) external;

    function getUserId(address) external view returns (uint256);

    function getUserAddress(uint256) external view returns (address);

    function userExploreLevel(address addr_) external view returns (uint256);

    function addExploreLevel(address addr_) external;

    function saveBattleHistory(address addr_, bytes memory history_) external;

    function setUserExploreTime(address addr_, uint256 fleetIndex_, uint256 time_) external;

    function userExploreTime(address addr_, uint256 fleetIndex_) external view returns (uint256);
}