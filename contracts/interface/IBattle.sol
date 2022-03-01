// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IShip.sol";

interface IBattle {

    struct BattleShip {
        uint32 health;
        uint32 attack;
        uint32 defense;
        uint8 shipType;
    }

    struct BattleInfo {
        bytes1 direction;
        uint8 battleType;
        uint8 fromIndex;
        uint8 toIndex;
        uint8 attributeIndex;
        uint32 delta;
    }

    function fleetToBattleShips(address user_, uint256 index_) external view returns(IBattle.BattleShip[] memory);
    function toBattleShipArray(address, IShip.Info[] memory array) external view returns (BattleShip[] memory);
    function battleByBattleShip(BattleShip[] memory attackerShips_, BattleShip[] memory defenderShips_) external view returns (bytes memory);
    function getBattleInfo(BattleShip[] memory attackerShips_, BattleShip[] memory defenderShips_) external view returns (bytes memory);
}