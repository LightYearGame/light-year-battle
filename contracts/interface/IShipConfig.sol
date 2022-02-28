// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IShipConfig {
    function getBuildTokenArray(uint8 shipType_) external view returns (address[] memory);
    function getBuildShipCostByLevel(uint8 shipType_, uint8 level_) external pure returns (uint256[] memory);
}
