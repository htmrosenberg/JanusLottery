// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {JanusLottery} from "../src/JanusLottery.sol";
import {ChainAdapter} from "../script/ChainAdapter.s.sol";
import {Deployment} from "../script/Deployment.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
// ┌──────────────────────────────────────────────┐
// │╺┳╸┏━╸┏━┓╺┳╸   ┏┓ ╻ ╻╻ ╻   ╺┳╸╻┏━╸╻┏ ┏━╸╺┳╸┏━┓│
// │ ┃ ┣╸ ┗━┓ ┃    ┣┻┓┃ ┃┗┳┛    ┃ ┃┃  ┣┻┓┣╸  ┃ ┗━┓│
// │ ╹ ┗━╸┗━┛ ╹    ┗━┛┗━┛ ╹     ╹ ╹┗━╸╹ ╹┗━╸ ╹ ┗━┛│
// └──────────────────────────────────────────────┘

contract BuyTicksTest is Test {


    

    JanusLottery public janusLottery;
    ChainAdapter public chainAdapter;
    ChainAdapter.Adaptation public chainAdaptation;

    Deployment private deployment;
    uint256 private ticketPrice;
    uint32 private maximumTickets;
    uint16 private sellingPeriodHours;
    uint256 private jackpotValue;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

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

        vm.startPrank(msg.sender);
        if (block.chainid == chainAdapter.CHAIN_ID_LOCAL()) {
           LinkToken(chainAdaptation.link).mint(msg.sender, LINK_BALANCE);
          
            VRFCoordinatorV2_5Mock(chainAdaptation.vrfCoordinatorV2_5).fundSubscription(chainAdaptation.subscriptionId, LINK_BALANCE);
        }
        LinkToken(chainAdaptation.link).approve(chainAdaptation.vrfCoordinatorV2_5, LINK_BALANCE);
        vm.stopPrank();

        //make jackpot offer
        uint32 fundingHours = deployment.FUNDING_PERIOD_HOURS();
        jackpotValue = deployment.MINIMUM_JACKPOT();
        ticketPrice = 10 gwei;
        maximumTickets = 5;
        sellingPeriodHours = deployment.MAXIMUM_SELLING_PERIOD_HOURS()-1;
        address funder = address(0x1);
        vm.deal(funder, 2 ether);
        vm.prank(funder);
        janusLottery.jackPotOffer{value: jackpotValue}(ticketPrice, maximumTickets, sellingPeriodHours);
        vm.warp(block.timestamp + (fundingHours * 60 * 60));
        vm.roll(block.number + 1);
        janusLottery.performUpkeep("");
        assert(janusLottery.isSelling());
    }

// ┌──────────────────────────────────────────┐
// │┏┓╻┏━┓   ┏┳┓┏━┓┏━┓┏━╸   ┏━┓┏━╸┏━╸┏━╸┏━┓┏━┓│
// │┃┗┫┃ ┃   ┃┃┃┃ ┃┣┳┛┣╸    ┃ ┃┣╸ ┣╸ ┣╸ ┣┳┛┗━┓│
// │╹ ╹┗━┛   ╹ ╹┗━┛╹┗╸┗━╸   ┗━┛╹  ╹  ┗━╸╹┗╸┗━┛│
// └──────────────────────────────────────────┘

    function testNoMoreJackpotOffers() public {
        vm.expectRevert(JanusLottery.JanusLottery__NotInFundingState.selector);
        janusLottery.jackPotOffer{value: jackpotValue}(ticketPrice, maximumTickets, sellingPeriodHours);       
    }

// ┌────────────────┐
// │┏┓ ╻ ╻╻ ╻╻┏┓╻┏━╸│
// │┣┻┓┃ ┃┗┳┛┃┃┗┫┃╺┓│
// │┗━┛┗━┛ ╹ ╹╹ ╹┗━┛│
// └────────────────┘

    function testBuyingNotEnoughAmount() public {
        address funder = address(0x5);
        vm.deal(funder, 1 ether);
        vm.prank(funder);

        vm.expectRevert(JanusLottery.JanusLottery__InvalidTicketPrice.selector);
        janusLottery.buyTicket{ value: ticketPrice - 1 gwei}();
    }

    function testBuyingTooMuchAmount() public {
        address funder = address(0x5);
        vm.deal(funder, 1 ether);
        vm.prank(funder);

        vm.expectRevert(JanusLottery.JanusLottery__InvalidTicketPrice.selector);
        janusLottery.buyTicket{ value: ticketPrice + 1 gwei}();
    }

    function testCorrectAmount() public {
        address buyer = address(0x5);
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);

        janusLottery.buyTicket{ value: ticketPrice}();

        assertEq(janusLottery.getTotalTicketHolders(),1);
        assertEq(janusLottery.getTotalTicketsSale(),ticketPrice);
        assertEq(janusLottery.getTicketHolder(0),address(0x5));
    }

    function testTooManyTickets() public {
        address buyer = address(0x5);
        vm.deal(buyer, 1 ether);
 
        for (uint i = 0; i < 5; i++) {
            vm.prank(buyer);
            janusLottery.buyTicket{ value: ticketPrice}();
        }

        assertEq(janusLottery.getTotalTicketHolders(),5);
        assertEq(janusLottery.getTotalTicketsSale(),ticketPrice*5);
        assertEq(janusLottery.getTicketHolder(0),address(0x5));
        assertEq(janusLottery.getTicketHolder(1),address(0x5));
        assertEq(janusLottery.getTicketHolder(2),address(0x5));
        assertEq(janusLottery.getTicketHolder(3),address(0x5));
        assertEq(janusLottery.getTicketHolder(4),address(0x5));

        vm.expectRevert(JanusLottery.JanusLottery__SoldOut.selector);

        vm.prank(buyer);
        janusLottery.buyTicket{ value: ticketPrice}();
    }

// ┌───────────────────────────────────────────────────────┐
// │┏━╸╻  ┏━┓┏━┓┏━╸   ┏━┓┏━╸╻  ╻  ╻┏┓╻┏━╸   ┏━┓╻ ╻┏━┓┏━┓┏━╸│
// │┃  ┃  ┃ ┃┗━┓┣╸    ┗━┓┣╸ ┃  ┃  ┃┃┗┫┃╺┓   ┣━┛┣━┫┣━┫┗━┓┣╸ │
// │┗━╸┗━╸┗━┛┗━┛┗━╸   ┗━┛┗━╸┗━╸┗━╸╹╹ ╹┗━┛   ╹  ╹ ╹╹ ╹┗━┛┗━╸│
// └───────────────────────────────────────────────────────┘

    function testClosingSellingPhaseTooEarly() public {
        uint32 hoursSelling = sellingPeriodHours - 1;
        vm.warp(block.timestamp + (hoursSelling * 60 * 60));
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = janusLottery.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testClosingSellingPhaseWithoutTicketsSold() public {
        uint256 hoursSelling = sellingPeriodHours;
        vm.warp(block.timestamp + (hoursSelling * 60 * 60));
        vm.roll(block.number + 1);
        assertEq(janusLottery.getTimeLeftSelling(),0);
        (bool upkeepNeeded,) = janusLottery.checkUpkeep("");
        assert(upkeepNeeded);
        assert(janusLottery.isSelling());
        address funder = address(0x1);
        uint256 funder_balance = funder.balance;
        uint256 jackpot = janusLottery.getJackpot();
        janusLottery.performUpkeep("");
        //no sales, return jackpot to funder
        //and restart a new funding phase
        assert(janusLottery.isFunding());
        uint256 funder_balance_after = funder.balance;
        assertEq(funder_balance_after - funder_balance, jackpot);
        assert(!janusLottery.hasJackpot());
        assertEq(janusLottery.getTotalTicketHolders(),0);
    }

    function testClosingSellingPhaseWithTicketsSold() public {
        uint256 hoursSelling = sellingPeriodHours;
    
        address buyer = address(0x5);
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        janusLottery.buyTicket{ value: ticketPrice}();

        vm.warp(block.timestamp + (hoursSelling * 60 * 60));
        vm.roll(block.number + 1);
        assertEq(janusLottery.getTimeLeftSelling(),0);
        (bool upkeepNeeded,) = janusLottery.checkUpkeep("");
        assert(upkeepNeeded);
        assert(janusLottery.isSelling());

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.RequestedRandomNumber(1);

        janusLottery.performUpkeep("");

        assert(janusLottery.isCalculating());


        vm.expectRevert(JanusLottery.JanusLottery__NotSellingTickets.selector);
        janusLottery.buyTicket{ value: ticketPrice}();

        vm.expectRevert(JanusLottery.JanusLottery__NotInFundingState.selector);
        janusLottery.jackPotOffer{value: jackpotValue}(ticketPrice, maximumTickets, sellingPeriodHours);
    }



}
