// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IRegistry {

    // base and research
    function base() external view returns (address);
    function research() external view returns (address);

    // fleets and ships
    function account() external view returns (address);
    function fleets() external view returns (address);
    function explore() external view returns (address);
    function battle() external view returns (address);
    function ship() external view returns (address);
    function hero() external view returns (address);

    // staking and burning
    function staking() external view returns (address);
    function burning() external view returns (address);
    function uniswapV2Router() external view returns (address);
    function stableToken() external view returns (address);
    function treasury() external view returns (address);

    // fleets config and ships config
    function shipConfig() external view returns (address);
    function heroConfig() external view returns (address);
    function fleetsConfig() external view returns (address);
    function exploreConfig() external view returns (address);
    function battleConfig() external view returns (address);
    function shipAttrConfig() external view returns (address);
    function heroAttrConfig() external view returns (address);

    // base config and research config
    function baseConfig() external view returns (address);
    function researchConfig() external view returns (address);
    function miningConfig() external view returns (address);
    function claimConfig() external view returns (address);

    // tokens
    function tokenIron() external view returns (address);
    function tokenGold() external view returns (address);
    function tokenEnergy() external view returns (address);
    function tokenSilicate() external view returns (address);
    function tokenLightCoin() external view returns (address);

    // access
    function canMintCommodity(address) external view returns (bool);
}
