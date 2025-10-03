// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Raffle} from "src/RaffleLottery.sol";
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {
    error CreateSubscription__Invalid_subID();

    function createSubscription() public returns (uint, address) {
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.get_networkConfig().vrfCoordinator;
        uint subID = _createSubscription(vrfCoordinator);
        return (subID, vrfCoordinator);
    }

    function _createSubscription(
        address vrfCoordinator
    ) internal returns (uint) {
        console.log("Creating Subscription ID: ");
        vm.startBroadcast(); ///////////////////////////////////////////////////////
        uint subID = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast(); /////////////////////////////////////////////////////////
        if (subID == 0) revert CreateSubscription__Invalid_subID();
        console.log("*** Subscription Created: ", subID);
        return subID;
    }

    function run() external {
        createSubscription();
    }
}
