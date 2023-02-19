// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PredictingGame is Ownable {
    using SafeMath for uint256;

    // Define the three possible outcomes for the game and pending outcome
    enum _Outcome { WIN, LOSS, DRAW }

    // Define the two possible states of prediction making
    enum _pStatus { OPEN, CLOSED }

    // PlayerPrediction structure
    struct _PlayerPrediction{
        address payable addr;
        _Outcome prediction;
        uint256 amount;
    }

    // Array of all player predictions for the win side;
    _PlayerPrediction[] public _winPlayerPredictions;

    // Array of all player predictions for the loss side;
    _PlayerPrediction[] public _lossPlayerPredictions;

    // Store the total amount of ether prediction for each outcome
    mapping(_Outcome => uint256) private _totalPredictionEther;

    // Store the mapping of player addresses to their predictions
    //mapping(address => uint256) private _playerPredictions;

    // Store the current outcome of the game
    _Outcome private _gameOutcome;

    // Store the current Prediction Status
    _pStatus private _predictionStatus;

    // Store the owner of the contract
    address payable private _owner;

    // Minimum amount for prediction
    uint256 public _minPrediction = 0.003 ether;

    uint256 public _totalEther;


    /* Opens predictions */
    function openPredictions() public onlyOwner {
        _predictionStatus = _pStatus.OPEN;
    }

    /* Closes predictions */
    function closePredictions() public onlyOwner {
        _predictionStatus = _pStatus.CLOSED;
    }

    /* Sets result */
    function setResult(_Outcome outcome) public onlyOwner {
        _gameOutcome = outcome;
    }

    /* Pay out the winners */
    function payout() public onlyOwner {
        require(_gameOutcome == _Outcome.WIN || _gameOutcome == _Outcome.LOSS, "Prediction is not in Win or Loss state.");

        (uint256 winOdds, uint256 lossOdds) = calculateOdds();
        uint256 houseFee = _totalEther.mul(15).div(100);
        uint256 totalAmountToPay = _totalEther.sub(houseFee);

        if (_gameOutcome == _Outcome.WIN) {
            for (uint i = 0; i < _winPlayerPredictions.length; i++) {
                _PlayerPrediction memory iPrediction = _winPlayerPredictions[i];
                address payable playerAddress = iPrediction.addr;
                uint256 amountPredicted = iPrediction.amount;
                uint256 payoutAmount = amountPredicted.mul(totalAmountToPay).div(_totalPredictionEther[_Outcome.WIN]);
                payoutAmount = payoutAmount.add(payoutAmount.mul(winOdds).div(100)); // Add the win odds to the payout
                playerAddress.transfer(payoutAmount);
            }
        } else if (_gameOutcome == _Outcome.LOSS) {
            for (uint i = 0; i < _lossPlayerPredictions.length; i++) {
                _PlayerPrediction memory iPrediction = _lossPlayerPredictions[i];
                address payable playerAddress = iPrediction.addr;
                uint256 amountPredicted = iPrediction.amount;
                uint256 payoutAmount = amountPredicted.mul(totalAmountToPay).div(_totalPredictionEther[_Outcome.LOSS]);
                payoutAmount = payoutAmount.add(payoutAmount.mul(lossOdds).div(100)); // Add the loss odds to the payout
                playerAddress.transfer(payoutAmount);
            }
        }
    }

    /* Allow players to make a prediction */
    function makePrediction(_Outcome prediction) public payable {
        require(_predictionStatus == _pStatus.OPEN, "Predictions are currently not open.");
        require(prediction == _Outcome.WIN || prediction == _Outcome.LOSS, "Prediction must be WIN or LOSS.");
        require(msg.value >= _minPrediction, "Prediction amount must be greater than 0.003 ether");
        _totalPredictionEther[prediction] += msg.value;

        if(prediction == _Outcome.WIN){
            _winPlayerPredictions.push(_PlayerPrediction(payable(msg.sender), prediction, msg.value));
        }

        else {
            _lossPlayerPredictions.push(_PlayerPrediction(payable(msg.sender), prediction, msg.value));
        }

        _totalEther += msg.value;
    }

    function calculateOdds() public view returns (uint256, uint256) {
        uint256 totalWinEther = _totalPredictionEther[_Outcome.WIN];
        uint256 totalLossEther = _totalPredictionEther[_Outcome.LOSS];

        uint256 netWinEther = totalWinEther;
        uint256 netLossEther = totalLossEther;

        uint256 winOdds = totalLossEther == 0 ? netWinEther : netWinEther.mul(_totalEther).div(netLossEther);
        uint256 lossOdds = totalWinEther == 0 ? netLossEther : netLossEther.mul(_totalEther).div(netWinEther);

        return (winOdds, lossOdds);
    }
}