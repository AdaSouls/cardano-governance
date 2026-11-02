# Turn the existing DRep into the AdaSouls DRep

Matías is already a DRep. Keep that DRep, with its delegations and its voting record, and change its metadata to AdaSouls with an update certificate. An update pays no deposit, and under CIP-1694 it also renews the DRep's activity.

Tested with cardano-cli 11.2.3 on a local Conway network: same key, new metadata, no deposit; the anchor changed and the DRep's expiry moved forward one epoch.

## 0. Find the DRep key

Run `mi-drep.sh <DRep ID>` from the kit (`para-vos/`) on the offline machine, with the Ledger connected and the Cardano app open. It tells you whether the DRep key is one of the pool's keys, a key file on that machine, or the DRep key of Ledger account 0 to 4. If none of those, the key is in the wallet you registered with (Eternl, Lace, Yoroi…), whose governance section shows the DRep ID.

## 1. Publish the new metadata

Same as step 2 of `G0-register-drep.md`: edit `drep/metadata.jsonld`, check the logo hash, push, then:

```bash
URL=https://raw.githubusercontent.com/AdaSouls/adasouls-governance/main/drep/metadata.jsonld
HASH=$(cardano-cli conway governance drep metadata-hash --drep-metadata-file drep/metadata.jsonld)
cardano-cli conway governance drep metadata-hash --drep-metadata-url "$URL" --expected-hash "$HASH"
```

## 2a. The key is on the Ledger

Offline, export the public key of the account `mi-drep.sh` found (here, account 0):

```bash
cardano-hw-cli address key-gen --path 1852H/1815H/0H/3/0 \
  --verification-key-file drep.vkey --hw-signing-file drep.hwsfile
```

Online, build:

```bash
cardano-cli conway governance drep update-certificate --drep-verification-key-file drep.vkey \
  --drep-metadata-url "$URL" --drep-metadata-hash "$HASH" --out-file drep-update.cert
cardano-cli conway transaction build --mainnet \
  --tx-in <TXHASH#IX from fees.addr> --change-address "$(cat fees.addr)" \
  --certificate-file drep-update.cert --witness-override 2 --out-file drep-update.raw
```

Offline, sign:

```bash
cardano-hw-cli transaction transform --tx-file drep-update.raw --out-file drep-update.tx
cardano-hw-cli transaction witness --tx-file drep-update.tx --hw-signing-file drep.hwsfile \
  --mainnet --out-file drep.witness
cardano-cli conway transaction witness --tx-body-file drep-update.tx \
  --signing-key-file /home/usuario/cold-keys/fees.skey --mainnet --out-file fee.witness
cardano-cli conway transaction assemble --tx-body-file drep-update.tx \
  --witness-file drep.witness --witness-file fee.witness --out-file drep-update.signed
```

Online, submit and check:

```bash
cardano-cli conway transaction submit --mainnet --tx-file drep-update.signed
cardano-cli conway query drep-state --drep-verification-key-file drep.vkey --mainnet
```

## 2b. The key is a file on the offline machine

Offline, get the public key to carry online (the `.skey` stays where it is):

```bash
cardano-cli conway key verification-key --signing-key-file <path to the DRep .skey> \
  --verification-key-file drep.vkey
```

Online, build exactly as in 2a. Offline, sign without the Ledger:

```bash
cardano-cli conway transaction witness --tx-body-file drep-update.raw \
  --signing-key-file <path to the DRep .skey> --mainnet --out-file drep.witness
cardano-cli conway transaction witness --tx-body-file drep-update.raw \
  --signing-key-file /home/usuario/cold-keys/fees.skey --mainnet --out-file fee.witness
cardano-cli conway transaction assemble --tx-body-file drep-update.raw \
  --witness-file drep.witness --witness-file fee.witness --out-file drep-update.signed
```

Online, submit and check as in 2a.

## 2c. The key is in a wallet

Update the DRep from that wallet's governance section, or from GovTool connected to it, and point it at the metadata URL above. If the tool builds its own file from a form instead, copy the texts and links from `drep/metadata.jsonld` and host the file it gives you in this repo.

## 3. Tell your delegators

They delegated to you as a person. Announce that the DRep now votes as AdaSouls, with you as the human who decides and signs, and link the conflict of interest policy. Anyone who prefers can redelegate.
