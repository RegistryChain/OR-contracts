// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error SBT__NotShittyCopper();
error SBT__NotFineCopper();

contract SBT is ERC1155 {
  using Math for uint256;

    IERC20 public shittyCopper;
    IERC20 public fineCopper;

    modifier onlyShittyCopper() {
        if (msg.sender != address(shittyCopper)) {
            revert SBT__NotShittyCopper();
        }
        _;
    }

    modifier onlyFineCopper() {
        if (msg.sender != address(fineCopper)) {
            revert SBT__NotFineCopper();
        }
        _;
    }

    constructor(address _shittyCopper, address _fineCopper) ERC1155("") {
        shittyCopper = IERC20(_shittyCopper);
        fineCopper = IERC20(_fineCopper);
    }

    function downVote(address wallet, uint256 amount) public onlyShittyCopper {
      uint256 sqrtAmount = amount.sqrt();
      uint256 formattedAmount = sqrtAmount / (10 ** 9);

      _mint(wallet, 0, formattedAmount, "");

      emit DownVoted(wallet, amount);
    }

    function upVote(address wallet, uint256 amount) public onlyFineCopper {
      uint256 sqrtAmount = amount.sqrt();
      uint256 formattedAmount = sqrtAmount / (10 ** 9);

      _mint(wallet, 1, formattedAmount, "");

      emit UpVoted(wallet, amount);
    }

    event DownVoted(address indexed from, uint256 amount);
    event UpVoted(address indexed from, uint256 amount);
}
