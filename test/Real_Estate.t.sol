//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Real_estate} from "../src/Real_Estate.sol";
import {MyToken} from "../src/USDT.sol";

contract something is Test {
    Real_estate public real_estate;
    MyToken public usdt;

    address public owner = address(11111);
    address public investor1 = address(121212);
    address public investor2 = address(232323);
    address public fake = address(343434);
    uint public askUSDT = 2000;

    function setUp() public {
        usdt = new MyToken();
        real_estate = new Real_estate(address(usdt));

        usdt.mint(owner, 100000);
        usdt.mint(investor1, 100000);
        usdt.mint(investor2, 100000);
    }

    function testFoo(uint amount) public {
        vm.prank(owner);
        vm.assume(10000 >= amount);
        real_estate.registerProperty(10000, amount, "Ahmedabad");
        assertEq(
            real_estate.balanceOf(owner, 0),
            amount,
            "token should mint same as amount of askUSDT"
        );
    }

    function testFail_registerProperty(uint amount) public {
        vm.prank(owner);
        vm.assume(amount > 10000);
        real_estate.registerProperty(10000, amount, "Ahmedabad");
        vm.expectRevert("You can not ask more fund than your property value");
    }

    function test_Investor(uint amount, uint investorAmount) public {
        vm.assume(investorAmount <= 100000);
        vm.assume(amount >= investorAmount);
        vm.assume(10000 >= amount);

        vm.prank(owner);
        real_estate.registerProperty(10000, amount, "Ahmedabad");

        vm.startPrank(investor1);
        usdt.approve(address(real_estate), investorAmount);
        assertGe(
            usdt.allowance(investor1, address(real_estate)),
            investorAmount,
            "Insufficient Allowance"
        );
        assertGe(usdt.balanceOf(owner), investorAmount, "Insufficient Balance");

        uint before = usdt.balanceOf(owner);
        uint tokensInInvestorWallet = real_estate.balanceOf(investor1, 0);
        real_estate.invest(0, investorAmount);
        assertEq(
            usdt.balanceOf(owner) - before,
            investorAmount,
            "value should be added"
        );
        assertEq(
            real_estate.balanceOf(investor1, 0) + tokensInInvestorWallet,
            investorAmount,
            "tokens should be transfer to investor's account equal to investment"
        );
        vm.stopPrank();
    }

    function test_addreward(uint addreward) public {
        uint beforeUSDT = usdt.balanceOf(address(real_estate));
        vm.assume(addreward <= 500);
        vm.prank(owner);
        real_estate.registerProperty(10000, 2000, "Ahmedabad");

        vm.startPrank(investor1);
        usdt.approve(address(real_estate), 2000);
        real_estate.invest(0, 2000);
        vm.stopPrank();

        vm.startPrank(owner);
        usdt.approve(address(real_estate), 500);
        assertGe(
            usdt.allowance(owner, address(real_estate)),
            addreward,
            "Insufficient Alowance to add rewards"
        );
        assertGe(
            usdt.balanceOf(owner),
            addreward,
            "Insufficient Balance to add rewards"
        );
        real_estate.addReward(0, addreward);
        assertEq(usdt.balanceOf(address(real_estate)) - beforeUSDT, addreward);
        vm.stopPrank();
    }

    function testFail_addreward(uint addreward) public {
        vm.assume(addreward <= 500);

        vm.prank(owner);
        real_estate.registerProperty(10000, 2000, "Ahmedabad");

        vm.startPrank(investor1);
        usdt.approve(address(real_estate), 500);
        real_estate.invest(0, 500);
        vm.stopPrank();

        vm.startPrank(fake);
        usdt.approve(address(real_estate), 500);
        real_estate.addReward(0, addreward);
        vm.expectRevert("Only Owner Can Add Rewards");
        vm.stopPrank();
    }

    function test_getrewards() public {
        vm.prank(owner);
        real_estate.registerProperty(10000, 2000, "Ahmedabad");

        vm.startPrank(investor1);
        usdt.approve(address(real_estate), 2000);
        real_estate.invest(0, 2000);
        console.logUint(usdt.balanceOf(investor1));
        vm.stopPrank();

        vm.startPrank(owner);
        usdt.approve(address(real_estate), 1000);
        real_estate.addReward(0, 1000);
        uint previousbalance = usdt.balanceOf(investor1);
        vm.stopPrank();

        vm.startPrank(investor1);
        vm.warp(block.timestamp + 30 days);
        real_estate.getReward(0);
        uint getReward = (1000 * 2000) / 2000;
        assertEq(usdt.balanceOf(investor1) - previousbalance, getReward, "XYZ");
        vm.stopPrank();
    }

    function testFail_getRewallo() public {
        vm.prank(owner);
        real_estate.registerProperty(10000, 2000, "Ahmedabad");

        vm.startPrank(investor1);
        usdt.approve(address(real_estate), 500);
        real_estate.invest(0, 500);
        console.logUint(usdt.balanceOf(investor1));
        vm.stopPrank();

        vm.startPrank(owner);
        usdt.approve(address(real_estate), 1000);
        real_estate.addReward(0, 1000);
        vm.stopPrank();

        vm.startPrank(fake);
        vm.warp(block.timestamp + 30 days);
        vm.expectRevert("Caller is not an investor");
        real_estate.getReward(0);
        vm.stopPrank();
    }

    function testFail_getRewards() public {
        vm.prank(owner);
        real_estate.registerProperty(10000, 2000, "Ahmedabad");

        vm.startPrank(investor1);
        usdt.approve(address(real_estate), 500);
        real_estate.invest(0, 500);

        vm.stopPrank();

        vm.startPrank(owner);
        usdt.approve(address(real_estate), 1000);
        real_estate.addReward(0, 1000);
        uint previousbalance = usdt.balanceOf(investor1);
        vm.stopPrank();

        vm.startPrank(investor1);
        vm.warp(block.timestamp + 30 days);
        uint getReward = (1000 * 500) / 2000;
        assertEq(usdt.balanceOf(investor1) - previousbalance, getReward, "XYZ");
        vm.expectRevert("You can get rewards after achieving askUSDT amount");
        real_estate.getReward(0);
        vm.stopPrank();
    }
}
