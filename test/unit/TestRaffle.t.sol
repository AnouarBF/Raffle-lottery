// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/RaffleLottery.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract TestRaffle is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    address PLAYER = makeAddr("player");
    uint private constant INITIAL_BALANCE = 10 ether;
    // uint entranceFee_usd;
    // uint interval;
    address priceFeedAdd;
    address vrfCoordinator;
    uint subscriptionID;
    uint32 callbackGasLimit;
    bytes32 keyhash;

    event PlayerEntered(address indexed _player);
    event WinnerPicked(address indexed _winner);
    event RequestedRaffleWinner(uint indexed _requestId);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run(400, 30);

        HelperConfig.NetworkConfig memory config = helperConfig
            .get_networkConfig();

        // entranceFee_usd = config._entranceFee_usd;
        // interval = config._interval;
        priceFeedAdd = config.priceFeedAdd;
        vrfCoordinator = config.vrfCoordinator;
        subscriptionID = config.subscriptionID;
        callbackGasLimit = config.callbackGasLimit;
        keyhash = config.keyhash;

        vm.deal(PLAYER, INITIAL_BALANCE);
    }

    function test_RaffleStateOpen() external view {
        assert(raffle.get_RaffleState() == Raffle.RaffleState.OPEN);
    }

    function test_VRFSubscriptionID() external view {
        assert(raffle.i_subscriptionID() == 0);
    }

    function test_correctEntranceFee() external view {
        assert(raffle.i_entranceFee_usd() == 100);
    }

    function test_correctInterval() external view {
        assert(raffle.i_interval() == 30);
    }

    ////////////////////////////////////////////////////////////////////////
    //////////////////****  Enter Raffle  ****/////////////////////////////
    //////////////////////////////////////////////////////////////////////

    function test_revertInvalidAmount() external {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__InvalidAmount.selector);
        raffle.enterRaffle();
    }

    function test_playerEntered() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.1 ether}();

        uint index = raffle.get_PlayerIDNum(PLAYER);

        assert(index == 0);
        assert(raffle.get_Player(index) == PLAYER);
    }

    function test_multiplePlayers() external {
        uint counter = 1;
        uint limit = 10;

        for (counter; counter <= limit; counter++) {
            // vm.prank(address(counter));
            hoax(address(uint160(counter)), INITIAL_BALANCE);
            raffle.enterRaffle{value: 0.1 ether}();
        }

        assert(raffle.get_TotalPlayers() == limit);
    }

    function test_emitEvent_PlayerEntered() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit PlayerEntered(PLAYER);

        raffle.enterRaffle{value: 0.1 ether}();
    }
}
