// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {JanusLottery} from "../src/JanusLottery.sol";
import {ChainAdapter} from "../script/ChainAdapter.sol";
import {Deployment} from "../script/Deployment.s.sol";


contract JanusLotteryTest is Test {


    uint16 constant ZERO_HOURS = 0;
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

    JanusLottery public janusLottery;
    ChainAdapter public chainAdapter;
    ChainAdapter.Adaptation public chainAdaptation;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    Deployment deployment;

// ┌───────────────┐
// │┏━┓┏━╸╺┳╸╻ ╻┏━┓│
// │┗━┓┣╸  ┃ ┃ ┃┣━┛│
// │┗━┛┗━╸ ╹ ┗━┛╹  │
// └───────────────┘

    function setUp() external {
        deployment = new Deployment();
        (janusLottery, chainAdapter) = deployment.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        chainAdaptation = chainAdapter.getAdaptation();

/*        vm.startPrank(msg.sender);
        if (block.chainid == LOCAL_CHAIN_ID) {
            link.mint(msg.sender, LINK_BALANCE);
          
            VRFCoordinatorV2_5Mock(chainAdaptation.vrfCoordinatorV2_5).fundSubscription(chainAdaptation.subscriptionId, LINK_BALANCE);
        }
        link.approve(chainAdaptation.vrfCoordinatorV2_5, LINK_BALANCE);
        vm.stopPrank();*/
    }

    uint256 private constant MINIMUM_VALUE = 1 gwei;
    uint16 private constant MINIMUM_TICKETS = 1;

    function testJackpotTooSmallForJackpot() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT() - 1 gwei;
        vm.expectRevert(JanusLottery.JanusLottery__JackpotTooSmall.selector);
        janusLottery.jackPotOffer{value: jackpotValue}(
            MINIMUM_VALUE, 
            MINIMUM_TICKETS, 
            sellingPeriod);
    }

    function testTicketSellingPeriodTooShortForJackpot() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS() - 1;
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();
        vm.expectRevert(JanusLottery.JanusLottery__TicketSellingPeriodTooShort.selector);
        janusLottery.jackPotOffer{value: jackpotValue}(
            MINIMUM_VALUE, 
            MINIMUM_TICKETS, 
            sellingPeriod);
    }

    function testTicketSellingPeriodTooLongForJackpot() public {
        uint16 sellingPeriod = deployment.MAXIMUM_SELLING_PERIOD_HOURS() + 1;
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();
        vm.expectRevert(JanusLottery.JanusLottery__TicketSellingPeriodTooLong.selector);
        janusLottery.jackPotOffer{value: jackpotValue}(
            MINIMUM_VALUE, 
            MINIMUM_TICKETS, 
            sellingPeriod);
    }

    function testMaximumTicketsTooSmallForJackpot() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();
        vm.expectRevert(JanusLottery.JanusLottery__MaximumTicketsTooSmall.selector);
        janusLottery.jackPotOffer{value: jackpotValue}(
            MINIMUM_VALUE, 
            MINIMUM_TICKETS - 1, 
            sellingPeriod);
    }

    function testInvalidTicketPriceForJackpot() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();
        vm.expectRevert(JanusLottery.JanusLottery__InvalidTicketPrice.selector);
        janusLottery.jackPotOffer{value: jackpotValue}(
            0, 
            MINIMUM_TICKETS, 
            sellingPeriod);        
    }

    function testCorrectJackpotOffer() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(address(this), jackpotValue, MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        assertEq(janusLottery.getFunder(), address(this));
        assertEq(janusLottery.getJackpot(), jackpotValue);
        assertEq(janusLottery.getMaximumTickets(), MINIMUM_TICKETS);
        assertEq(janusLottery.getSellingPeriodHours(), sellingPeriod);
        assertEq(janusLottery.getTicketPrice(), MINIMUM_VALUE);
        assert(janusLottery.isFunding());
    }

    function testRejectSameJackpotOffer() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();

        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        vm.expectRevert(JanusLottery.JanusLottery__OfferRejected.selector);

        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);
    }

    function testRejectShorterJackpotOffer() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();

        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod+1);

        vm.expectRevert(JanusLottery.JanusLottery__OfferRejected.selector);
        // One_Hour < Two_Hours
        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);
    }

    function testRejectMoreExpensiveJackpotOffer() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();

        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        vm.expectRevert(JanusLottery.JanusLottery__OfferRejected.selector);
  
        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE + 1, MINIMUM_TICKETS, sellingPeriod);
    }

    function testRejectMoreTicketsJackpotOffer() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();

        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        vm.expectRevert(JanusLottery.JanusLottery__OfferRejected.selector);
  
        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS + 1, sellingPeriod);
    }

    function testAcceptBiggerJackpotOffer() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 firstJackpotValue = deployment.MINIMUM_JACKPOT();
        uint256 secondJackpotValue = deployment.MINIMUM_JACKPOT() + 1 gwei;

        address first_funder = address(0x1);
        address second_funder = address(0x2);

        vm.deal(first_funder, 2 ether);
        vm.deal(second_funder, 3 ether);

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(first_funder, firstJackpotValue, MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        vm.prank(first_funder);
        janusLottery.jackPotOffer{value: firstJackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        assertEq(first_funder.balance, 2 ether - firstJackpotValue);
        assertEq(address(janusLottery).balance, firstJackpotValue);

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(second_funder, secondJackpotValue, MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        vm.prank(second_funder);
        janusLottery.jackPotOffer{value: secondJackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, sellingPeriod);

        assertEq(first_funder.balance, 2 ether);
        assertEq(second_funder.balance, 3 ether - secondJackpotValue);
        assertEq(address(janusLottery).balance, secondJackpotValue);

        assertEq(janusLottery.getFunder(), second_funder);
        assertEq(janusLottery.getJackpot(), secondJackpotValue);
    }

    function testAcceptLongerJackpotOffer() public {
        uint16 firstSellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint16 secondSellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS()+1;
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();
        
        address first_funder = address(0x1);
        address second_funder = address(0x2);

        vm.deal(first_funder, 2 ether);
        vm.deal(second_funder, 3 ether);

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(first_funder, jackpotValue, MINIMUM_VALUE, MINIMUM_TICKETS, firstSellingPeriod);

        vm.prank(first_funder);
        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, firstSellingPeriod);

        assertEq(first_funder.balance, 2 ether - jackpotValue);
        assertEq(address(janusLottery).balance, jackpotValue);

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(second_funder,jackpotValue, MINIMUM_VALUE, MINIMUM_TICKETS, secondSellingPeriod);

        vm.prank(second_funder);
        janusLottery.jackPotOffer{value: jackpotValue}(MINIMUM_VALUE, MINIMUM_TICKETS, secondSellingPeriod);

        assertEq(first_funder.balance, 2 ether);
        assertEq(second_funder.balance, 3 ether - jackpotValue);
        assertEq(address(janusLottery).balance, jackpotValue);

        assertEq(janusLottery.getFunder(), second_funder);
        assertEq(janusLottery.getJackpot(), jackpotValue);
    }

    function testAcceptCheaperJackpotOffer() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();
        uint256 firstTicketPrice = MINIMUM_VALUE + 1 gwei;
        uint256 secondTicketPrice = MINIMUM_VALUE;
        
        address first_funder = address(0x1);
        address second_funder = address(0x2);

        vm.deal(first_funder, 2 ether);
        vm.deal(second_funder, 3 ether);

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(first_funder, jackpotValue, firstTicketPrice, MINIMUM_TICKETS, sellingPeriod);

        vm.prank(first_funder);
        janusLottery.jackPotOffer{value: jackpotValue}(firstTicketPrice, MINIMUM_TICKETS, sellingPeriod);

        assertEq(first_funder.balance, 2 ether - jackpotValue);
        assertEq(address(janusLottery).balance, jackpotValue);

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(second_funder, jackpotValue, secondTicketPrice, MINIMUM_TICKETS, sellingPeriod);

        vm.prank(second_funder);
        janusLottery.jackPotOffer{value: jackpotValue}(secondTicketPrice, MINIMUM_TICKETS, sellingPeriod);

        assertEq(first_funder.balance, 2 ether);
        assertEq(second_funder.balance, 3 ether - jackpotValue);
        assertEq(address(janusLottery).balance, jackpotValue);
        assertEq(janusLottery.getTicketPrice(), secondTicketPrice);
        assertEq(janusLottery.getFunder(), second_funder);
        assertEq(janusLottery.getJackpot(), jackpotValue);
    }

    function testAcceptBetterChanceJackpotOffer() public {
        uint16 sellingPeriod = deployment.MINIMUM_SELLING_PERIOD_HOURS();
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();
        uint256 ticketPrice = MINIMUM_VALUE;
        uint32 firstTickets = MINIMUM_TICKETS + 1;
        uint32 secondTickets = MINIMUM_TICKETS;
        
        address first_funder = address(0x1);
        address second_funder = address(0x2);

        vm.deal(first_funder, 2 ether);
        vm.deal(second_funder, 3 ether);

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(first_funder, jackpotValue, ticketPrice, firstTickets, sellingPeriod);

        vm.prank(first_funder);
        janusLottery.jackPotOffer{value: jackpotValue}(ticketPrice, firstTickets, sellingPeriod);

        assertEq(first_funder.balance, 2 ether - jackpotValue);
        assertEq(address(janusLottery).balance, jackpotValue);

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.JackPotOfferAccepted(second_funder, jackpotValue, ticketPrice, secondTickets, sellingPeriod);

        vm.prank(second_funder);
        janusLottery.jackPotOffer{value: jackpotValue}(ticketPrice, secondTickets, sellingPeriod);

        assertEq(first_funder.balance, 2 ether);
        assertEq(second_funder.balance, 3 ether - jackpotValue);
        assertEq(address(janusLottery).balance, jackpotValue);
        assertEq(janusLottery.getTicketPrice(), ticketPrice);
        assertEq(janusLottery.getFunder(), second_funder);
        assertEq(janusLottery.getJackpot(), jackpotValue);
    }
}
