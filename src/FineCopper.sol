// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./ReputationToken.sol";

error FineCopper__TransferValueTooLow();

contract FineCopper is ReputationToken {
    constructor(
        address _basicCopper
    ) ReputationToken("FineCopper", "FCP", _basicCopper, msg.sender) {}

    function transfer(
        address to,
        uint256 value
    ) public override(ERC20, IERC20) returns (bool) {
        super.transferFrom(msg.sender, to, value);
        _handleUpVote(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override(ReputationToken) returns (bool) {
        super.transferFrom(from, to, value);
        _handleUpVote(msg.sender, to, value);
        return true;
    }

    function _handleUpVote(address from, address to, uint256 value) private {
        if (from != address(basicCopper)) {
            if (value < 1 ether) {
                revert FineCopper__TransferValueTooLow();
            }

            uint256 roundedDownValue = value / 1 ether; // Round down the value
            sbt.upVote(to, roundedDownValue * 1 ether); // Use the rounded down value for upVote
        }
    }
}
