// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IReputationToken.sol";

error BasicCopper__ReputationTokensAlreadySet();
error BasicCopper__LiquidityPoolAlreadySet();
error BasicCopper__TransferValueTooHigh();
error BasicCopper__ZeroAmount();
error BasicCopper__NotEnoughBalance();

contract BasicCopper is ERC20, Ownable {
    IReputationToken public shittyCopper;
    IReputationToken public fineCopper;
    address public liquidityPool;
    mapping(address => bool) faucetMinted;

    constructor() ERC20("BasicCopper", "BCP") Ownable(msg.sender) {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function mintFromFaucet() external {
        require(faucetMinted[msg.sender] == false);
        shittyCopper.mint(msg.sender, 1000000 * 10 ** decimals());
        fineCopper.mint(msg.sender, 1000000 * 10 ** decimals());

        faucetMinted[msg.sender] = true;
    }

    function setReputationTokens(
        address _shittyCopper,
        address _fineCopper
    ) external onlyOwner {
        if (
            address(shittyCopper) != address(0) ||
            address(fineCopper) != address(0)
        ) {
            revert BasicCopper__ReputationTokensAlreadySet();
        }

        shittyCopper = IReputationToken(_shittyCopper);
        fineCopper = IReputationToken(_fineCopper);
    }

    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        if (liquidityPool != address(0)) {
            revert BasicCopper__LiquidityPoolAlreadySet();
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
        if (shittyCopper.balanceOf(account) != fineCopper.balanceOf(account)) {
            return
                (shittyCopper.balanceOf(account) +
                    fineCopper.balanceOf(account)) / 2;
        }
        return super.balanceOf(account);
    }

    function convertToFineCopper(uint256 amount) public returns (uint256) {
        if (amount == 0) revert BasicCopper__ZeroAmount();
        if (amount > shittyCopper.balanceOf(msg.sender))
            revert BasicCopper__NotEnoughBalance();

        shittyCopper.burn(msg.sender, amount);
        fineCopper.mint(msg.sender, amount);

        emit ConvertedToFineCopper(msg.sender, amount);

        return amount;
    }

    function convertToShittyCopper(uint256 amount) public returns (uint256) {
        if (amount == 0) revert BasicCopper__ZeroAmount();
        if (amount > fineCopper.balanceOf(msg.sender))
            revert BasicCopper__NotEnoughBalance();

        fineCopper.burn(msg.sender, amount);
        shittyCopper.mint(msg.sender, amount);

        emit ConvertedToShittyCopper(msg.sender, amount);

        return amount;
    }

    function _handleTransfer(address from, address to, uint256 value) internal {
        if (value > balanceOf(from)) {
            revert BasicCopper__TransferValueTooHigh();
        }

        (uint256 scpAmount, uint256 fcpAmount) = _calculateReputationTransfers(
            from,
            value
        );

        super._transfer(from, to, value);

        if (from == liquidityPool) {
            shittyCopper.mint(to, scpAmount);
            fineCopper.mint(to, fcpAmount);
        } else if (to == liquidityPool) {
            shittyCopper.burn(from, scpAmount);
            fineCopper.burn(from, fcpAmount);
        } else {
            shittyCopper.transferFrom(from, to, scpAmount);
            fineCopper.transferFrom(from, to, fcpAmount);
        }
    }

    function _calculateReputationTransfers(
        address from,
        uint256 value
    ) internal view returns (uint256 scpAmount, uint256 fcpAmount) {
        if (from == liquidityPool) {
            return (value, value);
        } else {
            uint256 totalSCPBalance = shittyCopper.balanceOf(from);
            uint256 totalFCPBalance = fineCopper.balanceOf(from);

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

    event ConvertedToFineCopper(address indexed from, uint256 amount);
    event ConvertedToShittyCopper(address indexed from, uint256 amount);
}
