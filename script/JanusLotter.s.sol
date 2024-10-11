// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {JanusLottery} from "../src/JanusLottery.sol";

contract JanusLotteryScript is Script {
    function setUp() public {}

    function run() public returns(JanusLottery) {
        vm.startBroadcast();
        JanusLottery janusLottery = new JanusLottery(0,0,0,0,0);
        vm.stopBroadcast();
        return janusLottery;
    }
}
