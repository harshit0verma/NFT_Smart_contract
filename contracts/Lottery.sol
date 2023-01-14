// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

error Lottery__NotEnoughtETHEntered();
error Raffle_TranferFailed();
error Lottery_NotOpen();
error Lottery_UpkeepNotNeeded(
    uint256 current_balance,
    uint256 numPlayers,
    uint256 lotteryState
);

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/**
 * @title Sample Lotttery COntract
 * @author harshit0verma
 * @notice This contract is for creating an untamperable decentralized smart contract
 * @dev this implement chainlink VRF v2 and chainlink Keepers
 */
contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* type declaration */
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /* state variables*/
    uint256 private immutable i_entranceFee;
    address[] private s_players;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subsciptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastTimeStamp;
    uint256 private s_interval;

    // Lottery Variables
    address private s_recentWinner;
    LotteryState private s_lotteryState;

    // events
    event LotteryEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed Winner);

    constructor(
        address x,
        uint64 subsciptionId,
        bytes32 gasLane,
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(x) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(x);
        i_gasLane = gasLane;
        i_subsciptionId = subsciptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_interval = interval;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughtETHEntered();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery_NotOpen();
        }
        // here payable is written bcs tha player needs to be payed by the smart contract when getRandonwinner is called
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    /**
     * @dev
     */

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (bool upkeepNeeded, bytes memory /* perform data*/)
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > s_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /*performdata*/) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }

        s_lotteryState = LotteryState.CALCULATING;
        uint256 requesId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subsciptionId,
            3,
            i_callbackGasLimit,
            1
        );
        emit RequestedRaffleWinner(requesId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");

        if (!success) {
            revert Raffle_TranferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View/ Pure Functions*/

    function getPlayer(uint256 i) public view returns (address) {
        return s_players[i];
    }

    function getentraceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumberofPLayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }
}
