# G2 · Voting tools

About 2 weeks. Repo: adasouls-governance.
Done when DRep votes (Ledger) and SOULS votes (cold key) go through scripts with checks, tested end to end on a local network.

## G2.1 · DRep votes with the Ledger

```text
Session G2.1: scripts for the AdaSouls DRep's votes, following docs/runbooks/drep-vote.md, which was tested by hand on a local Conway network with cardano-cli 11.2.3.
Three bash scripts in scripts/drep-vote/, like the pool-update scripts I'll paste: 01-online-build.sh (vote create with the rationale anchor, checking the published file's hash first; transaction build), 02-offline-sign.sh (cardano-hw-cli transaction transform and witness with drep.hwsfile, the fee witness with cardano-cli, assemble), 03-online-submit.sh (submit, then read the vote back from query gov-state).
Before signing, print a summary and ask for confirmation: exactly one voter, exactly one voting procedure, the action id, the vote, the anchor; no certificates, withdrawals or mints. The Ledger accepts only one vote per transaction.
Private keys are paths on the offline machine and never travel; the scripts warn if a .skey sits next to them.
```

## G2.2 · SOULS votes with the cold key

```text
Session G2.2: the same three scripts for the SOULS pool, following docs/runbooks/spo-vote.md: the vote is created with cold.vkey online, and the cold key and fee key witness it on the offline machine. Refuse to build a vote on an action type SPOs can't vote on (CIP-1694: no-confidence, committee updates, hard fork, security-relevant parameters and Info are allowed).
```

## G2.3 · End-to-end test

```text
Session G2.3: a test script that starts a local Conway network with cardano-testnet, registers a DRep with metadata, creates an Info action, and runs both voting flows with test keys (no Ledger: a test-only path signs with a DRep .skey). It checks both votes in query gov-state. Document how to run it.
```
