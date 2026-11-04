# Status

Update at the end of every session. Newest log entry first.

| Phase | Status | Notes |
| --- | --- | --- |
| G0 Start | Not started | |
| G1 Analyst | Code done, not yet run on a real decision | Lives in `reference-agents/governance-analyst` (PR #7): ingest, Constitution, analysis, review, publish. Outputs land here in `votes/`. First real analysis pending Matías's run |
| G2 Voting tools | G2.1 scripts written, untested on a network | `scripts/drep-vote/01-03`; G2.2 (SOULS cold key) and G2.3 (local Conway network test) pending |
| G3 DRep with a mandate | G3.1 done | Validator in `adasouls-contracts/cardano/agent_drep` (PR #3): 27 tests; G3.2 off-chain and G3.3 preprod pending |
| G4 Delegation concierge | Not started | |
| G5 Treasury milestone verifier | Not started | |
| G6 Governance evidence in ALMA | Not started | |

## Log

### 2026-11-04 · G2.1 · DRep vote scripts
- Done: `scripts/lib/common.sh`, `scripts/drep-vote/01-online-build.sh` (verifies rationale hash against `decision.json`, requires anchor URL at a commit sha, builds, checks the body is one vote and nothing else, stops), `02-offline-sign.sh` (Ledger + fee key witness, assemble), `03-online-submit.sh` (the person submits, reads back gov-state). Runbook updated to anchor at a sha.
- Tests run and results: `bash -n` only. No cardano-cli in the build environment; the `transaction view` JSON field names must be confirmed in G2.3.
- Open questions: repo name in URLs (`adasouls-governance` vs `cardano-governance`); this change uses `cardano-governance`.
- Next session: G2.2 (SOULS scripts with the CIP-1694 type check), then G2.3.

<!--
### YYYY-MM-DD · G1.1 · one line on what changed
- Done:
- Tests run and results:
- Open questions:
- Next session:
-->
