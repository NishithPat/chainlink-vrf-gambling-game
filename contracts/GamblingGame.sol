// KOVAN address - 0x519aC9d293b8121fa84303fD9ee142387D1530f6

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract GamblingGame is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    address public owner;
    uint256 public N;
    uint256 public stakeAmount;
    uint256 public contractBalance;
    uint256 public currentStakers;
    bool public canCallGetRandomNumber;

    mapping(address => uint256) public stakerMapping;
    mapping(uint256 => address) public indexToStakerMapping;

    bool public winnerDeclared;
    address public winnerAddress;
    event Winner(address);

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor(uint256 _N, uint256 _stakeAmount)
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088 // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
        owner = msg.sender;

        require(
            _N >= 3,
            "Number of players should be greater than or equal to 3"
        );
        N = _N;
        stakeAmount = _stakeAmount;
    }

    function stake() public payable {
        require(msg.sender != owner, "owner cannot stake");
        require(
            msg.value >= stakeAmount,
            "amount must be greater than stakeAmount"
        );
        require(stakerMapping[msg.sender] == 0, "cannot stake again");
        require(
            !winnerDeclared,
            "winner has been declared. Cannot stake anymore"
        );
        require(currentStakers < N, "max stakers reached. No more staking.");

        if (msg.value > stakeAmount) {
            contractBalance += msg.value - stakeAmount;
        }

        currentStakers += 1;
        stakerMapping[msg.sender] = currentStakers;
        indexToStakerMapping[currentStakers - 1] = msg.sender;

        if (currentStakers == N) {
            canCallGetRandomNumber = true;
        }
    }

    function unstake() public {
        require(
            currentStakers != N,
            "Cannot unstake. As all the players have staked!"
        );
        require(msg.sender != owner, "owner cannot unstake");
        require(
            stakerMapping[msg.sender] > 0,
            "staker has no stake. They cannot unstake."
        );

        currentStakers -= 1;
        uint256 val = stakerMapping[msg.sender];
        delete indexToStakerMapping[val - 1];
        delete stakerMapping[msg.sender];

        (bool sent, ) = payable(msg.sender).call{value: stakeAmount}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            !winnerDeclared,
            "winner has been declared. Cannot call getRandomNumber again."
        );
        require(canCallGetRandomNumber, "random number cannot be called");
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        requestId = requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;

        uint256 index = randomResult % N;
        winnerAddress = indexToStakerMapping[index];

        winnerDeclared = true;
        emit Winner(winnerAddress);
    }

    function sendReward() public {
        require(
            winnerDeclared,
            "sendReward can only be called if the winner is declared"
        );

        uint256 totalReward = address(this).balance - contractBalance;
        uint256 rewardForWinner = (totalReward * 99) / 100;
        contractBalance = contractBalance + totalReward - rewardForWinner;

        (bool sent, ) = payable(winnerAddress).call{value: rewardForWinner}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawEth() public {
        require(owner == msg.sender, "only owner can withdraw");
        uint256 withdrawableEth = contractBalance;
        contractBalance = 0;
        (bool sent, ) = payable(msg.sender).call{value: withdrawableEth}("");
        require(sent, "Failed to send Ether");
    }

    //Implement a withdraw function to avoid locking your LINK in the contract
    function withdrawLink() public {
        require(msg.sender == owner, "only owner can withdraw");
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }

    function reset(uint256 _N, uint256 _stakeAmount) public {
        require(msg.sender == owner, "only owner can call reset");
        require(
            winnerDeclared,
            "reset can only be called after winner is declared"
        );
        sendReward();
        withdrawEth();

        randomResult = 0;
        N = _N;
        stakeAmount = _stakeAmount;

        canCallGetRandomNumber = false;
        winnerDeclared = false;
        winnerAddress = address(0);

        for (uint256 i = 0; i < currentStakers; i++) {
            address staker = indexToStakerMapping[i];
            delete stakerMapping[staker];
            delete indexToStakerMapping[i];
        }

        currentStakers = 0;
    }
}
