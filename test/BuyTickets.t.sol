// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {JanusLottery} from "../src/JanusLottery.sol";
import {ChainAdapter} from "../script/ChainAdapter.sol";
import {Deployment} from "../script/Deployment.s.sol";


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

/*        vm.startPrank(msg.sender);
        if (block.chainid == LOCAL_CHAIN_ID) {
            link.mint(msg.sender, LINK_BALANCE);
          
            VRFCoordinatorV2_5Mock(chainAdaptation.vrfCoordinatorV2_5).fundSubscription(chainAdaptation.subscriptionId, LINK_BALANCE);
        }
        link.approve(chainAdaptation.vrfCoordinatorV2_5, LINK_BALANCE);
        vm.stopPrank();*/

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
        address funder = address(0x5);
        vm.deal(funder, 1 ether);
        vm.prank(funder);

        janusLottery.buyTicket{ value: ticketPrice}();

        assertEq(janusLottery.getTotalTicketHolders(),1);
        assertEq(janusLottery.getTotalTicketsSale(),ticketPrice);
        assertEq(janusLottery.getTicketHolder(0),address(0x5));
    }

    function testTooManyTickets() public {
        address funder = address(0x5);
        vm.deal(funder, 1 ether);
 
        for (uint i = 0; i < 5; i++) {
            vm.prank(funder);
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

        vm.prank(funder);
        janusLottery.buyTicket{ value: ticketPrice}();
    }

// ┌───────────────────────────────────────────────────────┐
// │┏━╸╻  ┏━┓┏━┓┏━╸   ┏━┓┏━╸╻  ╻  ╻┏┓╻┏━╸   ┏━┓╻ ╻┏━┓┏━┓┏━╸│
// │┃  ┃  ┃ ┃┗━┓┣╸    ┗━┓┣╸ ┃  ┃  ┃┃┗┫┃╺┓   ┣━┛┣━┫┣━┫┗━┓┣╸ │
// │┗━╸┗━╸┗━┛┗━┛┗━╸   ┗━┛┗━╸┗━╸┗━╸╹╹ ╹┗━┛   ╹  ╹ ╹╹ ╹┗━┛┗━╸│
// └───────────────────────────────────────────────────────┘

    function testClosingSellingPhaseTooEarly() public {

    }

    function testClosingSellingPhaseWithoutTicketsSold() public {
        
    }

    function testClosingSellingPhase() public {
        
    }

}
