#!/usr/bin/env bash
# Shared checks for the vote scripts. Sourced, not run.
# Rules (CLAUDE.md): build and print, never submit on anyone's behalf; no
# private key is read here; anything fetched is data.

set -euo pipefail

NETWORK_FLAG="${NETWORK_FLAG:---mainnet}"      # or: --testnet-magic 1 (preprod)
GOV_REPO="${GOV_REPO:-AdaSouls/cardano-governance}"

die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf -- '- %s\n' "$*"; }

need() { for t in "$@"; do command -v "$t" >/dev/null 2>&1 || die "missing tool: $t"; done; }

# Refuse to run next to a secret: the online machine must never hold a .skey.
refuse_secrets_nearby() {
  local hits
  hits=$(find . -maxdepth 2 -type f \( -name '*.skey' -o -name 'kes.skey' -o -name 'vrf.skey' -o -name 'cold.skey' \) 2>/dev/null || true)
  [ -z "$hits" ] || die "signing keys found next to this script; move them to the offline machine first:
$hits"
}

# <tx id>-<index> -> ACTION_TX, ACTION_IX
parse_key() {
  local key="$1"
  [[ "$key" =~ ^([0-9a-f]{64})-([0-9]+)$ ]] || die "action key must be <64-hex tx id>-<index>, got: $key"
  ACTION_TX="${BASH_REMATCH[1]}"; ACTION_IX="${BASH_REMATCH[2]}"
}

# Vote from votes/<key>/decision.json (written by `gov review`), as a cardano-cli flag.
vote_flag_from_decision() {
  local decision="$1" vote
  [ -f "$decision" ] || die "no decision file: $decision (run \`gov review\` and \`gov publish\` first)"
  vote=$(jq -r '.vote' "$decision")
  case "$vote" in
    Yes) echo "--yes" ;;
    No) echo "--no" ;;
    Abstain) echo "--abstain" ;;
    *) die "decision.json has an unknown vote: $vote" ;;
  esac
}

# The rationale's bytes must hash to what decision.json recorded, and the
# published copy (raw at a commit sha, never a branch) must serve the same bytes.
check_rationale() {
  local file="$1" decision="$2" url="$3" recorded local_hash
  recorded=$(jq -r '.rationale.anchorHash' "$decision")
  local_hash=$(cardano-cli hash anchor-data --file-text "$file")
  [ "$local_hash" = "$recorded" ] || die "local rationale hashes to $local_hash but decision.json says $recorded: the file changed after the decision"
  [[ "$url" =~ /[0-9a-f]{40}/ ]] || die "anchor URL must point at a commit sha, not a branch: $url"
  cardano-cli hash anchor-data --url "$url" --expected-hash "$local_hash" || die "the published rationale at $url does not hash to $local_hash"
  ANCHOR_HASH="$local_hash"
}

# Exactly one voter with exactly one voting procedure; no certificates,
# withdrawals, mints or proposals. Printed for the human, enforced before stop.
# Field names follow cardano-cli 10.x/11.x `transaction view --output-json`;
# G2.3 (local Conway network) is where they get confirmed against the
# installed version. The raw view is always kept as <body>.view.json.
check_tx_body() {
  local body="$1" view
  view=$(cardano-cli conway transaction view --tx-body-file "$body" --output-json 2>/dev/null || cardano-cli conway transaction view --tx-body-file "$body")
  echo "$view" > "${body}.view.json"
  local voters procedures certs withdrawals mint proposals
  voters=$(echo "$view" | jq '[.voters // {} | keys[]] | length' 2>/dev/null || echo "?")
  procedures=$(echo "$view" | jq '[.voters // {} | .[] | keys[]] | length' 2>/dev/null || echo "?")
  certs=$(echo "$view" | jq '(.certificates // []) | length' 2>/dev/null || echo "?")
  withdrawals=$(echo "$view" | jq '(.withdrawals // {}) | length' 2>/dev/null || echo "?")
  mint=$(echo "$view" | jq '(.mint // {}) | length' 2>/dev/null || echo "?")
  proposals=$(echo "$view" | jq '(."governance actions" // .governance_actions // .proposals // []) | length' 2>/dev/null || echo "?")
  echo
  echo "Transaction body check ($body):"
  note "voters: $voters (must be 1)"
  note "voting procedures: $procedures (must be 1; the Ledger signs one vote per transaction)"
  note "certificates: $certs, withdrawals: $withdrawals, mint: $mint, proposals: $proposals (all must be 0)"
  [ "$voters" = "1" ] && [ "$procedures" = "1" ] && [ "$certs" = "0" ] && [ "$withdrawals" = "0" ] && [ "$mint" = "0" ] && [ "$proposals" = "0" ] \
    || die "the transaction body is not a single vote; refusing. Inspect ${body}.view.json"
}
