// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "./KaiaToken.sol";

contract Deployscript is Script {
    KaiaToken public helloToken;

    address deployer = 0x4506fDD110Ae6e5b5401d5A6380D3EB141e98d9f;

    function run() external {
        vm.startBroadcast(deployer);

        // constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)
        helloToken = new KaiaToken(
            0x27428DD2d3DD32A4D7f7C497eAaa23130d894911, // WormholeRelayer address
            0x0b2402144Bb366A632D14B83F244D2e0e21bD39c, // TokenBridge address
            0xa5f208e072434bC67592E4C49C1B991BA79BCA46 // Wormhole address
        );

        console.log("KaiaToken deployed at:", address(helloToken));
        console.log(" deployer Address at:", deployer);

        vm.stopBroadcast();
    }
}
