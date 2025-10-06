// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    using PriceConverter for uint256;

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // I made these immutable variables public because they're not stored in the stack anyway
    // I mean just made them public so I can get them from the ABI (DUHHHH).
    uint public immutable i_entranceFee_usd;
    uint public immutable i_interval;
    uint private s_lastsnapshot;
    uint private counter;
    address payable[] private s_players;
    address payable private s_winner;
    RaffleState private s_raffleState;

    mapping(address => uint) private s_playerIDNum;

    //////////////////////////////////////////////////////////////////////////////////////////
    AggregatorV3Interface private immutable i_priceFeed;
    ////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////////////////////
    ////////// VRF Static Var//////////////////////////////////////////////////////////////////
    /*||*/ uint256 public immutable i_subscriptionID;
    /*||*/ bytes32 public immutable i_keyhash;
    /*||*/ uint32 public immutable i_callbackGasLimit;
    /*||*/ uint16 constant REQUESTCONFIRMATIONS = 3;
    /*||*/ uint32 constant NUMWORDS = 1;
    //////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////

    event PlayerEntered(address indexed _player);
    event WinnerPicked(address indexed _winner);
    event RequestedRaffleWinner(uint indexed _requestId);

    error Raffle__InvalidAmount();
    error Raffle__RaffleLocked();
    error Raffle__FailedTransfer();
    error Raffle__BadVRF();

    constructor(
        uint _entranceFee_usd,
        uint _interval,
        address priceFeedAdd,
        address vrfCoordinator,
        uint subscriptionID,
        uint32 callbackGasLimit,
        bytes32 keyhash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee_usd = _entranceFee_usd;
        i_interval = _interval;
        i_priceFeed = AggregatorV3Interface(priceFeedAdd);
        i_subscriptionID = subscriptionID;
        i_callbackGasLimit = callbackGasLimit;
        i_keyhash = keyhash;

        s_lastsnapshot = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /**
        Players enter raffle by depositing some amount of eth
        The function should convert the eth into usd, in order to be compared with the entrance fee in USD
        register that player into an array so we can keep track of each player.
     */

    function enterRaffle() external payable {
        address player = msg.sender;
        uint fee = msg.value.getConversion(i_priceFeed);
        if (fee != i_entranceFee_usd) revert Raffle__InvalidAmount();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleLocked();

        s_players.push(payable(player));
        s_playerIDNum[player] = counter;
        counter++;

        emit PlayerEntered(player);
    }

    /**
        This function should be able to take a random number in between 0 and last players list item number
        in order to pick the winner
        Also it shouldn't work untill the enterance period is done
     */

    function pickWinner() public {
        if (block.timestamp - s_lastsnapshot <= i_interval) {
            revert Raffle__RaffleLocked();
        }

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyhash,
                subId: i_subscriptionID,
                requestConfirmations: REQUESTCONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUMWORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint requestId = s_vrfCoordinator.requestRandomWords(request);
        s_raffleState = RaffleState.CALCULATING;
        // winner = s_players[requestId];
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint index = randomWords[0] % s_players.length;
        if (!(index >= 0 && index < s_players.length)) revert Raffle__BadVRF();
        s_winner = s_players[index];
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        emit WinnerPicked(s_winner);

        (bool success, ) = s_winner.call{value: address(this).balance}("");
        if (!success) revert Raffle__FailedTransfer();
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool validInterval = (block.timestamp - s_lastsnapshot) > i_interval;
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool hasBalance = (address(this).balance > 0);
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = validInterval && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (upkeepNeeded) {
            pickWinner();
        }
    }

    function get_RaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function get_lastSnapshot() external view returns (uint) {
        return s_lastsnapshot;
    }

    function get_PlayerIDNum(address player) external view returns (uint) {
        return s_playerIDNum[player];
    }

    function get_TotalPlayers() external view returns (uint) {
        return s_players.length;
    }

    function get_Player(uint index) external view returns (address) {
        return s_players[index];
    }
}
