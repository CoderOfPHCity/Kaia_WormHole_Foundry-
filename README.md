# KaiaToken Cross-Chain Bridge
A simple cross-chain token transfer application built with Wormhole Protocol. 

This contract enables users to send ERC20 tokens between kaia chain, kairos testnet or ethereum.

This project comes prepacked with a detailed article guide with link below:
https://github.com/CoderOfPHCity/Kaia_WormHole_Foundry-/blob/master/src/article.md

## Features
1. Cross-chain ERC20 token transfers
2. Automated token bridging via Wormhole
3. Gas-efficient message passing
4. Recipient-specific token delivery

## Prerequisites
```
npm v8.5.0+
forge v0.2.0+
```

## Install dependencies
```
npm install
forge install
```


## Deploy to Kaia
```
forge create src/KaiaToken.sol:KaiaToken --rpc-url https://kaia.blockpi.network/v1/rpc/public --SIGNER --constructor-args 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911 0x0b2402144Bb366A632D14B83F244D2e0e21bD39c 0xa5f208e072434bC67592E4C49C1B991BA79BCA46 --gas-limit 8000000 
```

### KaiaChain Contract addresses
```
 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911, // WormholeRelayer address
 0x5b08ac39EAED75c0439FC750d9FE7E1F9dD0193F, // TokenBridge address
 0x0C21603c4f3a6387e241c0091A7EA39E43E90bb7  // Wormhole address
```

## License
MIT
