// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./model/FleetsModel.sol";
import "./interface/IFleets.sol";
import "./interface/IFleetsConfig.sol";
import "./interface/IRegistry.sol";
import "./interface/IShip.sol";
import "./interface/IAccount.sol";
import "./interface/IHero.sol";
import "./interface/ICommodityERC20.sol";
import "./interface/IShipConfig.sol";

contract Fleets is FleetsModel, IFleets, IERC721Receiver {

    event UserFleetsInformation(address addr_);

    modifier checkIndex(address addr_, uint256 index_){
        require(index_ < userFleetsMap[addr_].length, "userFleet: The index is out of bounds.");
        _;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
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

    function hero() private view returns (IHero){
        return IHero(registry().hero());
    }

    function shipConfig() private view returns (IShipConfig){
        return IShipConfig(registry().shipConfig());
    }

    function shipOwnerOf(uint256 shipId_) external view override returns (address){
        return shipOwnerMap[shipId_];
    }

    function userFleet(address addr_, uint256 index_) external view override returns (Fleet memory){
        Fleet[] memory fleetArray = userFleetsMap[addr_];
        require(index_ < fleetArray.length, "userFleet: The index is out of bounds.");
        return userFleetsMap[addr_][index_];
    }

    function userFleets(address addr_) external view override returns (Fleet[] memory){
        return userFleetsMap[addr_];
    }

    function _stakeShip(uint256 tokenId_) private {
        IShip(registry().ship()).safeTransferFrom(msg.sender, address(this), tokenId_);
        shipOwnerMap[tokenId_] = msg.sender;
    }

    function _withdrawShip(uint256 tokenId_) private {
        require(shipOwnerMap[tokenId_] == msg.sender, "_withdrawShip: is not owner.");
        IShip(registry().ship()).safeTransferFrom(address(this), msg.sender, tokenId_);
        delete shipOwnerMap[tokenId_];
    }

    function _stakeHero(uint256 tokenId_) private {
        IHero(registry().hero()).safeTransferFrom(msg.sender, address(this), tokenId_);
        heroOwnerMap[tokenId_] = msg.sender;
    }

    function _withdrawHero(uint256 tokenId_) private {
        require(heroOwnerMap[tokenId_] == msg.sender, "_withdrawHero: is not owner.");
        IHero(registry().hero()).safeTransferFrom(address(this), msg.sender, tokenId_);
        delete heroOwnerMap[tokenId_];
    }

    function _contains0(uint32[] memory arr_, uint32 v_) private pure returns (bool){
        for (uint i = 0; i < arr_.length; i++) {
            if (arr_[i] == v_) {
                return true;
            }
        }

        return false;
    }

    function _contains1(uint32[] storage arr_, uint32 v_) private view returns (bool){
        for (uint i = 0; i < arr_.length; i++) {
            if (arr_[i] == v_) {
                return true;
            }
        }

        return false;
    }

    function _fleetFormationShip(uint256 fleetIndex_, uint32[] memory shipIdArray_) private {
        Fleet[] storage fleetArray = userFleetsMap[msg.sender];
        uint32[] storage nowArray = fleetArray[fleetIndex_].shipIdArray;

        //remove
        for (uint256 i = 0; i < nowArray.length; i++) {
            uint32 shipId = nowArray[i];

            if (shipId == 0) {
                continue;
            }

            if (!_contains0(shipIdArray_, shipId)) {
                _withdrawShip(shipId);
            }
        }

        //attach
        for (uint256 i = 0; i < shipIdArray_.length; i++) {
            uint32 shipId = shipIdArray_[i];
            if (shipId == 0) {
                continue;
            }

            if (!_contains1(nowArray, shipId)) {
                //stake
                _stakeShip(shipId);
            }
        }

        fleetArray[fleetIndex_].shipIdArray = shipIdArray_;
    }

    function _fleetFormationHero(uint256 fleetIndex_, uint32[] memory heroIdArray_) private {
        Fleet[] storage fleetArray = userFleetsMap[msg.sender];
        uint32[] storage nowArray = fleetArray[fleetIndex_].heroIdArray;

        //remove
        for (uint256 i = 0; i < nowArray.length; i++) {
            uint32 heroId = nowArray[i];

            if (heroId == 0) {
                continue;
            }

            if (!_contains0(heroIdArray_, heroId)) {
                _withdrawHero(heroId);
            }
        }

        //remove hero from other fleets or attach to nowArray.
        for (uint256 i = 0; i < heroIdArray_.length; i++) {
            uint32 heroId = heroIdArray_[i];

            if (heroId == 0) {
                continue;
            }

            (uint256 heroFleetIndex, uint256 heroPositionIndex) = getHeroPosition(heroId);

            if (heroFleetIndex == 0) {
                // If not in any fleets.
                _stakeHero(heroId);
            } else {
                if (heroFleetIndex - 1 != fleetIndex_) {
                    // If in other fleets.
                    userFleetsMap[msg.sender][heroFleetIndex - 1].heroIdArray[heroPositionIndex] = 0;
                }
            }
        }

        fleetArray[fleetIndex_].heroIdArray = heroIdArray_;
    }

    function fleetFormationCreateShipHero(uint32[] memory shipIdArray_, uint32[] memory heroIdArray_) external {
        //create fleet
        uint256 fleetIndex = createFleet();

        //add user
        if (fleetIndex == 0) {
            account().addUser(msg.sender);
        }

        //fleet formation
        fleetFormationShipHero(fleetIndex, shipIdArray_, heroIdArray_);
    }

    function fleetFormationShipHero(uint256 fleetIndex_, uint32[] memory shipIdArray_, uint32[] memory heroIdArray_) public {
        require(_checkFleetStatus(msg.sender, fleetIndex_, 0), "fleetFormationShipHero: The fleet is on a mission.");
        require(shipIdArray_.length == heroIdArray_.length, "fleetFormationShipHero: Invalid length");
        require(fleetsConfig().checkFleetFormationConfig(shipIdArray_), "fleetFormationShipHero: check config failed.");

        _fleetFormationShip(fleetIndex_, shipIdArray_);
        _fleetFormationHero(fleetIndex_, heroIdArray_);

        //event user fleets information
        emit UserFleetsInformation(msg.sender);
    }

    function fleetShipInfo(address user_, uint256 index_) public view returns (IShip.Info[] memory) {
        require(index_ < userFleetsMap[user_].length, "index out of bounds");
        Fleet storage fleet = userFleetsMap[user_][index_];

        uint256 length = fleet.shipIdArray.length;
        IShip.Info[] memory ships = new IShip.Info[](length);
        for (uint i = 0; i < length; i++) {
            uint256 shipId = fleet.shipIdArray[i];
            ships[i] = ship().shipInfo(shipId);
        }

        return ships;
    }

    function _checkFleetStatus(address addr_, uint256 fleetIndex_, uint8 status_) private view returns (bool){
        require(fleetIndex_ < userFleetsMap[addr_].length, "index out of bounds");
        Fleet storage fleet = userFleetsMap[addr_][fleetIndex_];

        return fleet.status == status_;
    }

    function _changeFleetStatus(
        address addr_,
        uint256 fleetIndex_,
        uint8 status_,
        uint32 target_,
        uint256 start_,
        uint256 end_
    ) private {
        Fleet storage fleet = userFleetsMap[addr_][fleetIndex_];
        fleet.status = status_;
        fleet.target = target_;
        fleet.missionStartTime = uint32(start_);
        fleet.missionEndTime = uint32(end_);
    }

    function createFleet() public override returns(uint256) {
        uint256 userFleetLength = userFleetsMap[msg.sender].length;
        uint256 userFleetLimit = fleetsConfig().getUserFleetLimit(msg.sender);
        require(userFleetLimit > userFleetLength, "createFleet: exceeds user fleet limit.");
        userFleetsMap[msg.sender].push(_emptyFleet());
        return userFleetLength;
    }

    function _emptyFleet() private pure returns (Fleet memory){
        return Fleet(new uint32[](0), new uint32[](0), 0, 0, 0, 0);
    }

    function getGuardFleet(address addr_) public view override returns (Fleet memory){
        Fleet[] storage fleets = userFleetsMap[addr_];
        for (uint i = 0; i < fleets.length; i++) {
            Fleet storage fleet = fleets[i];
            if (fleet.status == 1) {
                return fleet;
            }
        }
        return _emptyFleet();
    }

    function goHome(uint256 index_) public {
        uint256 duration = fleetsConfig().getGoHomeDuration(msg.sender, index_);
        _changeFleetStatus(msg.sender, index_, 0, 0, uint32(block.timestamp), uint32(block.timestamp + duration));
    }

    function goMarket(uint256 index_) public {
        uint256 duration = fleetsConfig().getGoMarketDuration(msg.sender, index_);
        _changeFleetStatus(msg.sender, index_, 2, 0, uint32(block.timestamp), uint32(block.timestamp + duration));
    }

    function goBattleByUserId(uint32 userId_, uint256 fleetIndex_) public {
        uint32 myUserId = uint32(account().getUserId(msg.sender));
        require(myUserId > 0, "myUserId be positive");
        require(userId_ > 0, "userId be positive");
        require(myUserId != userId_, "Not yourself");

        // TODO: re-add Distance back.
        uint256 second = 1e18; // Distance.getTransportTime(myUserId, userId_);
        _changeFleetStatus(msg.sender, fleetIndex_, 3, userId_, block.timestamp, block.timestamp + second);
    }

    function quickFly(uint256 index_) public {
        (address tokenAddress,uint256 cost) = fleetsConfig().getQuickFlyCost();
        ICommodityERC20(tokenAddress).transferFrom(msg.sender, address(this), cost);
        ICommodityERC20(tokenAddress).burn(cost);
        Fleet storage fleet = userFleetsMap[msg.sender][index_];
        fleet.missionEndTime = fleet.missionStartTime;
    }

    function goHomeInstant(uint256 index_) external {
        goHome(index_);
        quickFly(index_);
    }

    function goMarketInstant(uint256 index_) external {
        goMarket(index_);
        quickFly(index_);
    }

    function goBattleInstant(uint32 userId_, uint256 index_) external {
        goBattleByUserId(userId_, index_);
        quickFly(index_);
    }

    function guardHome(uint256 fleetIndex_) external {
        require(_checkFleetStatus(msg.sender, fleetIndex_, 0), "guardHome: The fleet is on a mission.");
        _changeFleetStatus(msg.sender, fleetIndex_, 1, 0, block.timestamp, block.timestamp);
    }

    function cancelGuardHome(uint256 fleetIndex_) external {
        require(_checkFleetStatus(msg.sender, fleetIndex_, 1), "cancelGuardHome: The fleet is not guarding.");
        _changeFleetStatus(msg.sender, fleetIndex_, 0, 0, block.timestamp, block.timestamp);
    }

    function fleetAutoExplore(address user_, uint256 fleetIndex_, uint32 level_, uint256 start_, uint256 end_) external override {
        require(msg.sender == registry().battle(), "fleetAutoExplore: require battle contract.");
        require(_checkFleetStatus(user_, fleetIndex_, 0), "fleetAutoExplore: The fleet is on a mission.");
        _changeFleetStatus(user_, fleetIndex_, 4, level_, start_, end_);
    }

    function endAutoExplore(address user_, uint256 fleetIndex_) external override {
        require(msg.sender == registry().battle(), "endAutoExplore: require battle contract.");
        require(_checkFleetStatus(user_, fleetIndex_, 4), "endAutoExplore: The fleet is on a mission.");
        _changeFleetStatus(user_, fleetIndex_, 0, 0, block.timestamp, block.timestamp);
    }

    function getHeroPosition(uint256 heroId_) public view returns (uint256, uint256) {
        Fleet[] storage fleets = userFleetsMap[msg.sender];
        for (uint256 i = 0; i < fleets.length; i++) {
            for (uint256 j = 0; j < fleets[i].heroIdArray.length; j++) {
                if (fleets[i].heroIdArray[j] == heroId_) {
                    return (i + 1, j);
                }
            }
        }
        return (0, 0);
    }

    function getFleetsHeroArray() external view returns (uint256[] memory){
        Fleet[] storage fleets = userFleetsMap[msg.sender];
        uint256[] memory heroArray = new uint256[](fleets.length * 4);
        uint256 index = 0;
        for (uint i = 0; i < fleets.length; i++) {
            for (uint j = 0; j < fleets[i].heroIdArray.length; j++) {
                heroArray[index] = fleets[i].heroIdArray[j];
                index++;
            }
        }
        return heroArray;
    }

    function getIdleShipsAndFleets() external view returns (uint256[] memory, Fleet[] memory){
        uint256[] memory idleShips = new uint256[](ship().balanceOf(msg.sender));
        for (uint i = 0; i < idleShips.length; i++) {
            uint256 shipId = ship().tokenOfOwnerByIndex(msg.sender, i);
            idleShips[i] = shipId;
        }
        return (idleShips, userFleetsMap[msg.sender]);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function upgradeHero(uint256 heroFromTokenId_, uint256 heroToTokenId_) external {
        require(heroOwnerMap[heroToTokenId_] == msg.sender, "upgradeHero: is not owner.");
        hero().safeTransferFrom(msg.sender, address(this), heroFromTokenId_);
        hero().upgradeHero(heroFromTokenId_, heroToTokenId_);
    }

    function convertHero(uint256 heroTokenId_) external {
        require(heroOwnerMap[heroTokenId_] == msg.sender, "convertHero: is not owner.");
        hero().convertHero(heroTokenId_);
    }

    function upgradeShip(uint256 shipFromTokenId_, uint256 shipToTokenId_) external {
        require(shipOwnerMap[shipToTokenId_] == msg.sender, "upgradeShip: is not owner.");
        ship().safeTransferFrom(msg.sender, address(this), shipFromTokenId_);
        ship().upgradeShip(shipFromTokenId_, shipToTokenId_);
    }

    function recycleShip(uint256 shipId_) external {
        ship().safeTransferFrom(msg.sender, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, shipId_);
        IShip.Info memory info = ship().shipInfo(shipId_);
        address[] memory addrs = shipConfig().getBuildTokenArray(info.shipType);
        uint256[] memory res = shipConfig().getBuildShipCostByLevel(info.shipType, info.level);
        require(addrs.length == res.length, "require valid cost array.");
        for (uint i = 0; i < res.length; i++) {
            ICommodityERC20(addrs[i]).mintByInternalContracts(msg.sender, res[i] / 2);
        }
    }
}