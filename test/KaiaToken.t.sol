// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KaiaToken} from "../src/KaiaToken.sol";

import "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract KaiaTokenTest is WormholeRelayerBasicTest {
    KaiaToken public kaiaSource;
    KaiaToken public kaiaTarget;

    ERC20Mock public token;

    function setUpSource() public override {
        kaiaSource = new KaiaToken(
            address(relayerSource), address(tokenBridgeSource), address(wormholeSource)
        );

        token = createAndAttestToken(sourceChain);
    }

    function setUpTarget() public override {
        kaiaTarget = new KaiaToken(
            address(relayerTarget), address(tokenBridgeTarget), address(wormholeTarget)
        );
    }

    function testRemoteDeposit() public {
        uint256 amount = 19e17;
        token.approve(address(kaiaSource), amount);

        vm.selectFork(targetFork);
        address recipient = 0x1234567890123456789012345678901234567890;
        vm.deal(recipient, 1 ether);

        vm.selectFork(sourceFork);
        uint256 cost = kaiaSource.quoteCrossChainDeposit(targetChain);

        vm.recordLogs();
        kaiaSource.sendCrossChainDeposit{value: cost}(
            targetChain, address(kaiaTarget), recipient, amount, address(token)
        );
        performDelivery();

        vm.selectFork(targetFork);
        address wormholeWrappedToken =
            tokenBridgeTarget.wrappedAsset(sourceChain, toWormholeFormat(address(token)));
        assertEq(IERC20(wormholeWrappedToken).balanceOf(recipient), amount);
    }
}
