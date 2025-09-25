// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/RaffleLottery.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";

contract TestRaffle is Test {
    Raffle raffle;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, ) = deployer.run();
    }

    function test_RaffleStateOpen() external view {
        assert(raffle.get_RaffleState() == Raffle.RaffleState.OPEN);
    }
}
