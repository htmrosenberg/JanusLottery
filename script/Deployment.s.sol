// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {JanusLottery} from "../src/JanusLottery.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";


// ┌──────────────────────────────┐
// │╺┳┓┏━╸┏━┓╻  ┏━┓╻ ╻┏┳┓┏━╸┏┓╻╺┳╸│
// │ ┃┃┣╸ ┣━┛┃  ┃ ┃┗┳┛┃┃┃┣╸ ┃┗┫ ┃ │
// │╺┻┛┗━╸╹  ┗━╸┗━┛ ╹ ╹ ╹┗━╸╹ ╹ ╹ │
// └──────────────────────────────┘

contract Deployment is Script {
    uint16 public constant MINIMUM_SELLING_PERIOD_HOURS = 24;
    uint16 public constant MAXIMUM_SELLING_PERIOD_HOURS = 48;
    uint16 public constant FUNDING_PERIOD_HOURS = 24;
    uint256 public constant MINIMUM_JACKPOT = 1 ether;
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
    ) public returns (JanusLottery, HelperConfig) {
 
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) =
                createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account
            );

            helperConfig.setConfig(block.chainid, config);
        }

        vm.startBroadcast();
        JanusLottery janusLottery = new JanusLottery(
            minimum_selling_period_hours,
            maximum_selling_period_hours,
            funding_period_hours,
            minimum_jackpot,
            promille_fee,
            config.vrfCoordinatorV2_5,
            config.subscriptionId,
            config.gasLane,
            config.callbackGasLimit
        );

        vm.stopBroadcast();

        // We already have a broadcast in here
        addConsumer.addConsumer(address(janusLottery), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);
    
        return (janusLottery, helperConfig);
    }

    // ┌─────────────────────────────────┐
    // │┏━┓╻ ╻┏┓╻   ╺┳┓┏━╸┏━╸┏━┓╻ ╻╻  ╺┳╸│
    // │┣┳┛┃ ┃┃┗┫    ┃┃┣╸ ┣╸ ┣━┫┃ ┃┃   ┃ │
    // │╹┗╸┗━┛╹ ╹   ╺┻┛┗━╸╹  ╹ ╹┗━┛┗━╸ ╹ │
    // └─────────────────────────────────┘

    function run() external returns (JanusLottery, HelperConfig) {
        return deploy(
            MINIMUM_SELLING_PERIOD_HOURS,
            MAXIMUM_SELLING_PERIOD_HOURS,
            FUNDING_PERIOD_HOURS,
            MINIMUM_JACKPOT,
            PROMILLE_FEE
        );
    }
}

