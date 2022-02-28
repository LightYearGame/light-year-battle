// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IRegistry.sol";
import "../interface/IBattleConfig.sol";

contract BattleConfig is IBattleConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function getRealDamage(IBattle.BattleShip memory attacker_, IBattle.BattleShip memory defender_) external override pure returns (uint32){
        uint32 attack = attacker_.attack;
        uint32 defense = defender_.defense;
//        uint256 attackerWeapon = getWeaponType(attacker_);
//        uint256 defenderWeapon = getWeaponType(defender_);
//        if ((attackerWeapon == 3 && defenderWeapon == 2) || (attackerWeapon == 2 && defenderWeapon == 1)) {
//            attack = attack * 120 / 100;
//        }
        return (attack * attack) / (attack + defense);
    }

    function getWeaponType(IBattle.BattleShip memory ship_) public pure returns (uint256){
        if (ship_.shipType == 2 || ship_.shipType == 9 || ship_.shipType == 16) {
            return 1;
        } else if (ship_.shipType == 3 || ship_.shipType == 10 || ship_.shipType == 17) {
            return 2;
        } else if (ship_.shipType == 7 || ship_.shipType == 13 || ship_.shipType == 18) {
            return 3;
        }
        return 0;
    }
}
