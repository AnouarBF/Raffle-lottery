// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Raffle} from "src/RaffleLottery.sol";
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DeploymentParameters} from "./DeployParam.s.sol";
import {LinkToken} from "test/mocks/LinkTokenMock.sol";

contract CreateSubscription is Script, DeploymentParameters {
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
        console.log("****************************************************");
        console.log("Creating Subscription ID: ");
        vm.startBroadcast(); ///////////////////////////////////////////////////////
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

    function fundSubscription(
        uint _subID,
        address _vrfCoordinator,
        address token
    ) public {
        // HelperConfig helper = new HelperConfig();
        // address vrfCoordinator = helper.get_networkConfig().vrfCoordinator;
        // uint subID = helper.get_networkConfig().subscriptionID;
        // address linkToken = helper.get_networkConfig().link;

        if (_subID == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (_subID, ) = createSub.createSubscription();
        }

        _fundSubscription(_subID, _vrfCoordinator, token);
    }

    function _fundSubscription(
        uint _subID,
        address _vrfCoordinator,
        address token
    ) internal {
        console.log("Funding Subscription....");
        console.log("Using VRFCoordinator: ", _vrfCoordinator);
        console.log("On chain: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(); //////////////////////////////////////////////////////////
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(
                _subID,
                FUNDED_AMOUNT
            );
            vm.stopBroadcast(); ///////////////////////////////////////////////////////////
        } else {
            vm.startBroadcast();
            LinkToken(token).transferAndCall(
                _vrfCoordinator,
                FUNDED_AMOUNT,
                abi.encode(_subID)
            );
            vm.stopBroadcast();
        }
        console.log("Subscription Funded Successfully");
    }

    function run() external {
        // fundSubscription();
    }
}
