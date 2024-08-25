// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReputationToken is IERC20 {
    /**
     * @dev Mints `amount` tokens to the `to` address.
     *
     * Requirements:
     *
     * - Can only be called by authorized addresses (e.g., BasicCopper contract).
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns `amount` tokens from the `from` address.
     *
     * Requirements:
     *
     * - Can only be called by authorized addresses (e.g., BasicCopper contract).
     */
    function burn(address from, uint256 amount) external;
}
