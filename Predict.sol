pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Prediction is Ownable {
    using SafeMath for uint256;

    enum Outcome { Underway, Win, Loss, Draw }

    mapping(address => uint256) private _balances;
    mapping(Outcome => uint256) private _totalPredictions;
    mapping(Outcome => mapping(address => uint256)) private _predictions;

    uint256 private _totalAmount;

    Outcome public result = Outcome.Underway;

    event PredictionMade(address indexed player, Outcome prediction, uint256 amount);
    event PredictionResult(Outcome result, uint256 totalAmount);

    function openPrediction() public onlyOwner {
        require(result == Outcome.Underway, "Prediction is not in Underway state.");
        result = Outcome.Underway;
        _totalAmount = 0;
        _totalPredictions[Outcome.Win] = 0;
        _totalPredictions[Outcome.Loss] = 0;
        _totalPredictions[Outcome.Draw] = 0;
    }

    function makePrediction(Outcome prediction) public payable {
        require(result == Outcome.Underway, "Prediction is not in Underway state.");
        require(prediction == Outcome.Win || prediction == Outcome.Loss, "Invalid prediction.");
        require(msg.value > 0, "Prediction amount must be greater than 0.");
        _balances[msg.sender] = _balances[msg.sender].add(msg.value);
        _predictions[prediction][msg.sender] = _predictions[prediction][msg.sender].add(msg.value);
        _totalPredictions[prediction] = _totalPredictions[prediction].add(msg.value);
        _totalAmount = _totalAmount.add(msg.value);
        emit PredictionMade(msg.sender, prediction, msg.value);
    }

    function closePrediction() public onlyOwner {
        require(result == Outcome.Underway, "Prediction is not in Underway state.");
        require(_totalPredictions[Outcome.Win] > 0 && _totalPredictions[Outcome.Loss] > 0, "At least one player must predict a win and a loss.");
        result = Outcome.Underway;
        emit PredictionResult(result, _totalAmount);
    }

    function setResult(Outcome _result) public onlyOwner {
        require(result == Outcome.Underway, "Prediction is not in Underway state.");
        result = _result;
        emit PredictionResult(result, _totalAmount);
        if (result == Outcome.Draw) {
            refund();
        } else {
            payout();
        }
    }

    function payout() public onlyOwner {
        require(result == Outcome.Win || result == Outcome.Loss, "Prediction is not in Win or Loss state.");
        uint256 totalBet = _totalPredictions[result];
        uint256 ownerFee = totalBet.mul(15).div(100);
        uint256 payoutAmount = totalBet.sub(ownerFee);
        address[] memory winners = getWinners();
        for (uint i = 0; i < winners.length; i++) {
            uint256 amount = _predictions[result][winners[i]];
            uint256 payout = amount.mul(payoutAmount).div(totalBet);
            _balances[winners[i]] = _balances[winners[i]].add(payout);
        }
        _balances[owner()] = _balances[owner()].add(ownerFee);
    }

    function refund() public onlyOwner {
        require(result == Outcome.Draw, "Prediction is not in Draw state.");
        for (uint i = 0; i < addressList.length; i++) {
            uint256 amount = _balances[addressList[i]];
            if (amount > 0) {
                _balances[addressList[i]] = 0;
                payable(addressList[i]).transfer(amount);
            }
        }
    }
}