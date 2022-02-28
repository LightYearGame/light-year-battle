// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

interface IHero {

    struct Info {
        uint8 level;
        uint8 quality;
        uint8 heroType;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function heroInfo(uint256 shipId_) external view returns (Info memory);
    function upgradeHero(uint256 heroFromTokenId_, uint256 heroToTokenId_) external;
    function convertHero(uint256 heroTokenId_) external;
}
