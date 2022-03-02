// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./interface/IRegistry.sol";
import "./interface/IFleets.sol";
import "./interface/IAccount.sol";
import "./interface/IExplore.sol";
import "./interface/IExploreConfig.sol";
import "./interface/ICommodityERC20.sol";

contract Explore is IExplore {

    address public registryAddress;

    event ExploreResult(uint256 win, uint256[] resource, uint256 level, bytes battleBytes);

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function fleets() private view returns (IFleets){
        return IFleets(registry().fleets());
    }

    function account() private view returns (IAccount){
        return IAccount(registry().account());
    }

    function exploreConfig() private view returns (IExploreConfig){
        return IExploreConfig(registry().exploreConfig());
    }

    function handleExploreResult(uint256 index_, uint8 win_, uint256 userMaxLevel_, uint256 level_, bytes memory battleBytes_) external override {
        require(msg.sender == registry().battle(), "Only battle can call");

        //explore lose
        if (win_ == 0) {
            emit ExploreResult(0, new uint256[](0), 0, battleBytes_);
            return;
        }

        //add user explore level
        if (userMaxLevel_ == level_) {
            account().addExploreLevel(msg.sender);
            userMaxLevel_++;
        }

        // win and get real drop
        uint32[] memory heroIdArray = fleets().userFleet(msg.sender, index_).heroIdArray;
        uint256[] memory winResource = exploreConfig().getRealDropByLevel(level_, heroIdArray);
        _exploreDrop(winResource);
        emit ExploreResult(1, winResource, userMaxLevel_, battleBytes_);
    }

    function _exploreDrop(uint256[] memory winResource_) private {
        if (winResource_[0] > 0) {
            ICommodityERC20(registry().tokenIron()).mintByInternalContracts(msg.sender, winResource_[0]);
        }

        if (winResource_[1] > 0) {
            ICommodityERC20(registry().tokenGold()).mintByInternalContracts(msg.sender, winResource_[1]);
        }

        if (winResource_[2] > 0) {
            ICommodityERC20(registry().tokenSilicate()).mintByInternalContracts(msg.sender, winResource_[2]);
        }

        if (winResource_[3] > 0) {
            ICommodityERC20(registry().tokenEnergy()).mintByInternalContracts(msg.sender, winResource_[3]);
        }
    }
}
