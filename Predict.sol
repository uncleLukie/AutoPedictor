pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Prediction is Ownable {
    using SafeMath for uint256;

    enum Outcome { WIN, LOSS, DRAW }
    enum Status { OPEN, CLOSED }

    mapping(address => uint256) private _balances;
    mapping(Outcome => uint256) private _totalPredictions;
    mapping(Outcome => mapping(address => uint256)) private _predictions;

    uint256 private _totalAmount;

    Outcome public result;
    Status public _currentStatus;

    uint256 public _minBet = 0.003 ether; 

    event PredictionMade(address indexed player, Outcome prediction, uint256 amount);
    event PredictionResult(Outcome result, uint256 totalAmount);

    function openPredictions() public onlyOwner {
        require(_currentStatus == Status.CLOSED, "Status must be closed.");
        _currentStatus = Status.OPEN;
        _totalAmount = 0;
        _totalPredictions[Outcome.WIN] = 0;
        _totalPredictions[Outcome.LOSS] = 0;
        _totalPredictions[Outcome.DRAW] = 0;
    }

    function closePredictions() public onlyOwner {
        require(_currentStatus == Status.OPEN, "Status must be open.");
        require(_totalPredictions[Outcome.WIN] > 0 && _totalPredictions[Outcome.LOSS] > 0, "At least one player must predict a win and a loss.");
        _currentStatus = Status.CLOSED;
        emit PredictionResult(result, _totalAmount);
    }

    function makePrediction(Outcome prediction) public payable {
        require(_currentStatus == Status.OPEN, "Predictions are not open.");
        require(prediction == Outcome.WIN || prediction == Outcome.Loss, "Invalid prediction.");
        require(msg.value >= _minBet, "Prediction amount must be greater than minimum bet");
        _balances[msg.sender] = _balances[msg.sender].add(msg.value);
        _predictions[prediction][msg.sender] = _predictions[prediction][msg.sender].add(msg.value);
        _totalPredictions[prediction] = _totalPredictions[prediction].add(msg.value);
        _totalAmount = _totalAmount.add(msg.value);
        emit PredictionMade(msg.sender, prediction, msg.value);
    }

    

    function setResult(Outcome _result) public onlyOwner {
        result = _result;
        emit PredictionResult(result, _totalAmount);
        if (result == Outcome.Draw) {
            refund();
        } else {
            payout();
        }
    }

    function payout() public onlyOwner {
        require(result == Outcome.WIN || result == Outcome.LOSS, "Prediction is not in Win or Loss state.");
        uint256 totalBet = _totalPredictions[result];
        uint256 ownerFee = totalBet.mul(15).div(100);
        uint256 payoutAmount = totalBet.sub(ownerFee);
        //address[] memory winners = getWinners();
        for (uint i = 0; i < winners.length; i++) {
            uint256 amount = _predictions[result][winners[i]];
            uint256 payout = amount.mul(payoutAmount).div(totalBet);
            _balances[winners[i]] = _balances[winners[i]].add(payout);
        }
        _balances[owner()] = _balances[owner()].add(ownerFee);
    }

/*
    function refund() public onlyOwner {
        require(result == Outcome.DRAW, "Prediction is not in Draw state.");
        for (uint i = 0; i < addressList.length; i++) {
            uint256 amount = _balances[addressList[i]];
            if (amount > 0) {
                _balances[addressList[i]] = 0;
                payable(addressList[i]).transfer(amount);
            }
        }
    }*/
}