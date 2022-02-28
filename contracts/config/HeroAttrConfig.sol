// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IHeroAttrConfig.sol";
import "../interface/IRegistry.sol";
import "../interface/IHero.sol";

contract HeroAttrConfig is IHeroAttrConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function hero() private view returns (IHero){
        return IHero(registry().hero());
    }

    function getAttributesById(uint256 HeroId_) public view override returns (uint8[] memory){
        IHero.Info memory info = hero().heroInfo(HeroId_);
        return getAttributesByInfo(info);
    }

    function getAttributesByInfo(IHero.Info memory info_) public view override returns (uint8[] memory){
        uint8 level = info_.level;
        uint8 quality = info_.quality;
        uint8 heroType = info_.heroType;
        uint8 rarity = getHeroRarity(heroType);
        // attributes
        uint8 strength = rarity * 10;
        uint8 dexterity = rarity * 10;
        uint8 intelligence = rarity * 10;
        uint8 luck = rarity * 10;

        uint8[] memory attrs = new uint8[](8);
        attrs[0] = level;
        attrs[1] = quality;
        attrs[2] = heroType;
        attrs[3] = rarity;
        // attributes
        attrs[4] = strength;
        attrs[5] = dexterity;
        attrs[6] = intelligence;
        attrs[7] = luck;
        return attrs;
    }

    function getHeroRarity(uint8 heroType_) public pure returns (uint8){
        if (heroType_ < 12) {
            return 1;
        } else if (heroType_ < 24) {
            return 2;
        } else if (heroType_ < 36) {
            return 3;
        } else {
            return 4;
        }
    }
}