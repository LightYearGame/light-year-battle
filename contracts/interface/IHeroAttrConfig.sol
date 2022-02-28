// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IHero.sol";

interface IHeroAttrConfig {
    function getAttributesById(uint256 HeroId_) external view returns (uint8[] memory);
    function getAttributesByInfo(IHero.Info memory info_) external view returns (uint8[] memory);
}