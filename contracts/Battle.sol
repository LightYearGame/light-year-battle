// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./utils/BytesUtils.sol";
import "./interface/IBattle.sol";
import "./interface/IAccount.sol";
import "./interface/IExplore.sol";
import "./interface/IExploreConfig.sol";
import "./interface/IRegistry.sol";
import "./interface/IFleets.sol";
import "./interface/IFleetsConfig.sol";
import "./interface/IBattleConfig.sol";
import "./interface/IShipAttrConfig.sol";
import "./interface/ICommodityERC20.sol";

contract Battle is IBattle {

    using BytesUtils for BytesUtils;

    address public registryAddress;

    event BattleResult(uint8 win, bytes battleBytes);

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function fleets() private view returns (IFleets){
        return IFleets(registry().fleets());
    }

    function fleetsConfig() private view returns (IFleetsConfig){
        return IFleetsConfig(registry().fleetsConfig());
    }

    function account() private view returns (IAccount){
        return IAccount(registry().account());
    }

    function ship() private view returns (IShip){
        return IShip(registry().ship());
    }

    function explore() private view returns (IExplore){
        return IExplore(registry().explore());
    }

    function exploreConfig() private view returns (IExploreConfig){
        return IExploreConfig(registry().exploreConfig());
    }

    function battleConfig() private view returns (IBattleConfig){
        return IBattleConfig(registry().battleConfig());
    }

    function shipAttrConfig() private view returns (IShipAttrConfig){
        return IShipAttrConfig(registry().shipAttrConfig());
    }

    /**
     * battle
     */
    function battle(uint256 fleetIndex_) external {

        //require fleet status
        IFleets.Fleet memory attackerFleet = fleets().userFleet(msg.sender, fleetIndex_);
        require(attackerFleet.status == 3, "battle: The fleet has not prepared for battle.");
        require(now >= attackerFleet.missionEndTime, "battle: The fleet has not arrived yet.");

        //check defender fleet
        address targetAddress = account().getUserAddress(attackerFleet.target);
        IFleets.Fleet memory defenderFleet = fleets().getGuardFleet(targetAddress);

        //battle
        bytes memory battleBytes = battleByFleet(msg.sender, targetAddress, attackerFleet, defenderFleet);
        account().saveBattleHistory(msg.sender, battleBytes);

        //handle battle result
        uint8 win = uint8(battleBytes[0]);

        //event
        emit BattleResult(win, battleBytes);
    }

    /**
     * battle by fleet 
     */
    function battleByFleet(address attacker_, address defender_, IFleets.Fleet memory attackerFleet_, IFleets.Fleet memory defenderFleet_) public view returns (bytes memory){
        //ship length
        uint256 attackerLen = attackerFleet_.shipIdArray.length;
        uint256 defenderLen = defenderFleet_.shipIdArray.length;

        //check length
        require(attackerLen > 0, "_battle: Attacker has no ship.");

        //attacker ships
        IShip.Info[] memory attackerShips = new IShip.Info[](attackerLen);
        for (uint i = 0; i < attackerLen; i++) {
            attackerShips[i] = ship().shipInfo(attackerFleet_.shipIdArray[i]);
        }

        //defender ships
        IShip.Info[] memory defenderShips = new IShip.Info[](defenderLen);
        for (uint i = 0; i < defenderLen; i++) {
            defenderShips[i] = ship().shipInfo(defenderFleet_.shipIdArray[i]);
        }

        //to battle ship array
        BattleShip[] memory attacker = _toBattleShipArray(attacker_, attackerShips);
        BattleShip[] memory defender = _toBattleShipArray(defender_, defenderShips);
        return _battleByBattleShip(attacker, defender);
    }

    function _getBattleInfo(BattleShip[] memory attackerShips_, BattleShip[] memory defenderShips_) private view returns (bytes memory) {
        //ship length
        uint256 attackerLen = attackerShips_.length;
        uint256 defenderLen = defenderShips_.length;

        //empty attacker
        if (attackerLen == 0) {
            attackerShips_ = _basicBattleShip();
        }

        //empty defender
        if (defenderLen == 0) {
            defenderShips_ = _basicBattleShip();
        }

        //bytes
        bytes memory result = "";

        //attack health
        for (uint i = 0; i < fleetsConfig().getFleetShipLimit(); i++) {
            if (i < attackerLen) {
                result = BytesUtils._addBytes(result, attackerShips_[i].health);
            } else {
                result = BytesUtils._addBytes(result, 0);
            }
        }

        //defender health
        for (uint i = 0; i < fleetsConfig().getFleetShipLimit(); i++) {
            if (i < defenderLen) {
                result = BytesUtils._addBytes(result, defenderShips_[i].health);
            } else {
                result = BytesUtils._addBytes(result, 0);
            }
        }

        //attacker defender ship type
        for (uint i = 0; i < fleetsConfig().getFleetShipLimit(); i++) {
            if (i < attackerLen) {
                result = abi.encodePacked(result, attackerShips_[i].shipType);
            } else {
                result = abi.encodePacked(result, uint8(0));
            }
        }
        for (uint i = 0; i < fleetsConfig().getFleetShipLimit(); i++) {
            if (i < defenderLen) {
                result = abi.encodePacked(result, defenderShips_[i].shipType);
            } else {
                result = abi.encodePacked(result, uint8(0));
            }
        }

        return result;
    }

    function _fleetToBattleShips(address user_, uint256 index_) private view returns (IBattle.BattleShip[] memory){
        uint32[] memory shipIdArray = fleets().userFleet(user_, index_).shipIdArray;
        IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](shipIdArray.length);
        for (uint i = 0; i < shipIdArray.length; i++) {
            uint256[] memory attrs = shipAttrConfig().getAttributesByInfo(user_, ship().shipInfo(shipIdArray[i]));
            ships[i].shipType = uint8(attrs[2]);
            ships[i].health = uint32(attrs[4]);
            ships[i].attack = uint32(attrs[5]);
            ships[i].defense = uint32(attrs[6]);
        }

        return ships;
    }

    function fleetBattleExplore(uint256 index_, uint256 level_) external {

        //check user explore time
        require(now >= account().userExploreTime(msg.sender, index_) + exploreConfig().exploreDuration(), "Explore not ready.");

        //get battle ship array from fleet
        IBattle.BattleShip[] memory attacker = _fleetToBattleShips(msg.sender, index_);

        //get pirate ships
        IBattle.BattleShip[] memory defender = exploreConfig().pirateBattleShips(level_);

        //battle
        bytes memory battleBytes = _battleByBattleShip(attacker, defender);
        uint8 win = uint8(battleBytes[0]);

        //handle explore result
        explore().handleExploreResult(msg.sender, index_, win, level_, battleBytes);
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
        IBattle.BattleShip[] memory attacker = _toBattleShipArray(msg.sender, attackerShips);

        //get pirate ships
        IBattle.BattleShip[] memory defender = exploreConfig().pirateBattleShips(level_);

        return _getBattleInfo(attacker,defender);
    }

    function _battleByBattleShip(BattleShip[] memory attackerShips_, BattleShip[] memory defenderShips_) private view returns (bytes memory){

        //empty attacker
        if (attackerShips_.length == 0) {
            attackerShips_ = _basicBattleShip();
        }

        //empty defender
        if (defenderShips_.length == 0) {
            defenderShips_ = _basicBattleShip();
        }
        
        //temp round
        uint256 round = 20;

        //battle info bytes array
        bytes memory battleInfoBytes = new bytes(1 + round * 6);

        uint32 attackerHealth = 0;
        uint32 defenderHealth = 0;

        //battle range
        for (uint i = 0; i < round; i++) {
            bytes memory roundBytes;

            //round bytes
            if (i % 2 == 0) {
                (roundBytes, defenderShips_) = _singleRound(0, attackerShips_, defenderShips_);
            } else {
                (roundBytes, attackerShips_) = _singleRound(1, defenderShips_, attackerShips_);
            }

            for (uint j = 0; j < roundBytes.length; ++j) {
                battleInfoBytes[1 + i * 6 + j] = roundBytes[j];
            }

            //round break
            attackerHealth = 0;
            for (uint j = 0; j < attackerShips_.length; j++) {
                attackerHealth += attackerShips_[j].health;
            }

            defenderHealth = 0;
            for (uint j = 0; j < defenderShips_.length; j++) {
                defenderHealth += defenderShips_[j].health;
            }

            if (attackerHealth == 0 || defenderHealth == 0) {
                break;
            }
        }

        //winner
        if (attackerHealth >= defenderHealth) {
            battleInfoBytes[0] = byte(uint8(1));
        }

        return battleInfoBytes;
    }

    /**
     *
     */
    function _singleRound(uint8 battleType_, BattleShip[] memory attacker_, BattleShip[] memory defender_) private view returns (bytes memory, BattleShip[] memory){

        //from index and to index
        uint8 fromIndex = uint8(_getFirstShipIndex(attacker_));
        uint8 toIndex = uint8(_getFirstShipIndex(defender_));

        //attribute index
        uint8 attributeIndex = 6;

        //attacker ship and defender ship
        BattleShip memory attackerShip = attacker_[fromIndex];
        BattleShip memory defenderShip = defender_[toIndex];

        //cause damage
        uint32 delta = battleConfig().getRealDamage(attackerShip, defenderShip);

        if (defenderShip.health < delta) {
            defenderShip.health = 0;
        } else {
            defenderShip.health -= delta;
        }

        //battle info to bytes
        return (_battleInfoToBytes(battleType_, fromIndex, toIndex, attributeIndex, delta), defender_);
    }

    function _toBattleShipArray(address user_, IShip.Info[] memory array) private view returns (BattleShip[] memory){
        BattleShip[] memory ships = new BattleShip[](array.length);
        for (uint i = 0; i < ships.length; i++) {
            uint256[] memory attrs = shipAttrConfig().getAttributesByInfo(user_, array[i]);
            ships[i].shipType = uint8(attrs[2]);
            ships[i].health = uint32(attrs[4]);
            ships[i].attack = uint32(attrs[5]);
            ships[i].defense = uint32(attrs[6]);
        }
        return ships;
    }

    function _basicBattleShip() private pure returns (BattleShip[] memory){
        BattleShip[] memory ships = new BattleShip[](1);
        ships[0] = BattleShip(10, 10, 10, 6);
        return ships;
    }

    function _getFirstShipIndex(BattleShip[] memory ships_) private pure returns (uint256){
        for (uint i = 0; i < ships_.length; i++) {
            if (ships_[i].health > 0) {
                return i;
            }
        }
        return 0;
    }

    /**
     *
     */
    function _battleInfoToBytes(
        uint8 battleType_,
        uint8 fromIndex_,
        uint8 toIndex_,
        uint8 attributeIndex_,
        uint32 delta_
    ) private pure returns (bytes memory){
        bytes1 direction = _toDirection(battleType_, fromIndex_, toIndex_);
        bytes memory b = new bytes(6);
        b[0] = byte(direction);
        b[1] = byte(attributeIndex_);
        b[2] = byte(uint8(delta_ / 16777216));
        b[3] = byte(uint8((delta_ / 65536) % 256));
        b[4] = byte(uint8((delta_ % 65536) / 256));
        b[5] = byte(uint8(delta_ % 256));
        return b;
    }

    /**
     *
     */
    function _toDirection(uint8 a, uint8 b, uint8 c) private pure returns (bytes1){
        require(a <= 3 && b <= 7 && c <= 7);
        bytes1 a_byte = abi.encodePacked(a)[0] << 6;
        bytes1 b_byte = abi.encodePacked(b)[0] << 3;
        bytes1 c_byte = abi.encodePacked(c)[0];
        bytes1 result = a_byte | b_byte | c_byte;
        return result;
    }
}
