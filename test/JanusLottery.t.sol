// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {JanusLottery} from "../src/JanusLottery.sol";

contract JanusLotteryTest is Test {

    uint16 constant Zero_Hours = 0;
    uint16 constant One_Hour = 1;
    uint16 constant Two_Hours = 2;
    uint16 constant One_Day = 24;
    uint32 constant Zero_Tickets = 0;
    uint256 constant Zero_Price = 0;

    uint256 constant One_Gwei = 1 gwei;
    uint256 constant One_Wei = 1 wei;
    uint256 constant One_ETH = 1 ether;
    uint256 constant Zero_ETH = 0 ether;
    uint16 constant Promille_999 = 999;
    uint16 constant Promille_1000 = 1000;
    uint32 constant Thousand_Tickets = 1000;
    uint32 constant Hunderd_Tickets = 100;


    function test_DeploymentInvalidFee() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(One_Hour,One_Hour,One_Hour,One_ETH,Promille_1000);
    }

    function test_DeploymentInvalidMinimumJackpot() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(One_Hour,One_Hour,One_Hour,Zero_ETH,Promille_999);
    }

    function test_DeploymentInvalidFundingPeriod() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(One_Hour,One_Hour,Zero_Hours,One_ETH,Promille_999);
    }

    function test_DeploymentInvalidMinimumSellingPeriod() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(Zero_Hours,One_Hour,One_Hour,One_ETH,Promille_999);
    }


    function test_DeploymentInvalidMaximumSellingPeriod() public {
        vm.expectRevert(JanusLottery.JanusLottery__InvalidConstructionParameter.selector);
        new JanusLottery(   Two_Hours,
                            One_Hour,
                            One_Hour,
                            One_ETH,
                            Promille_999);
    }

    function test_DeploymentCorrect() public {
        JanusLottery janusLottery = new JanusLottery(   
            One_Hour,
            Two_Hours,
            One_Hour,
            One_ETH,
            Promille_999);
        
        assertEq(janusLottery.getOwner(),address(this));
        assertEq(janusLottery.getFeePromille(),Promille_999);
        assertEq(janusLottery.getFundingPeriodHours(),One_Hour);
        assertEq(janusLottery.getFundingPeriodHours(),One_Hour);
        assertEq(janusLottery.getMinimumSellingPeriodHours(),One_Hour);
        assertEq(janusLottery.getMaximumSellingPeriodHours(),Two_Hours);
        assertEq(janusLottery.getMinimumJackotPot(),One_ETH);
        assert(janusLottery.isFunding());
    }

    function testJackpotTooSmallForJackpot() public  {
        JanusLottery janusLottery = new JanusLottery(   
            One_Hour,
            One_Day,
            One_Hour,
            One_ETH,
            Promille_999);
        vm.expectRevert(JanusLottery.JanusLottery__JackpotTooSmall.selector);
        //One_Wei < One_ETH
        janusLottery.jackPotOffer{value: One_Wei}(One_Wei, Thousand_Tickets, Two_Hours);   
    }
 
    function testTicketSellingPeriodTooShortForJackpot() public  {
        JanusLottery janusLottery = new JanusLottery(   
            Two_Hours,
            One_Day,
            One_Hour,
            One_ETH,
            Promille_999);
        vm.expectRevert(JanusLottery.JanusLottery__TicketSellingPeriodTooShort.selector);
        //One_Hours < Two_Hours
        janusLottery.jackPotOffer{value: One_ETH}(One_Wei, Thousand_Tickets, One_Hour);   
    }

    function testTicketSellingPeriodTooLongForJackpot() public  {
        JanusLottery janusLottery = new JanusLottery(   
            One_Hour,
            Two_Hours,
            One_Hour,
            One_ETH,
            Promille_999);
        vm.expectRevert(JanusLottery.JanusLottery__TicketSellingPeriodTooLong.selector);
        //One_Day > Two_Hours
        janusLottery.jackPotOffer{value: One_ETH}(One_Wei, Thousand_Tickets, One_Day);   
    }


   function testMaximumTicketsTooSmallForJackpot() public  {
        JanusLottery janusLottery = new JanusLottery(   
            One_Hour,
            One_Day,
            One_Hour,
            One_ETH,
            Promille_999);
        vm.expectRevert(JanusLottery.JanusLottery__MaximumTicketsTooSmall.selector);
        //Zero_Tickets == 0
        janusLottery.jackPotOffer{value: One_ETH}(One_Wei, Zero_Tickets, Two_Hours);   
    }

   function testInvalidTicketPriceForJackpot() public  {
        JanusLottery janusLottery = new JanusLottery(   
            One_Hour,
            One_Day,
            One_Hour,
            One_ETH,
            Promille_999);
        vm.expectRevert(JanusLottery.JanusLottery__InvalidTicketPrice.selector);
        //Zero_ETH == 0
        janusLottery.jackPotOffer{value: One_ETH}(Zero_ETH, Thousand_Tickets, Two_Hours);   
    }

    
   function testCorrectJackpotOffer() public  {
        JanusLottery janusLottery = new JanusLottery(   
            One_Hour,
            One_Day,
            One_Hour,
            One_ETH,
            Promille_999);

        janusLottery.jackPotOffer{value: One_ETH}(One_Gwei, Thousand_Tickets, Two_Hours);

        assertEq(janusLottery.getFunder(), address(this));
        assertEq(janusLottery.getJackpot(), One_ETH);
        assertEq(janusLottery.getMaximumTickets(), Thousand_Tickets);
        assertEq(janusLottery.getSellingPeriodHours(), Two_Hours);
        assertEq(janusLottery.getTicketPrice(), One_Gwei);
        assert(janusLottery.isFunding());   
    }

}
