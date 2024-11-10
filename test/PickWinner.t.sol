// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
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
        address funder = address(0x1);
        vm.deal(funder, 2 ether);
        vm.prank(funder);
        janusLottery.jackPotOffer{value: jackpotValue}(ticketPrice, maximumTickets, sellingPeriodHours);
        vm.warp(block.timestamp + (fundingHours * 60 * 60));
        vm.roll(block.number + 1);
        janusLottery.performUpkeep("");
        assert(janusLottery.isSelling());

        uint256 hoursSelling = sellingPeriodHours;

        for (uint i = 5; i < 15; i++) {
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

        vm.expectEmit(true, false, false, true);
        emit JanusLottery.RequestedRandomNumber(1);

        janusLottery.performUpkeep("");

        assert(janusLottery.isCalculating());


    }

    function testPickNoWinner() public {
         VRFCoordinatorV2_5Mock(chainAdaptation.vrfCoordinatorV2_5).fulfillRandomWords(1, address(janusLottery));

    }

}
