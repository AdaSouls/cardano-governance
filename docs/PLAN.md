# Plan

Goal: show, in the open, how AI agents can help people govern Cardano without taking the decision away from them, and turn that work into reputation that ALMA can prove.

| Phase | What | Needs | Estimate |
| --- | --- | --- | --- |
| G0 Start | Policies, DRep metadata, Matías's existing DRep updated to AdaSouls, the first SOULS vote with a rationale. Matías runs it with `docs/runbooks/` | Nothing | 1 week |
| G1 Analyst | Reads every open governance action, checks its anchors, analyses it against the Constitution, drafts a rationale, records the human decision, publishes | G0 | 3 weeks |
| G2 Voting tools | Scripts for DRep votes (Ledger) and SOULS votes (cold key), with the same checks as the pool update scripts | G0 | 2 weeks |
| G3 DRep with a mandate | The agent submits only the votes a human signed; replay protection and key rotation; preprod only until audited | adasouls-contracts session F0.2 | 6 weeks |
| G4 Delegation concierge | Compares how DReps vote with what a holder says they care about; opt-in vote delegation in the SDK | G1 | 4 weeks |
| G5 Treasury milestone verifier | Checks the evidence of delivery of treasury-funded projects and publishes signed attestations | G1 | 4 weeks |
| G6 Governance evidence in ALMA | DRep and pool activity as verifiable evidence for an agent's or organisation's identity | G1, alma-core | 3 weeks |

G1 and G2 come first: AdaSouls uses its own tools before offering them. G4 and G5 can run in parallel after G1. Estimates assume one or two developers.

## Running a session

1. Branch: `git switch -c gov/G1.2-constitution`.
2. From the workspace folder: `claude --permission-mode plan`, then `/phase G1.2`, or paste the session's prompt from `docs/phases/`.
3. Read the plan Claude proposes, correct it, approve it.
4. Claude implements with tests. Read the diffs and run the tests yourself.
5. Claude updates `docs/STATUS.md` and proposes a commit message; you commit. `/clear` before the next session.
