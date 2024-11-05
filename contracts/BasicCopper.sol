// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IReputationToken.sol";

error BasicToken__ReputationTokensAlreadySet();
error BasicToken__LiquidityPoolAlreadySet();
error BasicToken__TransferValueTooHigh();
error BasicToken__ZeroAmount();
error BasicToken__NotEnoughBalance();

contract BasicToken is ERC20, Ownable {
    IReputationToken public downToken;
    IReputationToken public upToken;
    address public liquidityPool;
    mapping(address => bool) faucetMinted;

    constructor() ERC20("BasicToken", "BCP") Ownable() {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function mintFromFaucet() external {
        require(faucetMinted[msg.sender] == false);
        downToken.mint(msg.sender, 1000000 * 10 ** decimals());
        upToken.mint(msg.sender, 1000000 * 10 ** decimals());

        faucetMinted[msg.sender] = true;
    }

    function setReputationTokens(
        address _downToken,
        address _upToken
    ) external onlyOwner {
        if (
            address(downToken) != address(0) ||
            address(upToken) != address(0)
        ) {
            revert BasicToken__ReputationTokensAlreadySet();
        }

        downToken = IReputationToken(_downToken);
        upToken = IReputationToken(_upToken);
    }

    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        if (liquidityPool != address(0)) {
            revert BasicToken__LiquidityPoolAlreadySet();
        }

        liquidityPool = _liquidityPool;
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        _handleTransfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _handleTransfer(from, to, value);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (downToken.balanceOf(account) != upToken.balanceOf(account)) {
            return
                (downToken.balanceOf(account) +
                    upToken.balanceOf(account)) / 2;
        }
        return super.balanceOf(account);
    }

    function convertToUpToken(uint256 amount) public returns (uint256) {
        if (amount == 0) revert BasicToken__ZeroAmount();
        if (amount > downToken.balanceOf(msg.sender))
            revert BasicToken__NotEnoughBalance();

        downToken.burn(msg.sender, amount);
        upToken.mint(msg.sender, amount);

        emit ConvertedToUpToken(msg.sender, amount);

        return amount;
    }

    function convertToDownToken(uint256 amount) public returns (uint256) {
        if (amount == 0) revert BasicToken__ZeroAmount();
        if (amount > upToken.balanceOf(msg.sender))
            revert BasicToken__NotEnoughBalance();

        upToken.burn(msg.sender, amount);
        downToken.mint(msg.sender, amount);

        emit ConvertedToDownToken(msg.sender, amount);

        return amount;
    }

    function _handleTransfer(address from, address to, uint256 value) internal {
        if (value > balanceOf(from)) {
            revert BasicToken__TransferValueTooHigh();
        }

        (uint256 scpAmount, uint256 fcpAmount) = _calculateReputationTransfers(
            from,
            value
        );

        super._transfer(from, to, value);

        if (from == liquidityPool) {
            downToken.mint(to, scpAmount);
            upToken.mint(to, fcpAmount);
        } else if (to == liquidityPool) {
            downToken.burn(from, scpAmount);
            upToken.burn(from, fcpAmount);
        } else {
            downToken.transferFrom(from, to, scpAmount);
            upToken.transferFrom(from, to, fcpAmount);
        }
    }

    function _calculateReputationTransfers(
        address from,
        uint256 value
    ) internal view returns (uint256 scpAmount, uint256 fcpAmount) {
        if (from == liquidityPool) {
            return (value, value);
        } else {
            uint256 totalSCPBalance = downToken.balanceOf(from);
            uint256 totalFCPBalance = upToken.balanceOf(from);

            if (
                totalSCPBalance == totalFCPBalance ||
                (totalSCPBalance > value && totalFCPBalance > value)
            ) {
                return (value, value);
            } else if (totalSCPBalance > totalFCPBalance) {
                scpAmount = totalSCPBalance - value;
                fcpAmount = totalFCPBalance;
            } else {
                scpAmount = totalSCPBalance;
                fcpAmount = totalFCPBalance - value;
            }

            return (scpAmount, fcpAmount);
        }
    }

    event ConvertedToUpToken(address indexed from, uint256 amount);
    event ConvertedToDownToken(address indexed from, uint256 amount);
}
