// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/BasicCopper.sol";
import "../src/ShittyCopper.sol";
import "../src/FineCopper.sol";
import "../src/SBT.sol";

contract BasicCopperTest is Test {
    BasicCopper public basicCopper;
    ShittyCopper public shittyCopper;
    FineCopper public fineCopper;
    SBT public sbt;
    address public owner;
    address public user;
    address public recipient;
    address public liquidityPool;

    event ConvertedToFineCopper(address indexed from, uint256 amount);
    event ConvertedToShittyCopper(address indexed from, uint256 amount);

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
        shittyCopper.setSBT(address(sbt));
        fineCopper.setSBT(address(sbt));

        // Transfer some tokens to the user from the deployer (owner)
        basicCopper.transfer(user, 1000 ether);
        shittyCopper.transfer(user, 1000 ether);
        fineCopper.transfer(user, 1000 ether);

        vm.deal(user, 1 ether); // Give user some Ether to pay for gas
        vm.prank(user);
        shittyCopper.approve(address(basicCopper), 1000 ether);
        fineCopper.approve(address(basicCopper), 1000 ether);
    }

    function testTransferToLiquidityPool() public {
        vm.prank(user);

        basicCopper.transfer(liquidityPool, 500 ether);

        // Validate balances
        assertEq(basicCopper.balanceOf(user), 500 ether);
        assertEq(basicCopper.balanceOf(liquidityPool), 500 ether);

        // Validate ShittyCopper and FineCopper balances (burnt)
        assertEq(shittyCopper.balanceOf(user), 500 ether); // 500 ether burnt
        assertEq(fineCopper.balanceOf(user), 500 ether); // 500 ether burnt
    }

    function testTransferFromLiquidityPool() public {
        // First, transfer to the liquidity pool
        vm.prank(user);
        basicCopper.transfer(liquidityPool, 500 ether);

        // Then, transfer from liquidity pool to recipient
        vm.prank(liquidityPool);
        basicCopper.transfer(recipient, 500 ether);

        // Validate balances
        assertEq(basicCopper.balanceOf(recipient), 500 ether);
        assertEq(basicCopper.balanceOf(liquidityPool), 0 ether);

        // Validate ShittyCopper and FineCopper balances (minted)
        assertEq(shittyCopper.balanceOf(recipient), 500 ether); // 500 ether minted
        assertEq(fineCopper.balanceOf(recipient), 500 ether); // 500 ether minted
    }

    function testTransferBetweenUsers() public {
        vm.prank(user);
        basicCopper.transfer(recipient, 300 ether);

        // Validate BasicCopper balances
        assertEq(basicCopper.balanceOf(user), 700 ether);
        assertEq(basicCopper.balanceOf(recipient), 300 ether);

        // Validate ShittyCopper and FineCopper transfers
        assertEq(shittyCopper.balanceOf(user), 700 ether);
        assertEq(fineCopper.balanceOf(user), 700 ether);

        assertEq(shittyCopper.balanceOf(recipient), 300 ether);
        assertEq(fineCopper.balanceOf(recipient), 300 ether);
    }

    function testTransferWithLessShittyCopperThanFineCopper() public {
        vm.prank(user);

        shittyCopper.transfer(address(this), 800 ether);

        assertEq(basicCopper.balanceOf(user), 600 ether);
        assertEq(shittyCopper.balanceOf(user), 200 ether);
        assertEq(fineCopper.balanceOf(user), 1000 ether);

        vm.prank(user);
        basicCopper.transfer(recipient, 400 ether);

        assertEq(basicCopper.balanceOf(user), 200 ether);
        assertEq(basicCopper.balanceOf(recipient), 400 ether);
        assertEq(shittyCopper.balanceOf(user), 0 ether);
        assertEq(fineCopper.balanceOf(user), 400 ether);
    }

    function testTransferOverBalance() public {
        vm.prank(user);

        shittyCopper.transfer(address(this), 800 ether);

        vm.prank(user);
        // should fail with BasicCopper__TransferValueTooHigh
        vm.expectRevert(BasicCopper__TransferValueTooHigh.selector);
        basicCopper.transfer(recipient, 1000 ether);
    }

    function testTransferFrom() public {
        // Set allowance for the owner to transfer on behalf of the user
        vm.prank(user);
        basicCopper.approve(owner, 500 ether);

        // Perform transferFrom as the owner on behalf of the user
        basicCopper.transferFrom(user, recipient, 500 ether);

        // Validate BasicCopper balances
        assertEq(basicCopper.balanceOf(user), 500 ether);
        assertEq(basicCopper.balanceOf(recipient), 500 ether);

        // Validate ShittyCopper and FineCopper transfers
        assertEq(shittyCopper.balanceOf(user), 500 ether);
        assertEq(fineCopper.balanceOf(user), 500 ether);

        assertEq(shittyCopper.balanceOf(recipient), 500 ether);
        assertEq(fineCopper.balanceOf(recipient), 500 ether);
    }

    function testConvertToFineCopper() public {
        vm.startPrank(user);

        // Convert 100 ShittyCopper to FineCopper
        uint256 amountToConvert = 100 ether;
        uint256 initialShittyCopperBalance = shittyCopper.balanceOf(user);
        uint256 initialFineCopperBalance = fineCopper.balanceOf(user);

        basicCopper.convertToFineCopper(amountToConvert);

        // Validate balances after conversion
        assertEq(
            shittyCopper.balanceOf(user),
            initialShittyCopperBalance - amountToConvert
        );
        assertEq(
            fineCopper.balanceOf(user),
            initialFineCopperBalance + amountToConvert
        );

        // Validate the event was emitted
        vm.expectEmit(true, true, true, true);
        emit ConvertedToFineCopper(user, amountToConvert);
        basicCopper.convertToFineCopper(amountToConvert);

        vm.stopPrank();
    }

    function testConvertToFineCopper_NotEnoughBalance() public {
        vm.startPrank(user);

        // Try converting more ShittyCopper than the user has
        uint256 amountToConvert = 1500 ether;

        vm.expectRevert(BasicCopper__NotEnoughBalance.selector);
        basicCopper.convertToFineCopper(amountToConvert);

        vm.stopPrank();
    }

    function testConvertToFineCopper_ZeroAmount() public {
        vm.startPrank(user);

        // Try converting zero ShittyCopper
        vm.expectRevert(BasicCopper__ZeroAmount.selector);
        basicCopper.convertToFineCopper(0);

        vm.stopPrank();
    }

    function testConvertToShittyCopper() public {
        vm.startPrank(user);

        // Convert 100 FineCopper to ShittyCopper
        uint256 amountToConvert = 100 ether;
        uint256 initialShittyCopperBalance = shittyCopper.balanceOf(user);
        uint256 initialFineCopperBalance = fineCopper.balanceOf(user);

        basicCopper.convertToShittyCopper(amountToConvert);

        // Validate balances after conversion
        assertEq(
            shittyCopper.balanceOf(user),
            initialShittyCopperBalance + amountToConvert
        );
        assertEq(
            fineCopper.balanceOf(user),
            initialFineCopperBalance - amountToConvert
        );

        // Validate the event was emitted
        vm.expectEmit(true, true, true, true);
        emit ConvertedToShittyCopper(user, amountToConvert);
        basicCopper.convertToShittyCopper(amountToConvert);

        vm.stopPrank();
    }

    function testConvertToShittyCopper_NotEnoughBalance() public {
        vm.startPrank(user);

        // Try converting more FineCopper than the user has
        uint256 amountToConvert = 1500 ether;

        vm.expectRevert(BasicCopper__NotEnoughBalance.selector);
        basicCopper.convertToShittyCopper(amountToConvert);

        vm.stopPrank();
    }

    function testConvertToShittyCopper_ZeroAmount() public {
        vm.startPrank(user);

        // Try converting zero FineCopper
        vm.expectRevert(BasicCopper__ZeroAmount.selector);
        basicCopper.convertToShittyCopper(0);

        vm.stopPrank();
    }

    // Allow this to receive ERC1155 tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    // Allow this to receive ERC1155 tokens
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
