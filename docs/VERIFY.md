# Verifying Cake Wallet downloads

Every Cake Wallet binary we publish can be checked before you run it. Verification answers
two separate questions:

1. **Integrity** — is this the exact file we published, byte for byte?
2. **Authenticity** — was it published by us, and not by someone who got access to the
   download page?

A SHA-256 hash on its own only answers the first question, and only if you trust the page
you read the hash from. The signed checksum file described below answers both.

> The release key on this page is **not** the same as the vulnerability-reporting key in
> [SECURITY.md](SECURITY.md). That key (`DC91 6520 ... 0E4D 3A0A`) is for sending us
> encrypted reports. The key below is the one we sign releases with.

---

## The Cake Wallet release key

```
Fingerprint:  22F5 6E80 9E09 4449 89AF  A8E0 23FE 0560 9FFB 3E7C
Identity:     Omar Hatem <omar@cakewallet.com>
Algorithm:    Ed25519, created 2026-09-18
```

The simplest way to fetch it is by address — GnuPG finds it through
[Web Key Directory](https://wiki.gnupg.org/WKD) on cakewallet.com:

```bash
gpg --locate-keys omar@cakewallet.com
```

Two other sources serve the same key, if you prefer one of them or your GnuPG is older than
2.1.12:

```bash
# Our domain, directly
curl -sS https://cakewallet.com/.well-known/cakewallet-release.asc | gpg --import

# Public keyserver
gpg --keyserver hkps://keys.openpgp.org --recv-keys 22F56E809E09444989AFA8E023FE05609FFB3E7C
```

**Always confirm the fingerprint matches the one printed above.** Fetching a key over the
network proves nothing by itself; the fingerprint is what you are trusting. The sources are
controlled by different parties — cakewallet.com proves control of the domain, keys.openpgp.org
proves control of the address — so seeing the same fingerprint in both is meaningfully stronger
than seeing it in one.

The same key signs both the release tag and `SHA256SUMS`, so whoever tagged the source is
demonstrably whoever signed the binaries.

---

## Verifying a release download

Releases that ship `SHA256SUMS` and `SHA256SUMS.asc` can be verified with the three steps
below, on any platform. Older releases list SHA-256 hashes in the release notes only; for
those, compare the hash by hand.

Download the two files from the same GitHub release page as the binary, and put all three in
the same directory.

### 1. Import the release key

See above. You only need to do this once.

### 2. Check the signature on the checksum file

```bash
gpg --verify SHA256SUMS.asc SHA256SUMS
```

You are looking for:

```
gpg: Good signature from "Omar Hatem <omar@cakewallet.com>"
Primary key fingerprint: 22F5 6E80 9E09 4449 89AF  A8E0 23FE 0560 9FFB 3E7C
```

You will probably also see this, and it is **not** a failure:

```
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
```

That warning only means you have not personally marked the key as trusted in your own
keyring. It appears every time until you do. What matters is `Good signature` together with
a fingerprint that matches. If you want the warning gone, sign the key locally:

```bash
gpg --lsign-key 22F56E809E09444989AFA8E023FE05609FFB3E7C
```

A `BAD signature` result, or a different fingerprint, means the file has been altered. Stop
and do not install anything.

### 3. Check the binary against the checksum file

Linux:

```bash
sha256sum --check --ignore-missing SHA256SUMS
```

macOS:

```bash
shasum -a 256 --check --ignore-missing SHA256SUMS
```

Expected output, one line per file you actually downloaded:

```
Cake_Wallet_v6.5.0.dmg: OK
```

`--ignore-missing` is what lets you download a single file instead of every artifact in the
release. Without it, the command reports an error for each file you don't have.

---

## Platform-specific signatures

The signed checksum file covers every artifact we publish. Most platforms also carry their
own native code signature, which you can check independently.

### Android (`.apk`)

APKs on GitHub, Accrescent and F-Droid are all signed with the same key:

```bash
apksigner verify --print-certs Cake_Wallet_v6.5.0-arm64-v8a.apk
```

```
Signer #1 certificate DN: CN=Magic, OU=IT, O=Cake Wallet LTD, L=New York, ST=New York, C=US
Signer #1 certificate SHA-256 digest: c54053ab0f10d9541762a3da7665ae3dba5e7c743ab4f108a5349d62ac106ef5
```

The Monero.com builds use the same certificate.

Our APKs use **APK Signature Scheme v2 only** — there is no v1 (JAR) signature — so
`keytool -printcert -jarfile` will not work on them. Use `apksigner` from the Android SDK
build-tools, or [AppVerifier](https://github.com/soupslurpr/AppVerifier) on-device.

If Android refuses to install the APK over an existing copy with a signature-mismatch error,
that copy was signed by a different key. **Back up your seeds first**, then uninstall and
reinstall.

### macOS (`.dmg`)

The disk image is signed with a Developer ID certificate and notarized by Apple:

```bash
codesign -dv --verbose=4 Cake_Wallet_v6.5.0.dmg
spctl -a -t open --context context:primary-signature -v Cake_Wallet_v6.5.0.dmg
xcrun stapler validate Cake_Wallet_v6.5.0.dmg
```

Expected:

```
Authority=Developer ID Application: Cake Technologies, LLC (32J6BB6VUS)
Authority=Developer ID Certification Authority
Authority=Apple Root CA
TeamIdentifier=32J6BB6VUS

Cake_Wallet_v6.5.0.dmg: accepted
source=Notarized Developer ID

The validate action worked!
```

`TeamIdentifier` is the value to pin — `32J6BB6VUS`. A Gatekeeper result of anything other
than `accepted` / `Notarized Developer ID` means the file should not be opened.

### Linux (`.flatpak`, `.tar.xz`)

Linux artifacts carry no separate code signature, so `SHA256SUMS` and `SHA256SUMS.asc` are
the verification path. Check them **before** installing.

The Flatpak bundle currently contains no embedded OpenPGP signature. As a result,
`flatpak install --bundle` creates its origin remote with `gpg-verify=false`. This is
expected, and it is why the checksum file matters: verify the `.flatpak` with step 3 above,
then install the file you verified.

```bash
sha256sum --check --ignore-missing SHA256SUMS
flatpak install --user --bundle Cake_Wallet_Linux.flatpak
```

### Windows (`.exe`)

Windows installers are Authenticode-signed. In PowerShell:

```powershell
Get-AuthenticodeSignature .\Cake_Wallet_Windows.exe | Format-List
```

The signature chains to `DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1`, and the
publisher is `Cake Labs Inc` — the same name Windows shows in the UAC prompt as the verified
publisher. `Status` must be `Valid`.

Note that recent 6.x releases do not include a Windows build.

### iOS

iOS is distributed through the App Store, which performs its own signature checks on
install. There is nothing for you to verify manually; installing from the App Store is the
verification.

---

## Verifying the source

Releases that ship `SHA256SUMS` also carry a signed Git tag, made with the same release key,
so you can confirm which revision a release was built from. Earlier tags are unsigned and
`git verify-tag` will report `no signature found` for them.

```bash
git fetch --tags
git verify-tag v<version>
```

Individual commits merged through GitHub's web interface are signed by GitHub's own key
rather than a maintainer key. That is normal and is what GitHub's "Verified" badge shows.

Building from source gives you a binary you audited yourself, but it will not be
byte-identical to ours — our builds are not yet reproducible, so you cannot use a local build
to verify a published one. Use the signed checksums for that.

---

## If verification fails

Do not install or run the file.

Re-download it first, in case the download was simply truncated or corrupted. If it still
fails, please tell us through one of the private channels in [SECURITY.md](SECURITY.md) —
`security@cakewallet.com`, or a
[GitHub security advisory](https://github.com/cake-tech/cake_wallet/security/advisories/new).
Include which file, which release, and the exact output you saw.
