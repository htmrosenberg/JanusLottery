// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {JanusLottery} from "../src/JanusLottery.sol";
import {ChainAdapter} from "../script/ChainAdapter.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

// ┌──────────────────────────────┐
// │╺┳┓┏━╸┏━┓╻  ┏━┓╻ ╻┏┳┓┏━╸┏┓╻╺┳╸│
// │ ┃┃┣╸ ┣━┛┃  ┃ ┃┗┳┛┃┃┃┣╸ ┃┗┫ ┃ │
// │╺┻┛┗━╸╹  ┗━╸┗━┛ ╹ ╹ ╹┗━╸╹ ╹ ╹ │
// └──────────────────────────────┘

contract Deployment is Script {

    uint16 public constant MINIMUM_SELLING_PERIOD_HOURS = 24;
    uint16 public constant MAXIMUM_SELLING_PERIOD_HOURS = 48;
    uint16 public constant FUNDING_PERIOD_HOURS = 24;
    uint256 constant public MINIMUM_JACKPOT = 1 ether;
    uint16 public constant PROMILLE_FEE = 1;
    
// ┌────────────────────────┐
// │┏━┓╻ ╻┏┓╻   ┏━┓┏━┓┏━╸┏━┓│
// │┣┳┛┃ ┃┃┗┫   ┣━┫┣┳┛┃╺┓┗━┓│
// │╹┗╸┗━┛╹ ╹   ╹ ╹╹┗╸┗━┛┗━┛│
// └────────────────────────┘

    function deploy(
        uint16 minimum_selling_period_hours,
        uint16 maximum_selling_period_hours,
        uint16 funding_period_hours,
        uint256 minimum_jackpot,
        uint16 promille_fee
    ) public returns (JanusLottery, ChainAdapter) {
        ChainAdapter chainAdapter = new ChainAdapter();
        ChainAdapter.Adaptation memory adaptation = chainAdapter.getAdaptation();

        AddConsumer addConsumer = new AddConsumer();
  
        if (adaptation.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (adaptation.subscriptionId, adaptation.vrfCoordinatorV2_5) =
                createSubscription.createSubscription(adaptation.vrfCoordinatorV2_5, adaptation.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                adaptation.vrfCoordinatorV2_5, adaptation.subscriptionId, adaptation.link, adaptation.account
            );

            chainAdapter.updateAdaptation(adaptation);
        }

        vm.startBroadcast();
        JanusLottery janusLottery = new JanusLottery(
            minimum_selling_period_hours,
            maximum_selling_period_hours,
            funding_period_hours,
            minimum_jackpot,
            promille_fee,
            adaptation.vrfCoordinatorV2_5,
            adaptation.subscriptionId,
            adaptation.gasLane,
            adaptation.callbackGasLimit
        );

        vm.stopBroadcast();
        addConsumer.addConsumer(address(janusLottery), adaptation.vrfCoordinatorV2_5, adaptation.subscriptionId, adaptation.account);
        return (janusLottery, chainAdapter);
    }

// ┌─────────────────────────────────┐
// │┏━┓╻ ╻┏┓╻   ╺┳┓┏━╸┏━╸┏━┓╻ ╻╻  ╺┳╸│
// │┣┳┛┃ ┃┃┗┫    ┃┃┣╸ ┣╸ ┣━┫┃ ┃┃   ┃ │
// │╹┗╸┗━┛╹ ╹   ╺┻┛┗━╸╹  ╹ ╹┗━┛┗━╸ ╹ │
// └─────────────────────────────────┘

    function run() external returns (JanusLottery, ChainAdapter) {

        return deploy( MINIMUM_SELLING_PERIOD_HOURS,
                    MAXIMUM_SELLING_PERIOD_HOURS,
                    FUNDING_PERIOD_HOURS,
                    MINIMUM_JACKPOT,
                    PROMILLE_FEE);
    }

}
