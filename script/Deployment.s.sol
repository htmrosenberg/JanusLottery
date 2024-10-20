// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {JanusLottery} from "../src/JanusLottery.sol";

contract Deployment is Script {
    function run(
        uint16 minimum_selling_period_hours,
        uint16 maximum_selling_period_hours,
        uint16 funding_period_hours,
        uint256 minimum_jackpot,
        uint16 promille_fee
    ) public returns (JanusLottery) {
        vm.startBroadcast();
        JanusLottery janusLottery = new JanusLottery(
            minimum_selling_period_hours,
            maximum_selling_period_hours,
            funding_period_hours,
            minimum_jackpot,
            promille_fee,
            address(0x0),
            1,
            "0x1",
            1
        );

        vm.stopBroadcast();
        return janusLottery;
    }
}
