# NFTD - Stablecoin

::Goerli Test Net::

:::contract:::

1. VRFv2Consumer

- 150 gwei Key Hash/keyHash: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
- VRF Coordinator/VRFConsumerBaseV2: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D

```
npx hardhat run scripts/nftDollar/deploy.js --network goerliTestNet
npx hardhat run scripts/nftLand/deploy.js --network goerliTestNet
npx hardhat run scripts/vRFv2Consumer/deploy.js --network goerliTestNet
npx hardhat run scripts/earthverseDeposit/deploy.js --network goerliTestNet
npx hardhat run scripts/earthverseMarketplace/deploy.js --network goerliTestNet

npx hardhat verify --network goerliTestNet 0x009f891e0a2f11dC9B2f95dcc86b983D173EA03d

npx hardhat verify --network goerliTestNet --constructor-args arguments.js 0x8e89447dC261EAc5086750dbdD20462371861A46
```

::BSC Test Net::

:::contract:::

1. VRFv2Consumer

- 50 gwei Key Hash/keyHash: 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314
- VRF Coordinator/VRFConsumerBaseV2: 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f

```shell
npx hardhat run scripts/nftDollar/deploy.js --network binanceSmartChainTestNet
npx hardhat run scripts/nftLand/deploy.js --network binanceSmartChainTestNet
npx hardhat run scripts/vRFv2Consumer/deploy.js --network binanceSmartChainTestNet
```

::BSC Main Net::

:::contract:::

1. VRFv2Consumer

- 500 gwei Key Hash/keyHash: 0xba6e730de88d94a5510ae6613898bfb0c3de5d16e609c5b7da808747125506f7
- VRF Coordinator/VRFConsumerBaseV2: 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE

```shell
npx hardhat run scripts/nftDollar/deploy.js --network binanceSmartChainMainNet
npx hardhat run scripts/nftLand/deploy.js --network binanceSmartChainMainNet
npx hardhat run scripts/vRFv2Consumer/deploy.js --network binanceSmartChainMainNet
```
