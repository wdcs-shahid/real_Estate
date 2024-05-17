//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {Real_estate} from "../src/Real_Estate.sol";
import {MyToken} from "../src/USDT.sol";

contract myScript is Script {
    function run() external {
        vm.startBroadcast();
        MyToken usdt = new MyToken();
        new Real_estate(address(usdt));
        vm.stopBroadcast();
    }
}
