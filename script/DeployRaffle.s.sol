// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/RaffleLottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    HelperConfig helperConfig;

    function run(
        uint _entranceFee_usd,
        uint _interval
    ) external returns (Raffle, HelperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .get_networkConfig();

        if (config.subscriptionID == 0) {
            // Creating Subscription
            CreateSubscription createSub = new CreateSubscription();
            (
                config.subscriptionID,
                config.vrfCoordinator,
                config.account
            ) = createSub.createSubscription();

            // Funding Subscription
            FundSubscription fundSub = new FundSubscription();
            fundSub.fundSubscription(
                config.subscriptionID,
                config.vrfCoordinator,
                config.link,
                config.account
            );
        }

        vm.startBroadcast(config.account); /////////////////////////////////////////

        Raffle raffle = new Raffle(
            _entranceFee_usd,
            _interval,
            config.priceFeedAdd,
            config.vrfCoordinator,
            config.subscriptionID,
            config.callbackGasLimit,
            config.keyhash
        );
        vm.stopBroadcast(); /////////////////////////////////////////

        // Adding Consumer to the Created Subscription !
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionID,
            config.account
        );

        return (raffle, helperConfig);
    }
}
