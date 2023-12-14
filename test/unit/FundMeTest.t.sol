//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsDeployer() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testGetVersion() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assertEq(fundMe.getFunder(0), USER);
    }

    modifier funder() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testWithdrawFailsIfNotOwner() public funder {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funder {
        uint256 ownerBalanceBefore = fundMe.getOwner().balance;
        uint256 contractBalanceBefore = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 ownerBalanceAfter = fundMe.getOwner().balance;
        uint256 contractBalanceAfter = address(fundMe).balance;
        assertEq(ownerBalanceAfter, ownerBalanceBefore + contractBalanceBefore);
        assertEq(contractBalanceAfter, 0);
    }

    function testWithdrawWithMultipleFunders() public funder {
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 ownerBalanceBefore = fundMe.getOwner().balance;
        uint256 contractBalanceBefore = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 ownerBalanceAfter = fundMe.getOwner().balance;
        uint256 contractBalanceAfter = address(fundMe).balance;
        assertEq(ownerBalanceAfter, ownerBalanceBefore + contractBalanceBefore);
        assertEq(contractBalanceAfter, 0);
    }
}
