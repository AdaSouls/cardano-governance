# Vote as the SOULS stake pool

SPOs vote on no-confidence motions, committee updates, hard forks, security-relevant protocol parameters and Info actions (CIP-1694). Not on treasury withdrawals or the Constitution.

The vote is signed with the pool's cold key, on the offline machine, exactly like the pool certificate. No Ledger needed. Tested with cardano-cli 11.2.3 on a local Conway network.

## 1. Online: build

`cold.vkey` is public; the copy on the USB stick from the pool update works.

```bash
ACTION_TX=<governance action tx id>; ACTION_IX=<index>
URL=https://raw.githubusercontent.com/AdaSouls/adasouls-governance/main/votes/$ACTION_TX-$ACTION_IX/souls-rationale.jsonld
HASH=$(cardano-cli hash anchor-data --file-text votes/$ACTION_TX-$ACTION_IX/souls-rationale.jsonld)
cardano-cli conway governance vote create --abstain \
  --governance-action-tx-id "$ACTION_TX" --governance-action-index "$ACTION_IX" \
  --cold-verification-key-file cold.vkey --anchor-url "$URL" --anchor-data-hash "$HASH" \
  --out-file spo.vote
cardano-cli conway transaction build --mainnet \
  --tx-in <TXHASH#IX from fees.addr> --change-address "$(cat fees.addr)" \
  --vote-file spo.vote --witness-override 2 --out-file spo.raw
```

## 2. Offline: sign with the cold key and the fee key

```bash
cardano-cli conway transaction witness --tx-body-file spo.raw \
  --signing-key-file /home/usuario/cold-keys/cold.skey --mainnet --out-file cold.witness
cardano-cli conway transaction witness --tx-body-file spo.raw \
  --signing-key-file /home/usuario/cold-keys/fees.skey --mainnet --out-file fee.witness
cardano-cli conway transaction assemble --tx-body-file spo.raw \
  --witness-file cold.witness --witness-file fee.witness --out-file spo.signed
```

## 3. Online: submit and check

```bash
cardano-cli conway transaction submit --mainnet --tx-file spo.signed
cardano-cli conway query gov-state --mainnet | jq '.proposals[] | select(.actionId.txId=="'$ACTION_TX'") | .stakePoolVotes'
```

The pool id in `stakePoolVotes` is `50de79c63d672319e20be59c620eb57ed1de8b7cc7fa489d8f22e353`.
