// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/interfaces/IERC20.sol";

contract KaiaToken is TokenSender, TokenReceiver {
    uint256 constant GAS_LIMIT = 250_000000;

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole)
    {}

    function quoteCrossChainDeposit(uint16 targetChain) public view returns (uint256 cost) {
        uint256 deliveryCost;
        (deliveryCost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, 2500_000);
        cost = deliveryCost + wormhole.messageFee();
    }

    function sendCrossChainDeposit(
        uint16 targetChain,
        address targetHelloToken,
        address recipient,
        uint256 amount,
        address token
    ) public payable {
        uint256 cost = quoteCrossChainDeposit(targetChain);
        require(msg.value >= cost, "msg.value must be quoteCrossChainDeposit(targetChain)");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        bytes memory payload = abi.encode(recipient);
        sendTokenWithPayloadToEvm(
            targetChain,
            targetHelloToken, // address (on targetChain) to send token and payload to
            payload,
            0, // receiver value
            2500_000,
            token, // address of IERC20 token contract
            amount
        );
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32, // sourceAddress
        uint16,
        bytes32 // deliveryHash
    ) internal override onlyWormholeRelayer {
        require(receivedTokens.length == 1, "Expected 1 token transfers");

        address recipient = abi.decode(payload, (address));

        IERC20(receivedTokens[0].tokenAddress).transfer(recipient, receivedTokens[0].amount);
    }
}
