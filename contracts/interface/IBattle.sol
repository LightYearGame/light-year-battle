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
        uint8 battleType;
        uint8 fromIndex;
        uint8 toIndex;
        uint8 attributeIndex;
        uint32 delta;
    }
}
