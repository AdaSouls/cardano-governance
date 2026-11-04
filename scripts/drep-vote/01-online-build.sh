#!/usr/bin/env bash
# DRep vote, step 1 of 3 (online machine): verify the published rationale,
# create the vote, build the unsigned transaction, print what it contains,
# and stop. Nothing is signed or submitted here.
#
# usage: scripts/drep-vote/01-online-build.sh <tx id>-<index> <commit sha> <tx-in TXHASH#IX> [fees.addr] [drep.vkey]
#
#   <commit sha>  the commit in AdaSouls/cardano-governance that holds
#                 votes/<key>/rationale.jsonld; the anchor URL is the raw
#                 file at that sha, so its content can never change.
#   <tx-in>       a UTxO at fees.addr that pays the fee
#                 (cardano-cli conway query utxo --address "$(cat fees.addr)" $NETWORK_FLAG)
#
# Output: drep.vote, vote.raw (unsigned), vote.raw.view.json. Copy vote.raw
# to the USB stick for 02-offline-sign.sh.

HERE=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=../lib/common.sh
. "$HERE/lib/common.sh"
need cardano-cli jq
refuse_secrets_nearby

KEY="${1:?action key <tx id>-<index>}"; SHA="${2:?commit sha}"; TXIN="${3:?tx-in TXHASH#IX}"
FEES_ADDR_FILE="${4:-fees.addr}"; DREP_VKEY="${5:-drep.vkey}"
parse_key "$KEY"
[ -f "$FEES_ADDR_FILE" ] || die "missing $FEES_ADDR_FILE"
[ -f "$DREP_VKEY" ] || die "missing $DREP_VKEY (public key only; exported from the Ledger in G0)"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || die "second argument must be a full 40-hex commit sha, got: $SHA"

REPO_ROOT=$(cd "$HERE/.." && pwd)
DECISION="$REPO_ROOT/votes/$KEY/decision.json"
RATIONALE="$REPO_ROOT/votes/$KEY/rationale.jsonld"
[ -f "$RATIONALE" ] || die "missing $RATIONALE"
URL="https://raw.githubusercontent.com/$GOV_REPO/$SHA/votes/$KEY/rationale.jsonld"

VOTE_FLAG=$(vote_flag_from_decision "$DECISION")
check_rationale "$RATIONALE" "$DECISION" "$URL"

cardano-cli conway governance vote create "$VOTE_FLAG" \
  --governance-action-tx-id "$ACTION_TX" --governance-action-index "$ACTION_IX" \
  --drep-verification-key-file "$DREP_VKEY" \
  --anchor-url "$URL" --anchor-data-hash "$ANCHOR_HASH" \
  --out-file drep.vote

cardano-cli conway transaction build $NETWORK_FLAG \
  --tx-in "$TXIN" --change-address "$(cat "$FEES_ADDR_FILE")" \
  --vote-file drep.vote --witness-override 2 --out-file vote.raw

check_tx_body vote.raw

echo
echo "Ready to sign. What the Ledger will show:"
note "action:   $ACTION_TX#$ACTION_IX"
note "vote:     $(jq -r .vote "$DECISION")  (decided by $(jq -r .decidedBy.person "$DECISION") on $(jq -r .decidedAt "$DECISION"))"
note "anchor:   $URL"
note "hash:     $ANCHOR_HASH"
note "fee from: $TXIN"
echo
echo "Next: copy vote.raw to the USB stick and run scripts/drep-vote/02-offline-sign.sh on the offline machine."
echo "Nothing was signed or submitted."
