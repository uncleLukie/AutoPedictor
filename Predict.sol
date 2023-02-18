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

    /* Sets resullt */
    function setResult(_Outcome outcome) public onlyOwner {
        _gameOutcome = outcome;
    }

    function payout() public onlyOwner {
        require(_gameOutcome == _Outcome.WIN || _gameOutcome == _Outcome.LOSS, "Prediction is not in Win or Loss state.");
        uint256 totalAmountToPay = _totalEther.mul(85).div(100); // 85% of the totalAmount to be paid out to winners
        uint256 totalAmountToRefund = _totalEther.mul(15).div(100); // 15% of the totalAmount to be kept as house fee
        
        if (_gameOutcome == _Outcome.WIN) {
            for (uint i = 0; i < _winPlayerPredictions; i++){
                _PlayerPrediction memory iPrediction = _winPlayerPredictions[i];
                address payable playerAddress = iPrediction.addr;
                uint256 amountPredicted = iPrediction.amount;

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
}