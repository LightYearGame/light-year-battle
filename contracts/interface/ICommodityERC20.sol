// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICommodityERC20 is IERC20 {
    function mintByInternalContracts(address who_, uint256 amount_) external;
    function burn(uint256 amount_) external;
}
