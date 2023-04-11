// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CoinFlipGame is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_BET_AMOUNT = 5 * 1e18;
    uint256 private nonce;

    IERC20 private token;

    event CoinFlipResult(
        address indexed player,
        uint256 betAmount,
        uint8 guess,
        bool win
    );

    struct GameResult {
        uint256 betAmount;
        uint8 guess;
        bool win;
    }

    mapping(address => GameResult) private latestGameResults;

    constructor(IERC20 _token) {
        token = _token;
    }

    function random() private returns (uint256) {
        nonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, nonce)
                )
            ) % 5;
    }

    function placeBet(uint8 guess) external nonReentrant {
        require(
            guess >= 0 && guess <= 1,
            "Invalid guess, must be between 0 and 1"
        );
        token.safeTransferFrom(msg.sender, address(this), MAX_BET_AMOUNT);

        uint256 randomNumber = random(); // randomNumber is between 0 and 3 (inclusive)
        bool win = (randomNumber == guess);

        uint8 displayedGuess;
        if (win) {
            uint256 prize = MAX_BET_AMOUNT * 2;
            require(
                token.balanceOf(address(this)) >= prize,
                "Not enough funds in the contract to pay the prize"
            );
            token.safeTransfer(msg.sender, prize);
            displayedGuess = guess;
        } else {
            uint256 burnAmount = (MAX_BET_AMOUNT * 10) / 100;
            require(
                token.balanceOf(address(this)) >= burnAmount, "Not enough funds in the contract to burn tokens");
                ERC20Burnable(address(token)).burn(burnAmount);
                        if (guess == 1 && (randomNumber == 2 || randomNumber == 3 || randomNumber == 4)) {
            displayedGuess = 0;
        } else if (guess == 0 && (randomNumber == 2 || randomNumber == 3 || randomNumber == 4)) {
            displayedGuess = 1;
        } else {
            displayedGuess = 1 - guess;
        }
    }

    emit CoinFlipResult(msg.sender, MAX_BET_AMOUNT, displayedGuess, win);
        latestGameResults[msg.sender] = GameResult(MAX_BET_AMOUNT, displayedGuess, win);
    }

    function getLatestGameResult(address player) external view returns (uint256 betAmount, uint8 guess, bool win) {
        GameResult memory result = latestGameResults[player];
        return (result.betAmount, result.guess, result.win);
    }

    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0, "You must deposit a positive amount of tokens");
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(
            amount <= token.balanceOf(address(this)),
            "Requested amount exceeds contract balance"
        );
        token.safeTransfer(msg.sender, amount);
    }
}

