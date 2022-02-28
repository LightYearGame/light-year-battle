// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IShip.sol";

interface IShipAttrConfig {
    function getAttributesById(uint256 shipId_) external view returns (uint256[] memory);
    function getAttributesByInfo(address, IShip.Info memory info_) external view returns (uint256[] memory);
    function getShipCategory(uint8 shipType_) external pure returns (uint256);
    function getBattleAttribute(uint256 level_, uint256 quality_, uint256 shipType_) external pure returns(uint256[3] memory);
}