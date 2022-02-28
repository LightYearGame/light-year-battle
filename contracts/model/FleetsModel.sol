// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./../interface/IFleets.sol";

contract FleetsModel {

    //user fleets map
    mapping(address => IFleets.Fleet[]) public userFleetsMap;

    //ship owner map
    mapping(uint256 => address) public shipOwnerMap;

    //hero owner map
    mapping(uint256 => address) public heroOwnerMap;

    //registry
    address public registryAddress;
}