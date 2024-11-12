// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;


import {Test} from "forge-std/Test.sol";
import {JanusLottery} from "../src/JanusLottery.sol";
import {ChainAdapter} from "../script/ChainAdapter.s.sol";
import {Deployment} from "../script/Deployment.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

// ┌────────────────────────────────────────────────┐
// │┏━┓╻┏━╸╻┏    ┏━┓   ╻ ╻╻┏┓╻┏┓╻┏━╸┏━┓        ╺┓   │
// │┣━┛┃┃  ┣┻┓   ┣━┫   ┃╻┃┃┃┗┫┃┗┫┣╸ ┣┳┛    ╹╺━╸ ┃   │
// │╹  ╹┗━╸╹ ╹   ╹ ╹   ┗┻┛╹╹ ╹╹ ╹┗━╸╹┗╸    ┛   ╺┛   │
// └────────────────────────────────────────────────┘

contract PickWinnerTest is Test {

    JanusLottery public janusLottery;
    ChainAdapter public chainAdapter;
    ChainAdapter.Adaptation public chainAdaptation;

    Deployment private deployment;
    uint256 private ticketPrice;
    uint32 private maximumTickets;
    uint16 private sellingPeriodHours;
    uint256 private jackpotValue;
    address private funder;
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
        maximumTickets = 15;
        sellingPeriodHours = deployment.MAXIMUM_SELLING_PERIOD_HOURS()-1;
        funder = address(0x1);
        vm.deal(funder, 2 ether);
        vm.prank(funder);
        janusLottery.jackPotOffer{value: jackpotValue}(ticketPrice, maximumTickets, sellingPeriodHours);
        vm.warp(block.timestamp + (fundingHours * 60 * 60));
        vm.roll(block.number + 1);
        janusLottery.performUpkeep("");
        assert(janusLottery.isSelling());

        uint256 hoursSelling = sellingPeriodHours;

        for (uint i = 5; i < 16; i++) {
            address buyer = address(uint160(0x00 + i));
            vm.deal(buyer, 1 ether);
            vm.prank(buyer);
            janusLottery.buyTicket{ value: ticketPrice}();
        }    

        vm.warp(block.timestamp + (hoursSelling * 60 * 60));
        vm.roll(block.number + 1);
        assertEq(janusLottery.getTimeLeftSelling(),0);
        (bool upkeepNeeded,) = janusLottery.checkUpkeep("");
        assert(upkeepNeeded);
        assert(janusLottery.isSelling());

       


    }
    
    
// ┌─────────────────────────────────────────────┐
// │┏┓╻┏━┓   ╻ ╻╻┏┓╻┏┓╻╻┏┓╻┏━╸   ╺┳╸╻┏━╸╻┏ ┏━╸╺┳╸│
// │┃┗┫┃ ┃   ┃╻┃┃┃┗┫┃┗┫┃┃┗┫┃╺┓    ┃ ┃┃  ┣┻┓┣╸  ┃ │
// │╹ ╹┗━┛   ┗┻┛╹╹ ╹╹ ╹╹╹ ╹┗━┛    ╹ ╹┗━╸╹ ╹┗━╸ ╹ │
// └─────────────────────────────────────────────┘
// ┌─────────────────────────────────────────────┐
// │┏━╸╻ ╻┏┓╻╺┳┓┏━╸┏━┓   ┏━╸┏━╸╺┳╸┏━┓   ┏━┓╻  ╻  │
// │┣╸ ┃ ┃┃┗┫ ┃┃┣╸ ┣┳┛   ┃╺┓┣╸  ┃ ┗━┓   ┣━┫┃  ┃  │
// │╹  ┗━┛╹ ╹╺┻┛┗━╸╹┗╸   ┗━┛┗━╸ ╹ ┗━┛   ╹ ╹┗━╸┗━╸│
// └─────────────────────────────────────────────┘

    function testPickNoTicketWinner() public {


        vm.expectEmit(true, false, false, true);
        emit JanusLottery.RequestedRandomNumber(1);

        janusLottery.performUpkeep("");

        assert(janusLottery.isCalculating());

        //Funder get the jackpot back + the tickets sale - fee
        uint256 fee_prize= ((janusLottery.getTotalTicketsSale()+janusLottery.getJackpot())*janusLottery.getFeePromille()) / 1000;
        uint256 funder_prize = ((janusLottery.getJackpot()+janusLottery.getTotalTicketsSale()) * (1000-janusLottery.getFeePromille())) / 1000;
        uint256 pre_balance = funder.balance;
        uint256 owner_pre_balance = janusLottery.getOwner().balance;
        
        vm.expectEmit(true, false, false, true);
        emit JanusLottery.FunderWon(funder,funder_prize);

        VRFCoordinatorV2_5Mock(chainAdaptation.vrfCoordinatorV2_5).fulfillRandomWords(1, address(janusLottery));
        uint256 post_balance = funder.balance;
        uint256 owner_post_balance = janusLottery.getOwner().balance;

        //funder should have received his price: jackpot + tickets - fee
        assertEq(post_balance,pre_balance+funder_prize);
        assertEq(owner_post_balance,owner_pre_balance+fee_prize);
        assert(janusLottery.isFunding());        
        assertEq(janusLottery.getTotalTicketHolders(),0);
        assertEq(janusLottery.getTotalTicketsSale(),0);

        //ticket buyers should have received nothing
        for (uint i = 5; i < 15; i++) {
            address buyer = address(uint160(0x00 + i));
            assertEq(buyer.balance,1 ether - ticketPrice);
        }
    }


// ┌────────────────────────────────────────────────────────┐
// │╺┳╸╻┏━╸╻┏ ┏━╸╺┳╸   ┏━╸┏━╸╺┳╸┏━┓    ┏┓┏━┓┏━╸╻┏ ┏━┓┏━┓╺┳╸╻│
// │ ┃ ┃┃  ┣┻┓┣╸  ┃    ┃╺┓┣╸  ┃ ┗━┓     ┃┣━┫┃  ┣┻┓┣━┛┃ ┃ ┃ ╹│
// │ ╹ ╹┗━╸╹ ╹┗━╸ ╹    ┗━┛┗━╸ ╹ ┗━┛   ┗━┛╹ ╹┗━╸╹ ╹╹  ┗━┛ ╹ ╹│
// └────────────────────────────────────────────────────────┘
// ┌───────────────────────────────────────────────────┐
// │┏━╸╻ ╻┏┓╻╺┳┓┏━╸┏━┓   ┏━╸┏━╸╺┳╸┏━┓   ┏━┓┏━┓╻  ┏━╸┏━┓│
// │┣╸ ┃ ┃┃┗┫ ┃┃┣╸ ┣┳┛   ┃╺┓┣╸  ┃ ┗━┓   ┗━┓┣━┫┃  ┣╸ ┗━┓│
// │╹  ┗━┛╹ ╹╺┻┛┗━╸╹┗╸   ┗━┛┗━╸ ╹ ┗━┛   ┗━┛╹ ╹┗━╸┗━╸┗━┛│
// └───────────────────────────────────────────────────┘
    function testPickTicketWinner() public {

        address winner = address(0x666);
        vm.deal(winner, 1 ether);
        vm.startPrank(winner);
        janusLottery.buyTicket{ value: ticketPrice}();
        vm.stopPrank();

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.RequestedRandomNumber(1);
        janusLottery.performUpkeep("");

        assert(janusLottery.isCalculating());

        //Funder get the jackpot back + the tickets sale - fee
        uint256 funder_prize = (janusLottery.getTotalTicketsSale() * (1000-janusLottery.getFeePromille())) / 1000;
        uint256 ticket_prize = (janusLottery.getJackpot() * (1000-janusLottery.getFeePromille())) / 1000;
        uint256 fee_prize= ((janusLottery.getTotalTicketsSale()+janusLottery.getJackpot())*janusLottery.getFeePromille()) / 1000;

        uint256 owner_pre_balance = janusLottery.getOwner().balance;
        uint256 winner_pre_balance = winner.balance;
        uint256 funder_pre_balance = funder.balance;
        vm.expectEmit(true, false, false, true);
        emit JanusLottery.TicketWon(winner,ticket_prize);

        VRFCoordinatorV2_5Mock(chainAdaptation.vrfCoordinatorV2_5).fulfillRandomWords(1, address(janusLottery));
        uint256 winner_post_balance = winner.balance;
        uint256 funder_post_balance = funder.balance;
        uint256 owner_post_balance = janusLottery.getOwner().balance;

        //funder should have received his price: jackpot + tickets - fee
        assertEq(owner_post_balance,owner_pre_balance+fee_prize);
        assertEq(winner_post_balance,winner_pre_balance+ticket_prize);
        assertEq(funder_post_balance,funder_pre_balance+funder_prize);
        assert(janusLottery.isFunding());        
        assertEq(janusLottery.getTotalTicketHolders(),0);
        assertEq(janusLottery.getTotalTicketsSale(),0);

        //other ticket buyers should have received nothing
        for (uint i = 5; i < 15; i++) {
            address buyer = address(uint160(0x00 + i));
            assertEq(buyer.balance,1 ether - ticketPrice);
        }
    }

}
