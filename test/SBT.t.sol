// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/SBT.sol";
import "../src/ShittyCopper.sol";
import "../src/FineCopper.sol";
import "../src/BasicCopper.sol";

contract SBTTest is Test {
    SBT public sbt;
    ShittyCopper public shittyCopper;
    FineCopper public fineCopper;
    BasicCopper public basicCopper;
    address public owner;
    address public user;
    address public recipient;

    event DownVoted(address indexed from, uint256 amount);
    event UpVoted(address indexed from, uint256 amount);

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        recipient = address(0x2);

        basicCopper = new BasicCopper();
        shittyCopper = new ShittyCopper(address(basicCopper));
        fineCopper = new FineCopper(address(basicCopper));
        sbt = new SBT(address(shittyCopper), address(fineCopper));

        basicCopper.setReputationTokens(
            address(shittyCopper),
            address(fineCopper)
        );
        shittyCopper.setSBT(address(sbt));
        fineCopper.setSBT(address(sbt));

        basicCopper.transfer(user, 1000 ether);

        vm.deal(user, 1 ether); // Give user some Ether to pay for gas
    }

    function testDownVote() public {
        vm.prank(user);

        // Expect the DownVoted event to be emitted with the correct parameters
        vm.expectEmit(true, true, true, true);
        emit DownVoted(recipient, 100 ether);

        shittyCopper.transfer(recipient, 100 ether);

        // Validate SBT balance after downVote
        assertEq(sbt.balanceOf(recipient, 0), 10);
    }

    function testUpVote() public {
        vm.prank(user);

        // Expect the UpVoted event to be emitted with the correct parameters
        vm.expectEmit(true, true, true, true);
        emit UpVoted(recipient, 100 ether);

        fineCopper.transfer(recipient, 100 ether);

        // Validate SBT balance after upVote
        assertEq(sbt.balanceOf(recipient, 1), 10);
    }

    function testOnlyShittyCopperCanDownVote() public {
        vm.expectRevert(SBT__NotShittyCopper.selector);
        sbt.downVote(recipient, 100 ether);
    }

    function testOnlyFineCopperCanUpVote() public {
        vm.expectRevert(SBT__NotFineCopper.selector);
        sbt.upVote(recipient, 100 ether);
    }

    function testDownVoteAmountCalculation() public {
        uint256 amount = 200 ether;

        vm.prank(user);
        shittyCopper.transfer(recipient, amount);

        assertEq(sbt.balanceOf(recipient, 0), 14);
    }

    function testUpVoteAmountCalculation() public {
        uint256 amount = 300 ether;

        vm.prank(user);
        fineCopper.transfer(recipient, amount);

        assertEq(sbt.balanceOf(recipient, 1), 17);
    }

    function testSoulboundSafeTransferFrom() public {
        vm.expectRevert(SBT__Soulbound.selector);

        vm.prank(user);
        sbt.safeTransferFrom(user, recipient, 0, 10, "");
    }

    function testSoulboundSafeBatchTransferFrom() public {
        vm.expectRevert(SBT__Soulbound.selector);

        vm.prank(user);
        sbt.safeBatchTransferFrom(user, recipient, new uint256[](1), new uint256[](1), "");
    }
}
