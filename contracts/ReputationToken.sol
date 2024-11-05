// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IReputationToken.sol";
import "./interfaces/ISBT.sol";

error ReputationToken__NotBasicToken();
error ReputationToken__SBTAlreadySet();

abstract contract ReputationToken is IReputationToken, ERC20, Ownable {
    IERC20 public basicToken;
    ISBT public sbt;

    uint256 public constant ONE_MONTH = 30 days;

    struct TokensEscrowed {
        uint256 amount;
        uint256 escrowedAt;
    }

    mapping(address => TokensEscrowed[]) public tokensEscrowed;

    mapping(address => uint256) public targetNonce; //targetNonce[target] += 1
    mapping(address => mapping(uint256 => address))
        public targetToSenderByNonce; //targetToSenderByNonce[target][targetNonce] = sender - for looping sender/target pairs
    mapping(address => mapping(address => uint256)) public senderToTargetRating; //senderToTargetRating[sender][target] = balance

    // May need to record weights/weight factors at time of rating. Or could be current weight? Depends on how we want to score

    function getSenderRatingsListForTarget(
        address target
    ) external view returns (address[] memory, uint256[] memory) {
        uint256 count = targetNonce[target];
        address[] memory senders = new address[](count);
        uint256[] memory ratings = new uint256[](count);

        for (uint256 i = 1; i <= count; i++) {
            address sender = targetToSenderByNonce[target][i];
            uint256 rating = senderToTargetRating[sender][target];
            senders[i-1] = sender;
            ratings[i-1] = rating;
        }
        return (senders, ratings);
    }

    modifier onlyBasicToken() {
        if (msg.sender != address(basicToken)) {
            revert ReputationToken__NotBasicToken();
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _basicToken,
        address _owner
    ) ERC20(name, symbol) Ownable() {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
        basicToken = IERC20(_basicToken);
    }

    function setSBT(address _sbt) external onlyOwner {
        if (address(sbt) != address(0)) {
            revert ReputationToken__SBTAlreadySet();
        }
        sbt = ISBT(_sbt);
    }

    function allowance(
        address owner,
        address spender
    ) public view override(ERC20, IERC20) returns (uint256) {
        if (msg.sender == address(basicToken)) {
            return type(uint256).max;
        } else {
            return super.allowance(owner, spender);
        }
    }

    function mint(address to, uint256 amount) public override onlyBasicToken {
        _mint(to, amount);
    }

    function burn(
        address from,
        uint256 amount
    ) public override onlyBasicToken {
        _burn(from, amount);
    }

    function balanceOf(
        address account
    ) public view override(ERC20, IERC20) returns (uint256) {
        return super.balanceOf(account) + _getTokensOutOfEscrow(account);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override(ERC20, IERC20) returns (bool) {
        _maybeReleaseEscrowedTokens();
        if (senderToTargetRating[from][to] == 0) {
            targetNonce[to] += 1;
            targetToSenderByNonce[to][targetNonce[to]] = from;
        }
        senderToTargetRating[from][to] += value;

        if (msg.sender == address(basicToken)) {
            super._transfer(from, to, value);
        } else {
            super._transfer(from, address(this), value);

            // escrow tokens
            TokensEscrowed[] storage escrowedTokens = tokensEscrowed[from];
            escrowedTokens.push(TokensEscrowed(value, block.timestamp));
        }

        return true;
    }

    function _getTokensOutOfEscrow(
        address account
    ) internal view returns (uint256) {
        TokensEscrowed[] memory escrowedTokens = tokensEscrowed[account];

        uint256 totalTokens = 0;
        for (uint256 i = 0; i < escrowedTokens.length; i++) {
            if (escrowedTokens[i].escrowedAt + ONE_MONTH < block.timestamp) {
                totalTokens += escrowedTokens[i].amount;
            }
        }

        return totalTokens;
    }

    function _maybeReleaseEscrowedTokens() internal {
        TokensEscrowed[] storage escrowedTokens = tokensEscrowed[msg.sender];
        uint256 i = 0;

        while (i < escrowedTokens.length) {
            if (escrowedTokens[i].escrowedAt + ONE_MONTH < block.timestamp) {
                // Release the tokens from escrow
                super._transfer(
                    address(this),
                    msg.sender,
                    escrowedTokens[i].amount
                );

                // Remove the element from the array by replacing it with the last element
                escrowedTokens[i] = escrowedTokens[escrowedTokens.length - 1];
                escrowedTokens.pop();

                // Don't increment `i` to check the new element at this index
            } else {
                // Only increment if no element was removed
                i++;
            }
        }
    }
}
