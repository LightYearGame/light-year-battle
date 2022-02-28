// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IShipAttrConfig.sol";
import "../interface/IRegistry.sol";
import "../interface/IUpgradeable.sol";
import "../interface/IFleets.sol";

contract ShipAttrConfig is IShipAttrConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function ship() private view returns (IShip){
        return IShip(registry().ship());
    }

    function fleets() private view returns (IFleets){
        return IFleets(registry().fleets());
    }

    function research() public view returns (IUpgradeable) {
        return IUpgradeable(registry().research());
    }

    function ownerOf(uint256 shipId_) public view returns (address){
        address owner = ship().ownerOf(shipId_);
        if (owner == registry().fleets()) {
            return fleets().shipOwnerOf(shipId_);
        }
        return owner;
    }

    function getAttributesById(uint256 shipId_) public view override returns (uint256[] memory){
        IShip.Info memory info = ship().shipInfo(shipId_);
        address user = ownerOf(shipId_);
        return getAttributesByInfo(user, info);
    }

    function getAttributesByInfo(address user_, IShip.Info memory info_) public view override returns (uint256[] memory){
        uint16 level = info_.level;
        uint8 quality = info_.quality;
        uint8 shipType = info_.shipType;
        uint256 category = getShipCategory(shipType);
        // attributes
        uint256[3] memory battleAttrs = getBattleAttribute(level, quality, shipType);
        uint256 attack = battleAttrs[0];
        uint256 defense = battleAttrs[1];
        uint256 health = battleAttrs[2];

        if (user_ != 0x0000000000000000000000000000000000000000) {
            health *= (100 + research().levelMap(user_, 3) * 5) / 100;
            attack *= (100 + research().levelMap(user_, 3) * 5) / 100;
            defense *= (100 + research().levelMap(user_, 3) * 5) / 100;
        }

        uint256[] memory attrs = new uint256[](7);
        attrs[0] = level;
        attrs[1] = quality;
        attrs[2] = shipType;
        attrs[3] = category;
        // attributes
        attrs[4] = health;
        attrs[5] = attack;
        attrs[6] = defense;
        return attrs;
    }

    function getShipCategory(uint8 shipType_) public override pure returns (uint256){
        if (shipType_ == 6 || shipType_ == 8 || shipType_ == 12 || shipType_ == 15) {
            return 0;
        } else if (shipType_ == 1 || shipType_ == 5) {
            return 1;
        } else if (shipType_ == 4 || shipType_ == 11 || shipType_ == 14) {
            return 2;
        } else {
            return 3;
        }
    }

    function getBattleAttribute(uint256 level_, uint256 quality_, uint256 shipType_) public override pure returns (uint256[3] memory){
        require(level_ >= 1, "Invalid level.");
        uint256[3] memory arr;
        if (shipType_ == 6) {
            arr = [uint(100), uint(100), uint(100)];
        } else if (shipType_ == 8) {
            arr = [uint(160), uint(160), uint(160)];
        } else if (shipType_ == 12) {
            arr = [uint(220), uint(210), uint(210)];
        } else if (shipType_ == 15) {
            arr = [uint(300), uint(286), uint(286)];
        } else {
            require(false, "getBattleAttribute: Not implemented");
        }

        if (level_ == 2) {
            arr[0] = arr[0] * 120 / 100;
            arr[1] = arr[1] * 120 / 100;
            arr[2] = arr[2] * 120 / 100;
        } else if (level_ == 3) {
            arr[0] = arr[0] * 140 / 100;
            arr[1] = arr[1] * 140 / 100;
            arr[2] = arr[2] * 140 / 100;
        } else if (level_ == 4) {
            arr[0] = arr[0] * 160 / 100;
            arr[1] = arr[1] * 160 / 100;
            arr[2] = arr[2] * 160 / 100;
        } else if (level_ == 5) {
            arr[0] = arr[0] * 180 / 100;
            arr[1] = arr[1] * 180 / 100;
            arr[2] = arr[2] * 180 / 100;
        } else if (level_ == 6) {
            arr[0] = arr[0] * 200 / 100;
            arr[1] = arr[1] * 200 / 100;
            arr[2] = arr[2] * 200 / 100;
        } else if (level_ >= 7) {
            arr[0] = arr[0] * 220 / 100;
            arr[1] = arr[1] * 220 / 100;
            arr[2] = arr[2] * 220 / 100;
        }

        arr[0] = arr[0] * (1000 + quality_ * 5) / 1000;
        arr[1] = arr[1] * (1000 + quality_ * 5) / 1000;
        arr[2] = arr[2] * (1000 + quality_ * 5) / 1000;
        return arr;
    }
}
