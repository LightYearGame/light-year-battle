// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IUpgradeable {
    function levelMap(address who_, uint256 itemIndex_) external view returns(uint256);
    function upgrade(uint256 itemIndex_) external;
    function size() external view returns(uint256);
}
