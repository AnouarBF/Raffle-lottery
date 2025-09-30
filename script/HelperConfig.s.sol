// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {DeploymentParameters} from "./DeployParam.s.sol";

error HelperConfig__InvalidChainID();

contract HelperConfig is DeploymentParameters, Script {
    NetworkConfig private activeNetwork;
    mapping(uint chainID => NetworkConfig) public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeedAdd;
        address vrfCoordinator;
        uint subscriptionID;
        uint32 callbackGasLimit;
        bytes32 keyhash;
    }

    constructor() {
        activeNetworkConfig[ETH_MAINNET_CHAIN_ID] = get_Mainnet_Config();
        activeNetworkConfig[ETH_SEPOLIA_CHAIN_ID] = get_Sepolia_Config();
        activeNetworkConfig[POLYGON_AMOY_CHAIN_ID] = get_PolygonAmoy_Config();
    }

    function get_networkConfig() public returns (NetworkConfig memory) {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            activeNetwork = get_Sepolia_Config();
        } else if (block.chainid == ETH_MAINNET_CHAIN_ID) {
            activeNetwork = get_Mainnet_Config();
        } else if (block.chainid == POLYGON_AMOY_CHAIN_ID) {
            activeNetwork = get_PolygonAmoy_Config();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            activeNetwork = get_Anvil_Config();
        } else {
            revert HelperConfig__InvalidChainID();
        }

        return activeNetwork;
    }

    // function getConfig() external pure {

    // }

    function get_Mainnet_Config() internal pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeedAdd: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
                vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
                subscriptionID: 0,
                callbackGasLimit: 500_000,
                keyhash: 0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b
            });
    }

    function get_Sepolia_Config() internal pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeedAdd: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                subscriptionID: 0,
                callbackGasLimit: 500_000,
                keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
            });
    }

    function get_PolygonAmoy_Config()
        internal
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                priceFeedAdd: 0xF0d50568e3A7e8259E16663972b11910F89BD8e7,
                vrfCoordinator: 0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2,
                subscriptionID: 0,
                callbackGasLimit: 500_000,
                keyhash: 0x816bedba8a50b294e5cbd47842baf240c2385f2eaf719edbd4f250a137a8c899
            });
    }

    function get_Anvil_Config() internal returns (NetworkConfig memory) {
        if (activeNetwork.priceFeedAdd != address(0)) {
            return activeNetwork;
        }

        vm.startBroadcast(); /////////////////////////////////////////////////////////////////////////////////////////////
        VRFCoordinatorV2_5Mock mock_VRFCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );

        MockV3Aggregator mock_PriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_ANSWER
        );
        vm.stopBroadcast(); //////////////////////////////////////////////////////////////////////////////////////////////

        return
            NetworkConfig({
                priceFeedAdd: address(mock_PriceFeed),
                vrfCoordinator: address(mock_VRFCoordinator),
                subscriptionID: 0,
                callbackGasLimit: 500_000,
                keyhash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
            });
    }
}
