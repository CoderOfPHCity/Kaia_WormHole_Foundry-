# A Guide to Integrating Wormhole Cross-Chain Protocol on Kaia Blockchain

[Cross-chain messaging](https://wormhole.com/) is the core mechanism that enables the transfer of data from one blockchain to another. 

Think of it as a bridge between chains, allowing seamless communication and actions across different ecosystems. 

For instance, you can send data from [Kaia](https://www.kaia.io/) to Ethereum and trigger operations on ethereum upon receiving it.
![worm](https://hackmd.io/_uploads/rk1fdZkmJl.png)
Using cross-chain messaging, you can:

* Send a Cross-Chain Message: On the Kaia chain, send a message containing necessary staking data, like the amount to token deposit and any specific parameters.
* Receive and Process the Message: On the ethereum side, the message is received and verified via the cross-chain messaging protocol.
* Execute the Recieve Operation: Once the message is processed, the token payload is decoded on ethereum and is automatically invoked using the data received from Kaia.

We are going to dive into the implementation of simple cross-chain messaging between the two chains straight away without wasting too much time.

For this topic, we will use Wormhole. Wormhole provides a solidity SDK for cross-chain messaging. We will use Wormhole's cross-chain messaging to send data from one chain to another.

## How Wormhole Cross-Chain Works under The Hood?
Wormhole Token Bridge lies the lock-and-mint mechanism, which uses the Core Contract with a specific payload to pass information about the transfer. Tokens on the source chain are locked, and wrapped tokens are minted on the destination chain. 

This approach guarantees that token transfers are secure and consistent, ensuring that token properties such as name, symbol, and decimal precision are preserved across chains.

Think of the Wormhole Token Bridge as a cross-chain banking system. 

**Here's how it works:**
* When you send tokens from Ethereum to KaiaChain, the tokens get locked in a smart contract on Ethereum.
* The same amount of wrapped tokens are then minted on KaiaChain.
* The bridge ensures your token's properties (decimals, symbol, name) stay exactly the same across chains.

Before you can bridge a token for the first time, there's an `attestation` step. This is basically registering the token's metadata on the new chain so it knows how to create the wrapped version correctly.
The transfer process is pretty straightforward:

You specify which address should receive the tokens on the destination chain. The bridge handles all the locking and minting automatically, and then a user gets their wrapped tokens on the new chain.


While the program on KaiaChain can trust the message to inform it of token lockup events, it has no way of verifying the correct token is locked up. The address alone is a meaningless value to most users. To solve this, the Token Bridge supports token `attestation`.

For a token attestation, Ethereum emits a message containing metadata about a token, which KaiaChain may use to preserve the name, symbol, and decimal precision of a token address.

The message format for this action is as follows:

1. payload_id u8 - the ID of the payload. This should be set to 2 for an attestation
1. token_address [32]byte - address of the originating token contract
1. token_chain u16 - chain ID of the originating token
1. decimals u8 - number of decimals this token should have
1. symbol [32]byte - short name of asset
1. name [32]byte - full name of asset

Wormhole Tokenbridge also supports [Contract Controlled Transfers](https://wormhole.com/docs/learn/infrastructure/vaas/#token-transfer-with-message). It lets you attach extra data payload to your transfer - kind of like passing function parameters. 

So instead of just sending tokens, you could tell a protocol or DEX on the destination chain to immediately swap them, or trigger other smart contract actions.

For example, you could send 100 USDC to KaiaChain with instructions to:

* Swap 50 USDC for ETH
* Provide the remaining 50 USDC as liquidity
* All in one transaction

Before a token can be transferred to a new chain, the token’s metadata must be attested. 

This process registers the token details (such as decimals and symbol) on the destination chain, enabling the creation of wrapped assets.



## Prerequisites
1. Basic understanding of Ethereum development and programming  fundamentals.
2. A web3 wallet (e.g., MetaMask, Rabbi wallet) with Klay on Kaia mainnet.
3. Foundry to compile and deploy smart contracts or do the same locally on your machine by setting up a hardhat or RemixIDE project.

## Getting Started
We will build an ERC20 contract that leverage wormhole cross chain functionalites as well as cross chain token transfer functionalitoes.

This tutorial contains a solidity contract that can be deployed onto Kaia Blockchain and many EVM chains to form a fully functioning cross-chain application with the ability for users to request, from one contract, that tokens are sent to an address on a different chain.

To follow along i created a completes [GitHub](https://github.com/CoderOfPHCity/Kaia_Wormhole_Foundry) repository of the working project.
Included in this repository is:

* Example Solidity Code
* Example Forge local testing setup
* Testnet Deploy Scripts
* Example Testnet testing setup

Before getting started, it is important to note that we use Wormhole's TokenBridge to transfer tokens between chains!

So, in order to send a token using the method in this example, the token must be attested onto the Token Bridge contract that lives on our desired target blockchain.

To ease development, we'll make use of the[ Wormhole Solidity SDK](https://wormhole-foundation.github.io/wormhole-sdk-ts/). Then head to supported chain in [Wormhole Docs](https://wormhole.com/docs/build/start-building/supported-networks/evm/#klaytn) and get the Relayer, Tokenbridge and wormhole core  contract addresses of kaia mainnet.
![kaiwormhole](https://hackmd.io/_uploads/SJ0X_Zymkg.png)


Include this SDK in your own cross-chain application by running:

`forge install wormhole-foundation/wormhole-solidity-sdk`

Let's start writing the KaiaToken contract:

Create a new file named KaiaToken.sol in the /src directory:
Create a new solidity contract file an import wormhole SDK as below;

```
import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/interfaces/IERC20.sol";
```
This SDK contains aids that enable cross-chain development with Wormhole easier, particularly the TokenSender and TokenReceiver abstract classes with handy capabilities for sending and receiving tokens using TokenBridge.

We import two crucial interfaces from the Wormhole SDK.

1. IWormholeRelayer: This interface allows us to communicate with Wormhole's relayer, which sends cross-chain messages.
2. IWormholeReceiver: This interface is used to receive messages from other chains. By inheriting from this, our contract will be able to handle incoming cross-chain communications.

The KaiaToken contract derives from the IWormholeReceiver interface. This inheritance will subsequently allow us to construct a method that handles incoming messages.

### Define the constructor
```
constructor(
    address _wormholeRelayer,
    address _tokenBridge,
    address _wormhole
) TokenBase(_wormholeRelayer, _tokenBridge, _wormhole) {}
```
The wormholeRelayer state variable is assigned within the constructor using the given _wormholeRelayer address. 



This address must point to the appropriate instance of the Wormhole Relayer on the blockchain where your contract is implemented. You can retrieve this kaia address from the [wormhole documentation](https://wormhole.com/docs/build/start-building/supported-networks/evm/#klaytn).

![kaiaKairoswormhole](https://hackmd.io/_uploads/SJGMWbJXJe.png)

```
    0x0C21603c4f3a6387e241c0091A7EA39E43E90bb7
    0x5b08ac39EAED75c0439FC750d9FE7E1F9dD0193F
    0x3c3c561757BAa0b78c5C025CdEAa4ee24C1dFfEf
    0x27428DD2d3DD32A4D7f7C497eAaa23130d894911
```

The constructor takes three critical Wormhole infrastructure contract addresses based on kaia chain:

* _wormholeRelayer: This is the address of Wormhole's relayer contract that handles the automated delivery of messages and VAAs (Verified Action Approvals) across different blockchains. 
* _tokenBridge: This is the address of Wormhole's Token Bridge contract on the current chain. This contract handles the locking/unlocking and minting/burning of tokens when they're transferred across chains. 
* _wormhole: This is the address of the core Wormhole contract that handles the basic message passing protocol, VAA verification, and guardian signature validation.

The constructor uses these addresses to initialize a TokenBase contract through inheritance (:) by passing these parameters to its constructor. 

TokenBase is an abstract contract from the Wormhole Solidity SDK that provides the basic functionality for token-based cross-chain operations.

The empty implementation {} indicates that this constructor doesn't perform any additional initialization beyond what's handled by the TokenBase constructor.

### Gas Limit Constant:
`uint256 constant GAS_LIMIT = 2500_000;`
We define a constant GAS_LIMIT for executing cross-chain transactions.

Here, we set it to 2500_000, but this value can be adjusted based on the complexity of the operation you are relaying across chains.

## Token Sender Function
The KaiaToken contract calculates the cost of sending tokens across chains and then facilitates the actual token transfer.

Next, let's add a function that estimates the cost of sending tokens across chains:


    function quoteCrossChainDeposit(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        uint256 deliveryCost;
        (deliveryCost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            2500_000
        );

        cost = deliveryCost + wormhole.messageFee();
    }
This function, `quoteCrossChainDeposit`, helps calculate the cost of transferring tokens to a different chain. It factors in the delivery cost and the cost of publishing a message via the Wormhole protocol.

Finally, we'll add the function that sends the tokens across chains:

    function sendCrossChainDeposit(
        uint16 targetChain,
        address targetReceiver,
        address recipient,
        uint256 amount,
        address token
    ) public payable {
        uint256 cost = quoteCrossChainDeposit(targetChain);
        require(
            msg.value >= cost,
            "msg.value must equal quoteCrossChainDeposit(targetChain)"
        );

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        bytes memory payload = abi.encode(recipient);

        sendTokenWithPayloadToEvm(
            targetChain,
            targetReceiver,
            payload,
            0,
            2500_000,
            token,
            amount
        );
    }
This `sendCrossChainDeposit` function is where the actual token transfer happens. It sends the tokens to the recipient on the target chain using the Wormhole protocol.

Here’s a breakdown of what happens in each step of the `sendCrossChainDeposit` function:

**Cost calculation** - the function starts by calculating the cost of the cross-chain transfer using `quoteCrossChainDeposit(targetChain)`. This cost includes both the delivery fee and the Wormhole message fee. The `sendCrossChainDeposit` function then checks that the user has sent the correct amount of Ether to cover this cost (msg.value)

**Token transfer to contract** - the next step is to transfer the specified amount of tokens from the user to the contract itself using `IERC-20(token).transferFrom(msg.sender, address(this), amount)`. This ensures that the contract has custody of the tokens before initiating the cross-chain transfer

**Payload encoding** - The recipient's address on the target chain is encoded into a payload using abi.encode(recipient). This payload will be sent along with the token transfer, so the target contract knows who should receive the tokens on the destination chain

**Cross-chain transfer** - the `sendTokenWithPayloadToEvm` function is called to initiate the cross-chain token transfer. This function:

* Specifies the targetChain (the Wormhole chain ID of the destination blockchain).
* Sends the targetReceiver contract address on the target chain that will receive the tokens.
* Attaches the payload containing the recipient's address.
* Sets the `GAS_LIMIT` for the transaction.
* Passes the token address and amount to transfer.

This triggers the Wormhole protocol to handle the cross-chain messaging and token transfer, ensuring the tokens and payload reach the correct destination on the target chain.

## Token Reciever Function
We'll implement the TokenReceiver abstract class - which is also included in the Wormhole Solidity SDK
```
struct TokenReceived {
    bytes32 tokenHomeAddress;
    uint16 tokenHomeChain;
    address tokenAddress;
    uint256 amount;
    uint256 amountNormalized;
}

function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
) internal virtual {}
```

After we call `sendTokenWithPayloadToEvm` on the source chain, the message goes through the standard Wormhole message lifecycle. 

Once a VAA is available, the delivery provider will call `receivePayloadAndTokens` on the target chain and target address specified, with the appropriate inputs.

The arguments payload, sourceAddress, sourceChain, and deliveryHash are all the same as on the normal receiveWormholeMessages endpoint.

Let's delve into the fields that are provided to us in the TokenReceived struct:

**TokenHomeAddress** - The same as the token field in the call to sendTokenWithPayloadToEvm, as that is the original address of the token unless the original token sent is a wormhole-wrapped token.

**TokenHomeChain** - The chain (in wormhole chain ID format) corresponding to the home address above - this will be the source chain.

**TokenAddress** This is the address of the IERC20 token on this chain (the target chain) that has been transferred to this contract. If tokenHomeChain == this chain, this will be the same as tokenHomeAddress; otherwise, it will be the wormhole-wrapped version of the token sent.

**Amount** This is the amount of the token that has been sent to you - the units being the same as the original token. 


Recall all we intend to do is send the received token to the recipient, our fields of interest are payload (containing recipient), `receivedTokens[0].tokenAddress` (token we received), and `receivedTokens[0].amount`.

We can complete the implementation as follows:
```
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
```

This function above ensures that:

* It only processes one token transfer at a time
* The recipient address is decoded from the payload, and the received tokens are transferred to them using the ERC-20 interface

Note:TokenBridge already provides a form of duplicate prevention when redeeming sent tokens

Yeh! We now have a fully functional cross-chain application that sends and receives tokens via TokenBridge.

## Multi-Chain Testing With Foundry
Next, input this code into your contract test file and run
```
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

```
Configure your test files to use wormhole inbuilt cross chain test suit and run the following command 
```
forge test
```
![kaiatest](https://hackmd.io/_uploads/Byvluh-X1l.png)

Your Cross chain Foundry test stack trace should look like this above

## Compile & deploy
Let’s compile the above contract on Foundry, you can also use Remix IDE and deploy it on two Kaia mainnet, Ethereum or kairos testnet. For this tutorial i deployed on kaia mainnet.

For this part, i created a deployment script using foundry here;
```
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

```
Get the relayer address from [wormhole documentation](https://wormhole.com/docs/build/start-building/supported-networks/evm/#klaytn) . Enter the relayer address for the connected chain as a constructor argument in the deploy input field.

Configure your forge cast and run the command to get your cross chain kaiaToken Contract deployed on kaia mainnet.

```
forge create src/KaiaToken.sol:KaiaToken --rpc-url https://kaia.blockpi.network/v1/rpc/public --SIGNER --constructor-args 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911 0x0b2402144Bb366A632D14B83F244D2e0e21bD39c 0xa5f208e072434bC67592E4C49C1B991BA79BCA46 --gas-limit 8000000 
```
While this article focuses on Wormhole on the Kaia blockchain, many protocols have a similar structure, with notable differences. 

To assist you in navigating them, here is a link to a GitHub repository where you can walkthrough the contracts using various cross-chain messaging protocols:

GitHub: https://github.com/CoderOfPHCity/Kaia_WormHole_Foundry-
