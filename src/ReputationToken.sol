// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IReputationToken.sol";
import "./interfaces/ISBT.sol";

error ReputationToken__NotBasicCopper();
error ReputationToken__SBTAlreadySet();

abstract contract ReputationToken is IReputationToken, ERC20, Ownable {
    IERC20 public basicCopper;
    ISBT public sbt;

    uint256 public constant ONE_MONTH = 30 days;

    struct TokensEscrowed {
        uint256 amount;
        uint256 escrowedAt;
    }

    mapping(address => TokensEscrowed[]) public tokensEscrowed;

    modifier onlyBasicCopper() {
        if (msg.sender != address(basicCopper)) {
            revert ReputationToken__NotBasicCopper();
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _basicCopper,
        address _owner
    ) ERC20(name, symbol) Ownable(_owner) {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
        basicCopper = IERC20(_basicCopper);
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
        if (msg.sender == address(basicCopper)) {
            return type(uint256).max;
        } else {
            return super.allowance(owner, spender);
        }
    }

    function mint(address to, uint256 amount) public override onlyBasicCopper {
        _mint(to, amount);
    }

    function burn(
        address from,
        uint256 amount
    ) public override onlyBasicCopper {
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

        if (msg.sender == address(basicCopper)) {
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
