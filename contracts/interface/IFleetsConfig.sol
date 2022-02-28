// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IFleetsConfig {

    function getConfig(uint256 key) external returns (uint256[] memory);

    function getUserFleetLimit(address who_) external view returns (uint256);

    function getFleetShipLimit() external pure returns (uint256);

    function getGoHomeDuration(address addr_, uint256 index_) external pure returns (uint256);

    function getGoMarketDuration(address addr_, uint256 index_) external pure returns (uint256);

    function getFleetFormationConfig() external pure returns (uint256[] memory);

    function fleetTotalAttack(address addr_, uint256 index_) external view returns (uint256);

    function allFleetsAttack(address addr_) external view returns (uint256);

    function fleetsAttackArray(address addr_) external view returns (uint256[] memory);

    function checkFleetFormationConfig(uint32[] memory shipIdArray_) external view returns (bool);

    function getQuickFlyCost() external view returns (address, uint256);

}