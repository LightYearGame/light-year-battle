// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./../model/FleetsModel.sol";

contract FleetsProxy is FleetsModel, Ownable {

    address public fleets;

    function setFleets(address fleets_) public onlyOwner {
        fleets = fleets_;
    }

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    fallback() external {
        address _impl = fleets;
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }
}
