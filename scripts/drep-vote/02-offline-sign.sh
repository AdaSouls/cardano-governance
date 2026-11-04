#!/usr/bin/env bash
# DRep vote, step 2 of 3 (offline machine, Ledger connected): witness with
# the DRep key on the Ledger and with the fee key, assemble. The fee key
# path is given by the person running this; this script never reads it
# for anything but the cardano-cli call.
#
# usage: scripts/drep-vote/02-offline-sign.sh vote.raw drep.hwsfile /path/to/fees.skey
# Output: vote.signed. Copy it back to the USB stick for 03-online-submit.sh.

HERE=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=../lib/common.sh
. "$HERE/lib/common.sh"
need cardano-cli cardano-hw-cli jq

RAW="${1:?unsigned transaction (vote.raw)}"; HWS="${2:?drep.hwsfile}"; FEES_SKEY="${3:?path to fees.skey on this machine}"
[ -f "$RAW" ] || die "missing $RAW"
[ -f "$HWS" ] || die "missing $HWS"
[ -f "$FEES_SKEY" ] || die "missing $FEES_SKEY"

check_tx_body "$RAW"
echo
echo "Confirm on the Ledger: the action id, the vote and the anchor must match the summary printed by 01-online-build.sh."
read -r -p "Continue to sign? [y/N] " ok; [ "$ok" = "y" ] || die "stopped before signing"

cardano-hw-cli transaction transform --tx-file "$RAW" --out-file vote.tx
cardano-hw-cli transaction witness --tx-file vote.tx --hw-signing-file "$HWS" $NETWORK_FLAG --out-file drep.witness
cardano-cli conway transaction witness --tx-body-file vote.tx --signing-key-file "$FEES_SKEY" $NETWORK_FLAG --out-file fee.witness
cardano-cli conway transaction assemble --tx-body-file vote.tx --witness-file drep.witness --witness-file fee.witness --out-file vote.signed
rm -f fee.witness
echo "vote.signed written. Copy it to the USB stick; leave fees.skey here."
