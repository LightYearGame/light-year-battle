// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IBattle.sol";

interface IBattleConfig {
    function getRealDamage(IBattle.BattleShip memory, IBattle.BattleShip memory) external pure returns (uint32);
}