// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/FineCopper.sol";
import "../src/ShittyCopper.sol";
import "../src/SBT.sol";
import "../src/BasicCopper.sol";

contract FineCopperTest is Test {
    FineCopper public fineCopper;
    ShittyCopper public shittyCopper;
    SBT public sbt;
    BasicCopper public basicCopper;
    address public owner;
    address public user;
    address public recipient;
    address public liquidityPool;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        recipient = address(0x2);
        liquidityPool = address(0x3);

        basicCopper = new BasicCopper();
        shittyCopper = new ShittyCopper(address(basicCopper));
        fineCopper = new FineCopper(address(basicCopper));
        sbt = new SBT(address(shittyCopper), address(fineCopper));

        basicCopper.setLiquidityPool(liquidityPool);
        basicCopper.setReputationTokens(
            address(shittyCopper),
            address(fineCopper)
        );
        fineCopper.setSBT(address(sbt));

        // Transfer some tokens to the user from the deployer (owner)
        basicCopper.transfer(user, 1000 ether);
        assertEq(basicCopper.balanceOf(user), 1000 ether);
        assertEq(shittyCopper.balanceOf(user), 1000 ether);
        assertEq(fineCopper.balanceOf(user), 1000 ether);

        vm.deal(user, 1 ether); // Give user some Ether to pay for gas
        vm.prank(user);
        fineCopper.approve(address(basicCopper), 1000 ether);
    }

    function testTransferWithRounding() public {
        vm.prank(user);

        // Transfer 1.8 ether worth of FineCopper to the recipient
        fineCopper.transfer(recipient, 1.8 ether);

        // Validate FineCopper balances
        assertEq(fineCopper.balanceOf(user), 998.2 ether); // User has 1000 - 1.8 ether
        assertEq(fineCopper.balanceOf(recipient), 0); // FCP is held by the contract itself
        assertEq(fineCopper.balanceOf(address(fineCopper)), 1.8 ether); // FCP is held by the contract itself

        // Validate SBT balances (reputation)
        assertEq(sbt.balanceOf(recipient, 1), 1); // Only 1 ether should be considered due to rounding down
    }

    function testTransferFromWithRounding() public {
        // Set allowance for the owner to transfer on behalf of the user
        vm.prank(user);
        fineCopper.approve(owner, 1.8 ether);

        // Perform transferFrom as the owner on behalf of the user
        vm.prank(owner);
        fineCopper.transferFrom(user, recipient, 1.8 ether);

        // Validate FineCopper balances
        assertEq(fineCopper.balanceOf(user), 998.2 ether); // User has 1000 - 1.8 ether
        assertEq(fineCopper.balanceOf(recipient), 0); // FCP is held by the contract itself
        assertEq(fineCopper.balanceOf(address(fineCopper)), 1.8 ether); // FCP is held by the contract itself

        // Validate SBT balances (reputation)
        assertEq(sbt.balanceOf(recipient, 1), 1); // Only 1 ether should be considered due to rounding down
    }

    function testTransferLessThanOneEtherShouldFail() public {
        vm.prank(user);

        // Expect the transfer to revert with the FineCopper__TransferValueTooLow error
        vm.expectRevert(FineCopper__TransferValueTooLow.selector);
        fineCopper.transfer(recipient, 0.5 ether);

        // Ensure no state changes occurred
        assertEq(fineCopper.balanceOf(user), 1000 ether); // No tokens should have been transferred
        assertEq(fineCopper.balanceOf(recipient), 0 ether); // No tokens should have been received
    }

    function testTransferFromLessThanOneEtherShouldFail() public {
        // Set allowance for the owner to transfer on behalf of the user
        vm.prank(user);
        fineCopper.approve(owner, 0.5 ether);

        // Expect the transferFrom to revert with the FineCopper__TransferValueTooLow error
        vm.expectRevert(FineCopper__TransferValueTooLow.selector);
        vm.prank(owner);
        fineCopper.transferFrom(user, recipient, 0.5 ether);

        // Ensure no state changes occurred
        assertEq(fineCopper.balanceOf(user), 1000 ether); // No tokens should have been transferred
        assertEq(fineCopper.balanceOf(recipient), 0 ether); // No tokens should have been received
    }

    function testTransferFromAfterOneMonthShouldReleaseTokens() public {
        // Perform transferFrom as the owner on behalf of the user
        vm.prank(user);
        fineCopper.transferFrom(user, recipient, 1000 ether);

        assertEq(fineCopper.balanceOf(user), 0);
        assertEq(basicCopper.balanceOf(user), 500 ether);

        // one month later
        vm.warp(block.timestamp + 30 days + 1);

        assertEq(fineCopper.balanceOf(user), 1000 ether);
        assertEq(basicCopper.balanceOf(user), 1000 ether);

        vm.prank(user);
        fineCopper.transferFrom(user, recipient, 1000 ether);

        assertEq(fineCopper.balanceOf(user), 0);
        assertEq(fineCopper.balanceOf(recipient), 0);
        assertEq(basicCopper.balanceOf(user), 500 ether);
        assertEq(basicCopper.balanceOf(recipient), 0);
        assertEq(sbt.balanceOf(recipient, 1), 62); // sqrt(1000) + sqrt(1000) = 62
    }
}
