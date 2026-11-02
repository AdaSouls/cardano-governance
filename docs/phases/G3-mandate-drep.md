# G3 · A DRep with a mandate

About 6 weeks. Repos: adasouls-contracts (`cardano/`, after session F0.2) and adasouls-governance.
Done when a script DRep on preprod casts, through the agent, only the votes a human signed, through a full cycle of analysis, authorization and vote. No mainnet before an audit.

Starting point: the `agent-drep` prototype (Aiken 1.1.24, stdlib v4.0.0, 9 passing tests). The human can always vote directly; the agent can only cast the exact votes the human signed, before they expire.

## G3.1 · Replay protection and key rotation

```text
Session G3.1, repo adasouls-contracts: move the agent-drep prototype into cardano/ (validators/agent_drep.ak, lib/alma/vote.ak) and close its two gaps.
1. Replay: a voting script has no datum, so an unexpired authorization could be replayed after the human changes their mind. Make the vote spend a state UTxO, identified by a state token, that holds a sequence number; the authorization signs that number and the spend increments it.
2. Key rotation: read the agent key and the human key from a config UTxO passed as a reference input, identified by a token, so changing keys doesn't change the script hash and the DRep keeps its delegations. Only the human key can update the config.
One failing test per attack: replayed authorization, wrong sequence, fake config UTxO, config update without the human. Keep the existing tests passing.
```

## G3.2 · Off-chain

```text
Session G3.2, repo adasouls-governance: sign vote authorizations and build the voting transaction.
The authorization digest must equal the Aiken library's (test vector in lib/alma/vote.ak, digest_vector). The human signs with Ed25519 from a key file or a Ledger-compatible flow; the agent builds the transaction with the Plutus voting redeemer, the state and config UTxOs, and a validity range that ends before the authorization expires. Tests against the Aiken vectors.
```

## G3.3 · Preprod cycle

```text
Session G3.3: a runbook and scripts for preprod: register the script DRep (with the human's signature), create a test action or vote on an open preprod action, produce an analysis with the G1 analyst, have the human sign the authorization, and let the agent submit the vote. Record every transaction id in docs/STATUS.md. Nothing on mainnet.
```
