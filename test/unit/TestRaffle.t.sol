// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2, console} from "forge-std/Test.sol";
import {Raffle} from "src/RaffleLottery.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract TestRaffle is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    address PLAYER = makeAddr("player");
    uint private constant INITIAL_BALANCE = 10 ether;
    uint private constant ENTRANCE_FEE_usd = 400;
    uint private constant ENTRANCE_FEE_eth = 0.1 ether;
    uint private constant INTERVAL = 30;
    // uint entranceFee_usd;
    // uint interval;
    address priceFeedAdd;
    address vrfCoordinator;
    uint subscriptionID;
    uint32 callbackGasLimit;
    bytes32 keyhash;

    event PlayerEntered(address indexed _player);
    event WinnerPicked(address indexed _winner);
    event RequestedRaffleWinner();

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run(ENTRANCE_FEE_usd, INTERVAL);
        console.log("Test Contract: ", address(this));
        console.log("Deploy Contract: ", address(deployer));
        console.log("HelperConfig Contract: ", address(helperConfig));
        console.log("Raffle Contract: ", address(raffle));

        HelperConfig.NetworkConfig memory config = helperConfig
            .get_networkConfig();

        uint subID = helperConfig.get_networkConfig().subscriptionID;

        console.log(subID);
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
        assert(raffle.i_subscriptionID() != 0);
    }

    function test_correctEntranceFee() external view {
        assert(raffle.i_entranceFee_usd() == ENTRANCE_FEE_usd);
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
        raffle.enterRaffle{value: 0.01 ether}();
    }

    function test_playerEntered() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE_eth}();

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
            raffle.enterRaffle{value: ENTRANCE_FEE_eth}();
        }

        assert(raffle.get_TotalPlayers() == limit);
    }

    function test_emitEvent_PlayerEntered() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit PlayerEntered(PLAYER);

        raffle.enterRaffle{value: ENTRANCE_FEE_eth}();
    }

    function test_revertLockedRaffle() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE_eth}();

        vm.warp(block.timestamp + INTERVAL + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleLocked.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE_eth}();
    }

    ////////////////////////////////////////////////////////////////////////
    //////////////////****  Pick Winner  ****//////////////////////////////
    //////////////////////////////////////////////////////////////////////

    modifier enterPlayer() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE_eth}();
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.roll(block.number);
        _;
    }

    function test_revertRaffleLockedPerformUpkeep() external enterPlayer {
        vm.warp(INTERVAL);
        vm.roll(block.number);
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                address(raffle),
                raffle.get_RaffleState(),
                address(raffle).balance,
                raffle.get_TotalPlayers()
            )
        );
        raffle.performUpkeep("");
    }

    function test_emitEvent_RequestedRaffleWinner() external enterPlayer {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestID = entries[1].topics[1];

        assert(uint(requestID) > 0);
    }

    function test_fullfilment(uint randomRequestId) external enterPlayer {
        vm.expectRevert();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    ////////////////////////////////////////////////////////////////////////
    /////////////////////****  Big Test  ****//////////////////////////////
    //////////////////////////////////////////////////////////////////////

    function test_Raffle() external {
        uint totalParticipants = 10;
        uint index = 1;
        uint contractBalance;
        uint winnerBalance;

        while (index <= totalParticipants) {
            hoax(address(uint160(index)), INITIAL_BALANCE);
            raffle.enterRaffle{value: ENTRANCE_FEE_eth}();
            index++;
        }

        contractBalance = address(raffle).balance;
        console.log("Contract Total Balance: ");
        console.log(contractBalance);

        vm.warp(block.timestamp + INTERVAL + 1);
        vm.roll(block.number);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        console.logUint(subscriptionID);

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint(requestId),
            address(raffle)
        );

        address winner = raffle.get_latestWinner();
        winnerBalance = winner.balance;

        assert(winnerBalance == contractBalance);
        assert(raffle.get_TotalPlayers() == 0);
        assert(raffle.get_RaffleState() == Raffle.RaffleState.OPEN);
    }
}
