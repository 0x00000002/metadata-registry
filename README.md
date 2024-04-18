# Futureverse Access Manager's MULTISIG

## Deployment

Deploy the contract itself (example for 2 signers):

```sh
forge create --legacy ./src/Multisig.sol:Multisig \
   --private-key $DEPLOYER_PK \
   --rpc-url $RPC_URL \
   --constructor-args $MANAGER '[0xeb24a849E6C908D4166D34D7E3133B452CB627D2,0xaebC048B4D219D6822C17F1fe06E36Eba67D4144,0x1Fb0E85b7Ba55F0384d0E06D81DF915aeb3baca3]' 2
```

Deployed contracts:

## Example project

### Contracts on Porcini

- [Multisig - 0xe786F4224e072EdC144515f3795de2ad1fAd9009](https://explorer.rootnet.cloud/address/0xe786F4224e072EdC144515f3795de2ad1fAd9009)
- [AccessManager -0x367A65AD292faA479a8b081C0E13AF35833964F9](https://root)

```
export VERIFIER_URL=https://api-sepolia.scrollscan.com/api
export DEPLOYER_PK=42aa06dc8c320e0255df8d95494f6a7b66e10fa30919a24ad910a6c2bdbcc8ee
export RPC_URL=https://porcini.au.rootnet.app
export ETHERSCAN_API_KEY=F7ANGF3AQWSVMHXTWAK2IZQRH48BGSN2KG
export SIGNER1=0x1Fb0E85b7Ba55F0384d0E06D81DF915aeb3baca3
export SIGNER2=0xaebC048B4D219D6822C17F1fe06E36Eba67D4144
export SIGNER3=0xeb24a849E6C908D4166D34D7E3133B452CB627D2

forge create ./src/Multisig.sol:Multisig \
   --private-key $DEPLOYER_PK \
   --verify \
   --etherscan-api-key $ETHERSCAN_API_KEY \
   --rpc-url $RPC_URL \
   --constructor-args $MANAGER '[0x1Fb0E85b7Ba55F0384d0E06D81DF915aeb3baca3, 0xaebC048B4D219D6822C17F1fe06E36Eba67D4144]' 2
```

### Contracts on Sepolia

- [Multisig - 0xe786F4224e072EdC144515f3795de2ad1fAd9009](https://explorer.rootnet.cloud/address/0xe786F4224e072EdC144515f3795de2ad1fAd9009)
- [AccessManager -0x367A65AD292faA479a8b081C0E13AF35833964F9](https://root)

```
export VERIFIER_URL=https://api-sepolia.scrollscan.com/api
export DEPLOYER_PK=42aa06dc8c320e0255df8d95494f6a7b66e10fa30919a24ad910a6c2bdbcc8ee
export RPC_URL=https://sepolia.drpc.org
export ETHERSCAN_API_KEY=F7ANGF3AQWSVMHXTWAK2IZQRH48BGSN2KG
export MANAGER=0x1Fb0E85b7Ba55F0384d0E06D81DF915aeb3baca3
export SIGNER2=0xaebC048B4D219D6822C17F1fe06E36Eba67D4144
export SIGNER3=0xeb24a849E6C908D4166D34D7E3133B452CB627D2

forge create ./src/Multisig.sol:Multisig \
   --private-key $DEPLOYER_PK \
   --rpc-url $RPC_URL \
   --constructor-args $MANAGER '[0xeb24a849E6C908D4166D34D7E3133B452CB627D2,0xaebC048B4D219D6822C17F1fe06E36Eba67D4144,0x1Fb0E85b7Ba55F0384d0E06D81DF915aeb3baca3]' 2

export MULTISIG=....
```

then verify it:

```
forge verify-contract $MULTISIG ./src/Multisig.sol:Multisig \
   --chain-id 11155111 \
   --watch \
   --constructor-args 0000000000000000000000001fb0e85b7ba55f0384d0e06d81df915aeb3baca3000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003000000000000000000000000eb24a849e6c908d4166d34d7e3133b452cb627d2000000000000000000000000aebc048b4d219d6822c17f1fe06e36eba67d41440000000000000000000000001fb0e85b7ba55f0384d0e06d81df915aeb3baca3
```
