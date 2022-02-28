// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library BytesUtils {

    /**
     *
     */
    function _addBytes(bytes memory b, uint32 i) public pure returns (bytes memory){
        return _mergeBytes(b, abi.encodePacked(i));
    }

    /**
     *
     */
    function _mergeBytes(bytes memory a, bytes memory b) public pure returns (bytes memory c) {
        return abi.encodePacked(a, b);
    }
}