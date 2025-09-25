// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/RaffleLottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    HelperConfig helperConfig;

    function run() external returns (Raffle, HelperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .get_networkConfig();

        vm.startBroadcast(); /////////////////////////////////////////
        Raffle raffle = new Raffle(
            config._entranceFee_usd,
            config._interval,
            config.priceFeedAdd,
            config.vrfCoordinator,
            config.subscriptionID,
            config.callbackGasLimit,
            config.keyhash
        );
        vm.stopBroadcast(); /////////////////////////////////////////
        return (raffle, helperConfig);
    }
}
