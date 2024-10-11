// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {JanusLottery} from "../src/JanusLottery.sol";

contract JanusLotteryTest is Test {
    JanusLottery public janusLottery;

    function setUp() public {
        janusLottery = new JanusLottery(0,0,0,0,0);
    }

 /*   function test_Increment() public {
        janusLottery.increment();
        assertEq(janusLottery.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        janusLottery.setNumber(x);
        assertEq(janusLottery.number(), x);
    }*/
}
