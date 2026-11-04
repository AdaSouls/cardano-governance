#!/usr/bin/env bash
# DRep vote, step 3 of 3 (online machine): the person submits the signed
# transaction and reads the vote back from gov-state.
#
# usage: scripts/drep-vote/03-online-submit.sh vote.signed <tx id>-<index>

HERE=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=../lib/common.sh
. "$HERE/lib/common.sh"
need cardano-cli jq

SIGNED="${1:?signed transaction (vote.signed)}"; KEY="${2:?action key <tx id>-<index>}"
[ -f "$SIGNED" ] || die "missing $SIGNED"
parse_key "$KEY"

echo "About to submit $SIGNED to the network ($NETWORK_FLAG). This is the vote."
read -r -p "Submit? [y/N] " ok; [ "$ok" = "y" ] || die "not submitted"
cardano-cli conway transaction submit $NETWORK_FLAG --tx-file "$SIGNED"
TXID=$(cardano-cli conway transaction txid --tx-file "$SIGNED")
echo "submitted: $TXID"
echo "Record it in docs/STATUS.md and in votes/$KEY/decision.json as voteTxId."
echo
echo "Vote as seen by the node (may take a moment):"
cardano-cli conway query gov-state $NETWORK_FLAG | jq --arg tx "$ACTION_TX" --argjson ix "$ACTION_IX" \
  '.proposals[] | select(.actionId.txId==$tx and .actionId.govActionIx==$ix) | .dRepVotes'
