// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

interface IFleets {

    //fleet status
    //0-Home, 1-Guard, 2-Market, 3-GoBattle, 4-AutoExplore

    //struct Fleet
    struct Fleet {
        uint32[] shipIdArray;
        uint32[] heroIdArray;
        uint32 missionStartTime;
        uint32 missionEndTime;
        uint32 target;
        uint8 status;
    }

    function userFleet(address, uint256) external view returns (Fleet memory);
    function userFleets(address) external view returns (Fleet[] memory);
    function getGuardFleet(address addr_) external view returns (Fleet memory);
    function createFleet() external returns(uint256);
    function shipOwnerOf(uint256) external view returns(address);
    function fleetAutoExplore(address user_, uint256 fleetIndex_, uint32 level_, uint256 days_, uint256 ends_) external;
    function endAutoExplore(address user_, uint256 fleetIndex_) external;
}
