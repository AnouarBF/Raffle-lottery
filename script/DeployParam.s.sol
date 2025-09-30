// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract DeploymentParameters {
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;

    address public constant FOUNDRY_DEFAULT_SENDER =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant POLYGON_AMOY_CHAIN_ID = 80002;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ANSWER = 4000e8;
}
