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
        uint256 jackpotValue = deployment.MINIMUM_JACKPOT();
        ticketPrice = 10 wei;
        maximumTickets = 10;
        sellingPeriodHours = deployment.MAXIMUM_SELLING_PERIOD_HOURS()-1;
        janusLottery.jackPotOffer{ value : jackpotValue}(ticketPrice, maximumTickets, sellingPeriodHours);

//        janusLottery.checkUpkeep(null);  
//        janusLottery.performUpkeep()      
    }

// ┌──────────────────────────────────────────┐
// │┏┓╻┏━┓   ┏┳┓┏━┓┏━┓┏━╸   ┏━┓┏━╸┏━╸┏━╸┏━┓┏━┓│
// │┃┗┫┃ ┃   ┃┃┃┃ ┃┣┳┛┣╸    ┃ ┃┣╸ ┣╸ ┣╸ ┣┳┛┗━┓│
// │╹ ╹┗━┛   ╹ ╹┗━┛╹┗╸┗━╸   ┗━┛╹  ╹  ┗━╸╹┗╸┗━┛│
// └──────────────────────────────────────────┘

//test past offer phase



}
