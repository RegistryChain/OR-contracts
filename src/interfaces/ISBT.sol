// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISBT is IERC1155 {
    /**
     * @dev Downvotes the `wallet` by minting `amount` of the bad reputation token.
     * This function can only be called by an authorized contract (e.g., ShittyCopper).
     *
     * @param wallet The address of the wallet to downvote.
     * @param amount The amount of tokens to mint for downvoting.
     */
    function downVote(address wallet, uint256 amount) external;

    /**
     * @dev Upvotes the `wallet` by minting `amount` of the good reputation token.
     * This function can only be called by an authorized contract (e.g., FineCopper).
     *
     * @param wallet The address of the wallet to upvote.
     * @param amount The amount of tokens to mint for upvoting.
     */
    function upVote(address wallet, uint256 amount) external;
}
