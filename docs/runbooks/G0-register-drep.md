# Register the AdaSouls DRep

Matías runs this, once. The DRep key lives on the Ledger Nano X; the fee key stays on the offline machine. Nothing secret goes on the USB stick: only `.vkey`, `.hwsfile` (path and public key), unsigned and signed transactions, and witnesses.

Tested with cardano-cli 11.2.3 against a local Conway network: registration with a metadata anchor, a DRep vote with a rationale, and an SPO vote with the cold key witnessed separately. The Ledger steps follow cardano-hw-cli 1.20 and the Cardano app 8.x, which export DRep keys (path `1852H/1815H/<account>H/3/0`) and sign DRep certificates and votes. Check every screen the first time.

## What you need

- About 501 ADA in `fees.addr`: the deposit is 500 ADA (refunded when the DRep retires) plus the fee. Check the current deposit with `cardano-cli conway query protocol-parameters --mainnet | jq .dRepDeposit`.
- The repo `AdaSouls/adasouls-governance` public, with `policies/` and `drep/metadata.jsonld` final. `transaction build` downloads the metadata and checks its hash, so it must be online first.

## 1. Offline, with the Ledger: export the DRep key

```bash
cardano-hw-cli address key-gen --path 1852H/1815H/0H/3/0 \
  --verification-key-file drep.vkey --hw-signing-file drep.hwsfile
cardano-cli conway governance drep id --drep-verification-key-file drep.vkey --out-file drep.id
cat drep.id   # drep1..., your public DRep ID
```

Copy `drep.vkey`, `drep.hwsfile` and `drep.id` to the USB stick.

## 2. Online: publish and hash the metadata

1. Edit `drep/metadata.jsonld` until you're happy with every word: your name, objectives, motivations, qualifications, links.
2. Check that the logo hash in the file matches the published logo:

   ```bash
   curl -sL https://raw.githubusercontent.com/AdaSouls/cardano-stake-pool/main/logo.png | sha256sum
   ```

3. Push, then hash the published file and compare it with the local one:

   ```bash
   URL=https://raw.githubusercontent.com/AdaSouls/adasouls-governance/main/drep/metadata.jsonld
   HASH=$(cardano-cli conway governance drep metadata-hash --drep-metadata-file drep/metadata.jsonld)
   cardano-cli conway governance drep metadata-hash --drep-metadata-url "$URL" --expected-hash "$HASH"
   ```

Any later edit to the file changes the hash. After registering, an edit needs a DRep update certificate (`cardano-cli conway governance drep update-certificate`) with the new hash.

## 3. Online: certificate and unsigned transaction

```bash
DEPOSIT=$(cardano-cli conway query protocol-parameters --mainnet | jq .dRepDeposit)
cardano-cli conway governance drep registration-certificate \
  --drep-verification-key-file drep.vkey --key-reg-deposit-amt "$DEPOSIT" \
  --drep-metadata-url "$URL" --drep-metadata-hash "$HASH" --out-file drep-reg.cert
cardano-cli conway query utxo --address "$(cat fees.addr)" --mainnet
cardano-cli conway transaction build --mainnet \
  --tx-in <TXHASH#IX from fees.addr> --change-address "$(cat fees.addr)" \
  --certificate-file drep-reg.cert --witness-override 2 --out-file drep-reg.raw
```

Copy `drep-reg.raw` to the USB stick.

## 4. Offline: sign

```bash
cardano-hw-cli transaction transform --tx-file drep-reg.raw --out-file drep-reg.tx
cardano-hw-cli transaction witness --tx-file drep-reg.tx --hw-signing-file drep.hwsfile \
  --mainnet --out-file drep.witness
cardano-cli conway transaction witness --tx-body-file drep-reg.tx \
  --signing-key-file /home/usuario/cold-keys/fees.skey --mainnet --out-file fee.witness
cardano-cli conway transaction assemble --tx-body-file drep-reg.tx \
  --witness-file drep.witness --witness-file fee.witness --out-file drep-reg.signed
```

On the Ledger, approve only if it shows a DRep registration with the 500 ADA deposit, and the anchor URL and hash you published.

## 5. Online: submit and check

```bash
cardano-cli conway transaction submit --mainnet --tx-file drep-reg.signed
cardano-cli conway query drep-state --drep-verification-key-file drep.vkey --mainnet
```

Then put the DRep ID in a visible place on adasouls.io and on the X profile. CIP-119 lets you add those pages as `Identity` references in a later metadata update, so people can check the profile is yours.

## Rules from here on

- A registered DRep that doesn't vote counts as a No and becomes inactive after 20 epochs (about 100 days). Plan to vote on everything, or abstain with a reason.
- With the Ledger, one vote per transaction: cardano-hw-cli accepts a single voter with a single voting procedure. See `drep-vote.md`.
