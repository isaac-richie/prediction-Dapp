//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract StockPredition {
    address public owner;
    uint256 public predictionStartTime;
    uint256 public predictionEndTime;
    int public currentPrice;//using "int" because values can be negative
    mapping(address => int ) public bets;//mapping addreses to int
    address [] public bettors;
    mapping (address => uint256) public betAmounts;//keepinf track of addresses and their bet amount

    uint256 public lastCheckedTime;
    bool public isBettingActive;
    address public lastWinner;

    struct bet {//this struct holds the hettors address and amount
        address bettor;
        int amount;
    }

    struct BetInfo {
        address bettor;
        int amount;
        uint256 betAmount; 
    }

    constructor() {
        owner = msg.sender;
        predictionEndTime = block.timestamp + 5 minutes;
        isBettingActive = false;
    }

    function getAllBets() public view returns(BetInfo [] memory) {
        BetInfo [] memory allBets = new BetInfo[](bettors.length);
        for(uint256 i = 0; i < bettors.length; i++){//loop through all the bettors
            allBets[i].bettor = bettors[i]; 
            allBets[i].amount = bets[bettors[i]];
            allBets[i].betAmount = betAmounts[bettors[i]];
        }
        return allBets;
    }

    function startPrediction(int _currentPrice) public {
        require(msg.sender == owner,"only owner can start bet");
        currentPrice = _currentPrice;
        predictionStartTime = block.timestamp;
        predictionEndTime = block.timestamp + 5 minutes;
        isBettingActive = true;

    }

    function enterBet(int _prediction) public payable {
        require(block.timestamp < predictionEndTime, "prediction has ended");
        require(msg.value >= 0.01 ether, "insufficient funds");
        bets[msg.sender] = _prediction;
        bettors.push(msg.sender);
        betAmounts[msg.sender] = msg.value;

    }

    function finalizePrediction(int _currentPrice) public {
        require(block.timestamp >= predictionEndTime, "Prediction time is not over yet");
        require(isBettingActive, "Betting is not active");

        currentPrice = _currentPrice;

        int closestPrediction = bets[bettors[0]];
        uint closestDistance = abs(currentPrice, closestPrediction);
        address payable winner = payable(bettors[0]);

        for (uint i = 1; i < bettors.length; i++) {
            int prediction = bets[bettors[i]];
            uint distance = abs(currentPrice, prediction);
            if (distance < closestDistance) {
                closestPrediction = prediction;
                closestDistance = distance;
                winner = payable(bettors[i]);
            }
        }

        uint pool = address(this).balance;
        require(pool > 0, "No ether in pool");
        require(winner != address(0), "No winner");
        winner.transfer(pool);
        lastWinner = winner;

        predictionStartTime = 0;
        predictionEndTime = 0;
        currentPrice = 0;
        isBettingActive = false;

        for (uint i = 0; i < bettors.length; i++) {
            bets[bettors[i]] = 0;
        }
        bettors = new address[](0);
    }

    function resetLastWinner() public {
        require (msg.sender == owner, "only owner can call");
        lastWinner = address(0);//reset the bet to zero after winner
    }

    function isPredictionOver() public view returns(bool) {
        if(block.timestamp >= predictionEndTime){
            return true;
        }
        return false;
    }

    function getPoolAmount() public view returns (uint){//get all funds in the pool
        return address(this).balance;
    }


    function abs(int x, int y) internal pure returns(uint) {//this shows the differences between two diferent numbers x and y
        return x >= y ? uint(x-y): uint(y-x);
    }







}

