// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./interface/IRegistry.sol";
import "./interface/IFleets.sol";
import "./interface/IAccount.sol";
import "./interface/IBattle.sol";
import "./interface/IShip.sol";
import "./interface/IExploreConfig.sol";
import "./interface/ICommodityERC20.sol";

contract Explore {

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

    function battle() private view returns (IBattle){
        return IBattle(registry().battle());
    }

    function ship() private view returns (IShip){
        return IShip(registry().ship());
    }

    function exploreConfig() private view returns (IExploreConfig){
        return IExploreConfig(registry().exploreConfig());
    }

    function _handleExploreResult(uint256 index_, uint8 win_, uint256 userMaxLevel_, uint256 level_, bytes memory battleBytes_) private {

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

        //win and get real drop
        uint32[] memory heroIdArray = fleets().userFleet(msg.sender, index_).heroIdArray;
        uint256[] memory winResource = exploreConfig().getRealDropByLevel(level_, heroIdArray);
        _exploreDrop(winResource);
        emit ExploreResult(1, winResource, userMaxLevel_, battleBytes_);
    }

    function getFleetBattleInfo(uint256 index_, uint256 level_) external view returns(bytes memory) {

        //get ship info array from fleet
        IFleets.Fleet memory fleet = fleets().userFleet(msg.sender, index_);
        uint256 attackerLen = fleet.shipIdArray.length;
        IShip.Info[] memory attackerShips = new IShip.Info[](attackerLen);
        for (uint i = 0; i < attackerLen; i++) {
            attackerShips[i] = ship().shipInfo(fleet.shipIdArray[i]);
        }

        //to battle ships
        IBattle.BattleShip[] memory attacker = battle().toBattleShipArray(msg.sender, attackerShips);

        //get pirate ships
        IBattle.BattleShip[] memory defender = exploreConfig().pirateBattleShips(level_);

        return battle().getBattleInfo(attacker,defender);
    }

    function fleetBattleExplore(uint256 index_, uint256 level_) public {

        //check user explore time
        require(now >= account().userExploreTime(msg.sender, index_) + exploreConfig().exploreDuration(), "Explore not ready.");

        //get ship info array from fleet
        IFleets.Fleet memory fleet = fleets().userFleet(msg.sender, index_);
        uint256 attackerLen = fleet.shipIdArray.length;
        IShip.Info[] memory attackerShips = new IShip.Info[](attackerLen);
        for (uint i = 0; i < attackerLen; i++) {
            attackerShips[i] = ship().shipInfo(fleet.shipIdArray[i]);
        }

        //to battle ships
        IBattle.BattleShip[] memory attacker = battle().toBattleShipArray(msg.sender, attackerShips);

        //get pirate ships
        IBattle.BattleShip[] memory defender = exploreConfig().pirateBattleShips(level_);

        //battle
        bytes memory battleBytes = battle().battleByBattleShip(attacker, defender);
        uint8 win = uint8(battleBytes[0]);

        //handle explore result
        uint256 userMaxLevel = account().userExploreLevel(msg.sender);
        _handleExploreResult(index_, win, userMaxLevel, level_, battleBytes);

        //user explore time
        if (win == 1) {
            account().setUserExploreTime(msg.sender, index_, now);
        }
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
