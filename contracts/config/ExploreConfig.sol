// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IExploreConfig.sol";
import "../interface/IRegistry.sol";
import "../interface/IHeroAttrConfig.sol";
import "../interface/IShipAttrConfig.sol";

contract ExploreConfig is IExploreConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function heroAttrConfig() private view returns (IHeroAttrConfig){
        return IHeroAttrConfig(registry().heroAttrConfig());
    }

    function shipAttrConfig() private view returns (IShipAttrConfig){
        return IShipAttrConfig(registry().shipAttrConfig());
    }

    function getMayDropByLevel(uint256 level_) public override pure returns (uint256[] memory){
        uint256[] memory mayDrop = new uint256[](4);
        if (level_ == 0) {
            mayDrop[0] = 8;
            mayDrop[1] = 0;
            mayDrop[2] = 0;
        } else if (level_ == 1) {
            mayDrop[0] = 15;
            mayDrop[1] = 3;
            mayDrop[2] = 0;
        } else if (level_ == 2) {
            mayDrop[0] = 27;
            mayDrop[1] = 4;
            mayDrop[2] = 3;
        } else if (level_ == 3) {
            mayDrop[0] = 33;
            mayDrop[1] = 6;
            mayDrop[2] = 6;
        } else if (level_ == 4) {
            mayDrop[0] = 36;
            mayDrop[1] = 8;
            mayDrop[2] = 7;
        } else if (level_ == 5) {
            mayDrop[0] = 45;
            mayDrop[1] = 10;
            mayDrop[2] = 9;
        } else if (level_ == 6) {
            mayDrop[0] = 60;
            mayDrop[1] = 15;
            mayDrop[2] = 12;
        } else if (level_ == 7) {
            mayDrop[0] = 67;
            mayDrop[1] = 18;
            mayDrop[2] = 15;
        } else if (level_ == 8) {
            mayDrop[0] = 75;
            mayDrop[1] = 23;
            mayDrop[2] = 22;
        } else if (level_ == 9) {
            mayDrop[0] = 80;
            mayDrop[1] = 30;
            mayDrop[2] = 30;
        }

        return mayDrop;
    }

    function getRealDropByLevel(uint256 level_, uint32[] memory heroIdArray_) public override view returns (uint256[] memory){
        uint256 boost = heroBoost(heroIdArray_);

        uint256[] memory mayDrop = getMayDropByLevel(level_);
        uint256[] memory realDrop = new uint256[](4);
        realDrop[0] = mayDrop[0] * 1e18 * boost / 100;
        realDrop[1] = mayDrop[1] * 1e18 * boost / 100;
        realDrop[2] = mayDrop[2] * 1e18 * boost / 100;
        realDrop[3] = mayDrop[3] * 1e18 * boost / 100;

        return realDrop;
    }

    function pirateBattleShips(uint256 level_) public override view returns (IBattle.BattleShip[] memory){
        require(level_ <= 9, "max level 9");

        if (level_ == 0) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](2);
            ships[0] = pirateShip(1, 6);
            ships[1] = pirateShip(1, 6);
            return ships;
        } else if (level_ == 1) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(1, 6);
            ships[1] = pirateShip(1, 6);
            ships[2] = pirateShip(1, 6);
            ships[3] = pirateShip(1, 6);
            return ships;
        } else if (level_ == 2) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(1, 6);
            ships[1] = pirateShip(1, 6);
            ships[2] = pirateShip(2, 6);
            ships[3] = pirateShip(2, 6);
            return ships;
        } else if (level_ == 3) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(2, 6);
            ships[1] = pirateShip(2, 6);
            ships[2] = pirateShip(1, 8);
            ships[3] = pirateShip(1, 8);
            return ships;
        } else if (level_ == 4) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(2, 8);
            ships[1] = pirateShip(2, 8);
            ships[2] = pirateShip(2, 8);
            ships[3] = pirateShip(2, 8);
            return ships;
        } else if (level_ == 5) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(2, 8);
            ships[1] = pirateShip(2, 8);
            ships[2] = pirateShip(1, 12);
            ships[3] = pirateShip(1, 12);
            return ships;
        } else if (level_ == 6) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(2, 8);
            ships[1] = pirateShip(2, 12);
            ships[2] = pirateShip(2, 12);
            ships[3] = pirateShip(2, 12);
            return ships;
        } else if (level_ == 7) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(2, 12);
            ships[1] = pirateShip(2, 12);
            ships[2] = pirateShip(2, 12);
            ships[3] = pirateShip(3, 12);
            return ships;
        } else if (level_ == 8) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(2, 12);
            ships[1] = pirateShip(2, 12);
            ships[2] = pirateShip(1, 15);
            ships[3] = pirateShip(2, 15);
            return ships;
        } else if (level_ == 9) {
            IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
            ships[0] = pirateShip(2, 15);
            ships[1] = pirateShip(2, 15);
            ships[2] = pirateShip(2, 15);
            ships[3] = pirateShip(3, 15);
            return ships;
        }
    }

    function pirateShip(uint256 level_, uint8 shipType_) private view returns (IBattle.BattleShip memory){
        uint256[3] memory attrs = shipAttrConfig().getBattleAttribute(level_, 50, shipType_);
        uint32 attack = uint32(attrs[0]);
        uint32 defense = uint32(attrs[1]);
        uint32 health = uint32(attrs[2]);
        IBattle.BattleShip memory ship = IBattle.BattleShip(attack, defense, health, shipType_);
        return ship;
    }

    function heroBoost(uint32[] memory heroIdArray_) public view returns (uint256){
        uint256 boost = 100;
        for (uint i = 0; i < heroIdArray_.length; i++) {
            uint256 heroId = heroIdArray_[i];
            if (heroId != 0) {
                uint8[] memory attrs = heroAttrConfig().getAttributesById(heroId);
                uint8 rarity = attrs[3];
                uint8 level = attrs[0];
                uint8 quality = attrs[1];
                boost += heroBoostByRarityLevel(rarity, level, quality);
            }
        }
        return boost;
    }

    function heroBoostByRarityLevel(uint8 rarity_, uint8 level_, uint8 quality_) public pure returns (uint256){
        require(rarity_ >= 1 && rarity_ <= 4, "Invalid rarity.");
        require(level_ >= 1, "Invalid level.");
        if(level_ >= 3) {
            level_ = 3;
        }

        uint256 result;
        if (rarity_ == 1) {
            result = [30, 40, 53][level_ - 1];
        } else if (rarity_ == 2) {
            result = [53, 68, 89][level_ - 1];
        } else if (rarity_ == 3) {
            result = [115, 150, 195][level_ - 1];
        } else {
            result = [195, 254, 330][level_ - 1];
        }

        return result * (quality_ + 50) / 100;
    }

    function exploreDuration() public override pure returns (uint256){
        return 12 hours;
    }
}
