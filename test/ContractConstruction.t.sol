// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {JanusLottery} from "../src/JanusLottery.sol";

contract ContractConstructionTest is Test {
    uint16 constant Zero_Hours = 0;
    uint16 constant One_Hour = 1;
    uint16 constant Two_Hours = 2;
    uint16 constant One_Day = 24;
    uint32 constant Zero_Tickets = 0;
    uint256 constant Zero_Price = 0;

    uint256 constant Five_Gwei = 5 gwei;
    uint256 constant One_Gwei = 1 gwei;
    uint256 constant One_Wei = 1 wei;
    uint256 constant One_ETH = 1 ether;
    uint256 constant Two_ETH = 2 ether;
    uint256 constant Zero_ETH = 0 ether;
    uint16 constant Promille_999 = 999;
    uint16 constant Promille_1000 = 1000;
    uint32 constant Thousand_Tickets = 1000;
    uint32 constant Hundred_Tickets = 100;
    address constant VFR_ADDRESS = address(0x234);
    uint256 constant SUBSCRIPTION_ID = 1234;
    bytes32 constant GASLANE = "0x32";
    uint32 constant CALLBACK_GASLIMIT = 1234;

    function test_DeploymentInvalidFee() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(
            One_Hour,
            One_Hour,
            One_Hour,
            One_ETH,
            Promille_1000,
            VFR_ADDRESS,
            SUBSCRIPTION_ID,
            GASLANE,
            CALLBACK_GASLIMIT
        );
    }

    function test_DeploymentInvalidMinimumJackpot() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(
            One_Hour,
            One_Hour,
            One_Hour,
            Zero_ETH,
            Promille_999,
            VFR_ADDRESS,
            SUBSCRIPTION_ID,
            GASLANE,
            CALLBACK_GASLIMIT
        );
    }

    function test_DeploymentInvalidFundingPeriod() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(
            One_Hour,
            One_Hour,
            Zero_Hours,
            One_ETH,
            Promille_999,
            VFR_ADDRESS,
            SUBSCRIPTION_ID,
            GASLANE,
            CALLBACK_GASLIMIT
        );
    }

    function test_DeploymentInvalidMinimumSellingPeriod() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(
            Zero_Hours,
            One_Hour,
            One_Hour,
            One_ETH,
            Promille_999,
            VFR_ADDRESS,
            SUBSCRIPTION_ID,
            GASLANE,
            CALLBACK_GASLIMIT
        );
    }

    function test_DeploymentInvalidMaximumSellingPeriod() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(
            Two_Hours,
            One_Hour,
            One_Hour,
            One_ETH,
            Promille_999,
            VFR_ADDRESS,
            SUBSCRIPTION_ID,
            GASLANE,
            CALLBACK_GASLIMIT
        );
    }

    function test_DeploymentCorrect() public {
        JanusLottery janusLottery = new JanusLottery(
            One_Hour,
            Two_Hours,
            One_Hour,
            One_ETH,
            Promille_999,
            VFR_ADDRESS,
            SUBSCRIPTION_ID,
            GASLANE,
            CALLBACK_GASLIMIT
        );

        assertEq(janusLottery.getOwner(), address(this));
        assertEq(janusLottery.getFeePromille(), Promille_999);
        assertEq(janusLottery.getFundingPeriodHours(), One_Hour);
        assertEq(janusLottery.getFundingPeriodHours(), One_Hour);
        assertEq(janusLottery.getMinimumSellingPeriodHours(), One_Hour);
        assertEq(janusLottery.getMaximumSellingPeriodHours(), Two_Hours);
        assertEq(janusLottery.getMinimumJackotPot(), One_ETH);
        assert(janusLottery.isFunding());
    }
}
