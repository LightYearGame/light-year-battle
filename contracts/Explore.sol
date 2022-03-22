// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./interface/IRegistry.sol";
import "./interface/IFleets.sol";
import "./interface/IAccount.sol";
import "./interface/IExplore.sol";
import "./interface/IExploreConfig.sol";
import "./interface/ICommodityERC20.sol";

interface IReferral {
    function onReward(address who_, uint256[] calldata amountArray_) external;
}

contract Explore is IExplore {

    address public registryAddress;
    IReferral public referral;

    event ExploreResult(uint256 win, uint256[] resource, uint256 level, bytes battleBytes);

    constructor(address registry_, IReferral referral_) public {
        registryAddress = registry_;
        referral = referral_;
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

    function handleExploreResult(address user_, uint256 index_, uint8 win_, uint256 level_, bytes calldata battleBytes_, bool auto_) external override {
        require(msg.sender == registry().battle(), "Only battle can call");

        //explore lose
        if (win_ == 0) {
            emit ExploreResult(0, new uint256[](0), 0, battleBytes_);
            return;
        }

        uint256 userMaxLevel = account().userExploreLevel(user_);
        require(level_ <= userMaxLevel, "Wrong level");

        //add user explore level
        if (userMaxLevel == level_) {
            account().addExploreLevel(user_);
            userMaxLevel++;
        }

        // win and get real drop
        if (auto_) {
            emit ExploreResult(1, new uint256[](0), userMaxLevel, "");
        } else {
            uint32[] memory heroIdArray = fleets().userFleet(user_, index_).heroIdArray;
            uint256[] memory winResource = exploreConfig().getRealDropByLevel(level_, heroIdArray);
            _exploreDrop(user_, winResource);
            emit ExploreResult(1, winResource, userMaxLevel, battleBytes_);
        }

        //user explore time
        account().setUserExploreTime(user_, index_, now);
    }

    function claimAutoExplore(address user_, uint256 index_) external override {
        require(msg.sender == registry().battle(), "Only battle can call");

        //check end time
        IFleets.Fleet memory fleet = fleets().userFleet(user_, index_);
        require(now >= fleet.missionEndTime, "Mission undone.");

        uint256 day = (fleet.missionEndTime - fleet.missionStartTime) / 1 days;

        //burn energy
        ICommodityERC20(registry().tokenEnergy()).transferFrom(user_, address(this), day * 10 * 1e18);
        ICommodityERC20(registry().tokenEnergy()).burn(day * 10 * 1e18);

        //claim resource
        uint256[] memory winResource = exploreConfig().getRealDropByLevel(fleet.target, fleet.heroIdArray);
        for (uint i = 0; i < winResource.length; i++) {
            winResource[i] *= day * 2;
        }
        _exploreDrop(user_, winResource);
        emit ExploreResult(1, winResource, fleet.target, "");
    }

    function _exploreDrop(address user_, uint256[] memory winResource_) private {
        if (winResource_[0] > 0) {
            ICommodityERC20(registry().tokenIron()).mintByInternalContracts(user_, winResource_[0]);
        }

        if (winResource_[1] > 0) {
            ICommodityERC20(registry().tokenGold()).mintByInternalContracts(user_, winResource_[1]);
        }

        if (winResource_[2] > 0) {
            ICommodityERC20(registry().tokenSilicate()).mintByInternalContracts(user_, winResource_[2]);
        }

        if (winResource_[3] > 0) {
            ICommodityERC20(registry().tokenEnergy()).mintByInternalContracts(user_, winResource_[3]);
        }

        referral.onReward(user_, winResource_);
    }
}
