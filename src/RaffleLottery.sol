// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error Raffle__InvalidAmount();
error Raffle__RaffleLocked();

contract Raffle {
    using PriceConverter for uint256;
    // I made these immutable variables public because they're not stored in the stack anyway
    // I mean just make the public so I can get them from the ABI (DUHHHH).
    uint public immutable i_entranceFee_usd;
    uint public immutable i_interval;
    address payable[] private players;
    AggregatorV3Interface private immutable i_priceFeed;

    event PlayerEntered(address indexed _player);

    constructor(uint _entranceFee_usd, uint _interval, address priceFeedAdd) {
        i_entranceFee_usd = _entranceFee_usd;
        i_interval = _interval;
        i_priceFeed = AggregatorV3Interface(priceFeedAdd);
    }

    /**
        Players enter raffle by depositing some amount of eth
        The function should convert the eth into usd, in order to be compared with the entrance fee in USD
        register that player into an array so we can keep track of each player.
     */

    function enterRaffle() external payable {
        if (block.timestamp >= i_interval) revert Raffle__RaffleLocked();

        address player = msg.sender;
        uint fee = msg.value.getConversion(i_priceFeed);
        if (fee != i_entranceFee_usd) revert Raffle__InvalidAmount();

        players.push(payable(player));

        emit PlayerEntered(player);
    }

    /**
        This function should be able to take a random number in between 0 and last players list item number
        in order to pick the winner
        Also it shouldn't work untill the enterance period is done
     */

    function pickWinner() external returns (address winner) {}
}
