// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IExplore {
    function handleExploreResult(address user_, uint256 index_, uint8 win_, uint256 level_, bytes memory battleBytes_) external;
}
