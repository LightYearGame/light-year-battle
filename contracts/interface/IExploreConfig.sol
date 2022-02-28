// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IShip.sol";
import "./IBattle.sol";

interface IExploreConfig {
    function getMayDropByLevel(uint256 level_) external pure returns (uint256[] memory);
    function getRealDropByLevel(uint256 level_, uint32[] memory heroIdArray) external view returns (uint256[] memory);
    function pirateBattleShips(uint256 level_) external view returns (IBattle.BattleShip[] memory);
    function exploreDuration() external pure returns(uint256);
}