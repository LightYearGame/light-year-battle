// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

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

interface IReferral {
    function setReferral(address who_, address byWhom_) external;
}

contract Battle is IBattle {

    address public registryAddress;
    IReferral public referral;

    event BattleResult(uint8 win, bytes battleBytes);

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

    function _battleConfig() private view returns (IBattleConfig){
        return IBattleConfig(registry().battleConfig());
    }

    function _shipAttrConfig() private view returns (IShipAttrConfig){
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
    function battleByFleet(
        address attacker_,
        address defender_,
        IFleets.Fleet memory attackerFleet_,
        IFleets.Fleet memory defenderFleet_
    ) public view returns (bytes memory) {
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
                result = _addBytes(result, attackerShips_[i].health);
            } else {
                result = _addBytes(result, 0);
            }
        }

        //defender health
        for (uint i = 0; i < fleetsConfig().getFleetShipLimit(); i++) {
            if (i < defenderLen) {
                result = _addBytes(result, defenderShips_[i].health);
            } else {
                result = _addBytes(result, 0);
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

        IShipAttrConfig shipAttrConfig = _shipAttrConfig();

        for (uint i = 0; i < shipIdArray.length; i++) {
            uint256[] memory attrs = shipAttrConfig.getAttributesByInfo(user_, ship().shipInfo(shipIdArray[i]));
            ships[i].shipType = uint8(attrs[2]);
            ships[i].health = uint32(attrs[4]);
            ships[i].attack = uint32(attrs[5]);
            ships[i].defense = uint32(attrs[6]);
        }

        return ships;
    }

    function _fleetBattleExplore(uint256 index_, uint256 level_, bool auto_) private returns (uint8){

        //check fleet status
        require(fleets().userFleet(msg.sender, index_).status == 0, "The fleet is on a mission.");

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
        explore().handleExploreResult(msg.sender, index_, win, level_, battleBytes, auto_);

        return win;
    }

    function fleetAutoExplore(uint256 index_, uint32 level_, uint256 days_) external {
        uint8 win = _fleetBattleExplore(index_, level_, true);
        if (win == 1) {
            //burn energy
            ICommodityERC20(registry().tokenEnergy()).transferFrom(msg.sender, address(this), days_ * 10 * 1e18);
            ICommodityERC20(registry().tokenEnergy()).burn(days_ * 10 * 1e18);

            fleets().fleetAutoExplore(msg.sender, index_, level_, now, now + days_ * (1 days));        
        }
    }

    function fleetAutoExploreWithReferral(uint256 index_, uint32 level_, uint256 days_, address byWhom_) external {
        uint8 win = _fleetBattleExplore(index_, level_, true);
        if (win == 1) {
            //burn energy
            ICommodityERC20(registry().tokenEnergy()).transferFrom(msg.sender, address(this), days_ * 10 * 1e18);
            ICommodityERC20(registry().tokenEnergy()).burn(days_ * 10 * 1e18);

            fleets().fleetAutoExplore(msg.sender, index_, level_, now, now + days_ * (1 days));
        }

        referral.setReferral(msg.sender, byWhom_);
    }

    function endAutoExplore(uint256 index_) external {
        explore().claimAutoExplore(msg.sender, index_);
        fleets().endAutoExplore(msg.sender, index_);
    }

    function fleetBattleExplore(uint256 index_, uint256 level_) external {
        _fleetBattleExplore(index_, level_, false);
    }

    function fleetBattleExploreWithReferral(uint256 index_, uint256 level_, address byWhom_) external {
        _fleetBattleExplore(index_, level_, false);
        referral.setReferral(msg.sender, byWhom_);
    }

    function getFleetBattleInfo(uint256 index_, uint256 level_) external view returns (bytes memory) {

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

        return _getBattleInfo(attacker, defender);
    }

    function _getRealDamage(IBattle.BattleShip memory attacker_, IBattle.BattleShip memory defender_) private pure returns (uint32) {
        uint32 attack = attacker_.attack;
        uint32 defense = defender_.defense;
        return (attack * attack) / (attack + defense);
    }

    function _battleByBattleShip(BattleShip[] memory attackerShips_, BattleShip[] memory defenderShips_) private pure returns (bytes memory) {

        //empty attacker
        if (attackerShips_.length == 0) {
            attackerShips_ = _basicBattleShip();
        }

        //empty defender
        if (defenderShips_.length == 0) {
            defenderShips_ = _basicBattleShip();
        }

        //battle info bytes array
        bytes memory battleInfoBytes = new bytes(1 + 20 * 6);

        uint32 attackerHealth = 0;
        uint32 defenderHealth = 0;

        // IBattleConfig battleConfig = _battleConfig();

        //battle range
        for (uint i = 0; i < 20; i++) {
            bytes memory roundBytes;

            uint8 fromIndex;
            uint8 toIndex;
            uint8 attributeIndex;
            uint32 delta;

            if (i % 2 == 0) {
                //from index and to index
                fromIndex = uint8(_getFirstShipIndex(attackerShips_));
                toIndex = uint8(_getFirstShipIndex(defenderShips_));

                //attribute index
                attributeIndex = 6;

                // Cause damage
                delta = _getRealDamage(attackerShips_[fromIndex], defenderShips_[toIndex]);

                if (defenderShips_[toIndex].health < delta) {
                    defenderShips_[toIndex].health = 0;
                } else {
                    defenderShips_[toIndex].health -= delta;
                }

                //battle info to bytes
                roundBytes = _battleInfoToBytes(0, fromIndex, toIndex, attributeIndex, delta);
            } else {
                //from index and to index
                fromIndex = uint8(_getFirstShipIndex(defenderShips_));
                toIndex = uint8(_getFirstShipIndex(attackerShips_));

                //attribute index
                attributeIndex = 6;

                // Cause damage
                delta = _getRealDamage(defenderShips_[fromIndex], attackerShips_[toIndex]);

                if (attackerShips_[toIndex].health < delta) {
                    attackerShips_[toIndex].health = 0;
                } else {
                    attackerShips_[toIndex].health -= delta;
                }

                //battle info to bytes
                roundBytes = _battleInfoToBytes(1, fromIndex, toIndex, attributeIndex, delta);
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

    function _toBattleShipArray(address user_, IShip.Info[] memory array) private view returns (BattleShip[] memory){
        BattleShip[] memory ships = new BattleShip[](array.length);

        IShipAttrConfig shipAttrConfig = _shipAttrConfig();

        for (uint i = 0; i < ships.length; i++) {
            uint256[] memory attrs = shipAttrConfig.getAttributesByInfo(user_, array[i]);
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

    function _addBytes(bytes memory b, uint32 i) public pure returns (bytes memory){
        return _mergeBytes(b, abi.encodePacked(i));
    }

    function _mergeBytes(bytes memory a, bytes memory b) public pure returns (bytes memory c) {
        return abi.encodePacked(a, b);
    }
}
