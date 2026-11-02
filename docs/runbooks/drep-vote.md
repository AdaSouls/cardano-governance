# Vote as the AdaSouls DRep

One vote per transaction (the Ledger accepts a single voter with a single voting procedure). Same machines and files as `G0-register-drep.md`.

## 1. Online: publish the rationale, build the vote

The rationale is a CIP-100 JSON-LD file, `votes/<action-id>/rationale.jsonld`, made from `drep/vote-rationale.template.jsonld`. Publish it first: `transaction build` downloads it and checks its hash.

```bash
ACTION_TX=<governance action tx id>; ACTION_IX=<index>
URL=https://raw.githubusercontent.com/AdaSouls/adasouls-governance/main/votes/$ACTION_TX-$ACTION_IX/rationale.jsonld
HASH=$(cardano-cli hash anchor-data --file-text votes/$ACTION_TX-$ACTION_IX/rationale.jsonld)
cardano-cli hash anchor-data --url "$URL" --expected-hash "$HASH"
cardano-cli conway governance vote create --yes \
  --governance-action-tx-id "$ACTION_TX" --governance-action-index "$ACTION_IX" \
  --drep-verification-key-file drep.vkey --anchor-url "$URL" --anchor-data-hash "$HASH" \
  --out-file drep.vote
cardano-cli conway transaction build --mainnet \
  --tx-in <TXHASH#IX from fees.addr> --change-address "$(cat fees.addr)" \
  --vote-file drep.vote --witness-override 2 --out-file vote.raw
```

Use `--no` or `--abstain` instead of `--yes` as decided.

## 2. Offline: sign

```bash
cardano-hw-cli transaction transform --tx-file vote.raw --out-file vote.tx
cardano-hw-cli transaction witness --tx-file vote.tx --hw-signing-file drep.hwsfile --mainnet --out-file drep.witness
cardano-cli conway transaction witness --tx-body-file vote.tx \
  --signing-key-file /home/usuario/cold-keys/fees.skey --mainnet --out-file fee.witness
cardano-cli conway transaction assemble --tx-body-file vote.tx \
  --witness-file drep.witness --witness-file fee.witness --out-file vote.signed
```

On the Ledger, check the action id, the vote and the anchor.

## 3. Online: submit and check

```bash
cardano-cli conway transaction submit --mainnet --tx-file vote.signed
cardano-cli conway query gov-state --mainnet | jq '.proposals[] | select(.actionId.txId=="'$ACTION_TX'") | .dRepVotes'
```

In our test, `query gov-state` showed the vote right away; `query proposals` didn't show it within the same epoch.

A later vote on the same action replaces this one.
