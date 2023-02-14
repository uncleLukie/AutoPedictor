pragma solidity ^0.8.17;

contract Predict {
    address public owner;
    mapping (address => uint256) public balances;
    enum Outcome { Win, Loss }
    bool public betsOpen = false;
    Outcome public result;

    constructor() public {
        owner = msg.sender;
    }

    function predictWin() public payable {
        require(result == Outcome.Win || result == Outcome.Loss, "Result has not been set yet.");
        balances[msg.sender] += msg.value;
    }

    function predictLoss() public payable {
        require(result == Outcome.Win || result == Outcome.Loss, "Result has not been set yet.");
        balances[msg.sender] += msg.value;
    }

    function setBetsOpen(bool _betsOpen) public {
        require(msg.sender == owner, "Only the contract owner can open or close bets.");
        betsOpen = _betsOpen;
    }

    function setResult(Outcome _result) public {
        require(msg.sender == owner, "Only the contract owner can set the result.");
        result = _result;
    }

    function refund() public {
        require(msg.sender == owner, "Only the contract owner can call for a payout.");
        
    }

    function payout() public {
        require(msg.sender == owner, "Only the contract owner can call for a payout.");

        for (address player : balances) {
            if (result == Outcome.Win) {
                player.transfer(balances[player]);
            } else if (result == Outcome.Loss) {
                player.transfer(balances[player]);
            }
        }
    }
}