// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Raffle} from "src/RaffleLottery.sol";
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DeploymentParameters} from "./DeployParam.s.sol";
import {LinkToken} from "test/mocks/LinkTokenMock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script, DeploymentParameters {
    error CreateSubscription__Invalid_subID();

    function createSubscription() public returns (uint, address, address) {
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.get_networkConfig().vrfCoordinator;
        address account = config.get_networkConfig().account;
        uint subID = _createSubscription(vrfCoordinator, account);
        return (subID, vrfCoordinator, account);
    }

    function _createSubscription(
        address vrfCoordinator,
        address account
    ) internal returns (uint) {
        console.log("****************************************************");
        console.log("Creating Subscription ID: ");

        vm.startBroadcast(account); ///////////////////////////////////////////////////////
        uint subID = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast(); /////////////////////////////////////////////////////////

        if (subID == 0) revert CreateSubscription__Invalid_subID();
        console.log("*** Subscription Created: ", subID);
        console.log("*****************************************************");
        return subID;
    }

    function run() external {
        createSubscription();
    }
}

contract FundSubscription is Script, DeploymentParameters {
    error FundSubscription__Failed_Funding();
    uint private constant FUNDED_AMOUNT = 5 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helper = new HelperConfig();
        address vrfCoordinator = helper.get_networkConfig().vrfCoordinator;
        uint subID = helper.get_networkConfig().subscriptionID;
        address linkToken = helper.get_networkConfig().link;
        address account = helper.get_networkConfig().account;

        fundSubscription(subID, vrfCoordinator, linkToken, account);
    }

    function fundSubscription(
        uint _subID,
        address _vrfCoordinator,
        address token,
        address account
    ) public {
        console.log("Funding Subscription....");
        console.log("Using VRFCoordinator: ", _vrfCoordinator);
        console.log("On chain: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account); //////////////////////////////////////////////////////////
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(
                _subID,
                FUNDED_AMOUNT
            );
            vm.stopBroadcast(); ///////////////////////////////////////////////////////////
        } else {
            vm.startBroadcast(account); ////////////////////////////////////////////////////////////
            LinkToken(token).transferAndCall(
                _vrfCoordinator,
                FUNDED_AMOUNT,
                abi.encode(_subID)
            );
            vm.stopBroadcast(); //////////////////////////////////////////////////////////////////
        }
        console.log("Subscription Funded Successfully");
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address raffle) public {
        HelperConfig config = new HelperConfig();
        address vrfCoordinator = config.get_networkConfig().vrfCoordinator;
        uint subID = config.get_networkConfig().subscriptionID;
        address account = config.get_networkConfig().account;
        addConsumer(raffle, vrfCoordinator, subID, account);
    }

    function addConsumer(
        address raffle,
        address vrfCoordinator,
        uint subID,
        address account
    ) public {
        console.log(
            "***********************************************************************"
        );
        console.log("Adding consumer: ", raffle);
        console.log("Using VRF: ", vrfCoordinator);
        console.log("To the subscription: ", subID);
        console.log("On Chain: ", block.chainid);

        vm.startBroadcast(account); ///////////////////////////////////////////////////////////////
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subID, raffle);
        vm.stopBroadcast(); ///////////////////////////////////////////////////////////////

        console.log(
            "***********************************************************************"
        );
    }

    function run() external {
        address latestRaffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(latestRaffle);
    }
}
