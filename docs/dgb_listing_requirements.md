# DigiByte (DGB) Listing Package for Cake Wallet

This document captures the information Cake Wallet typically requires when assessing a new asset listing request. It collates the core data for DigiByte (DGB) and highlights any remaining gaps that should be resolved before submitting the listing application.

## 1. Asset Overview

| Field | Details |
| --- | --- |
| Asset name | DigiByte |
| Ticker | DGB |
| Asset type | Native UTXO blockchain (Bitcoin-codebase derivative) |
| Launch date | 10 January 2014 |
| Website | https://digibyte.org |
| Whitepaper | https://digibyte.org/whitepaper |
| Open-source repository | https://github.com/DigiByte-Core/digibyte |
| License | MIT (inherits Bitcoin Core licensing) |
| Logo | `assets/images/digibyte.png` (already present in repository) |
| Supported decimals | 8 (matches `CryptoCurrency.digibyte` entry) |
| BIP44 coin type | 20 |
| Block explorers | https://digiexplorer.info, https://chainz.cryptoid.info/dgb/, https://dgb.tokenview.com/en |
| Social / community | https://twitter.com/DigiByteCoin, https://t.me/DigiByteCoin |

## 2. Technical Parameters

* **Consensus:** MultiShield Proof-of-Work employing five algorithms (SHA-256, Scrypt, Skein, Groestl, and Qubit) with real-time difficulty adjustment.
* **Average block time:** ~15 seconds (a new block from each algorithm roughly every 75 seconds).
* **Maximum supply:** 21,000,000,000 DGB (scheduled to be reached around 2035).
* **Emission schedule:** Block reward decreases by 1% every month; no premine or ICO.
* **SegWit & address formats:** Supports legacy P2PKH (`D...`), P2SH (`3...`), and bech32 SegWit (`dgb1...`).
* **Transaction fees:** Bitcoin-style fee market denominated in satoshis per byte; SegWit adoption keeps typical fees below a few cents at 1–2 sat/byte.
* **BIP32 path:** `m/44'/20'/account'/change/index` for legacy, `49'` and `84'` variations for nested SegWit and native SegWit derivations respectively.
* **Network ports:** Default P2P port `12024`, default RPC port `14022` (configurable).

## 3. Network Infrastructure & Wallet Compatibility

* **Reference full node implementation:** `digibyted` (from the DigiByte Core repository). Supports JSON-RPC identical to Bitcoin Core; Cake Wallet integration can reuse existing Bitcoin RPC abstractions with chain-specific parameters (coin type 120 and message start string adjustments).
* **Public JSON-RPC endpoints for initial testing:**
  * `https://digiexplorer.info/api` (read-only REST for quick testing, not a full RPC substitute).
  * Community-hosted RPC nodes are available through the DigiByte Alliance; production integration is expected to run Cake-hosted nodes for reliability. (Action item: confirm which internally managed nodes can be exposed.)
* **Electrum ecosystem:** DigiByte supports ElectrumX servers for light clients. Known community-maintained SSL servers include `electrum1.digibyte.host:50002`, `electrum2.digibyte.host:50002`, and `dgb-cn1.electrum.digibyte.io:50002`. These should be validated and mirrored in a new `assets/digibyte_electrum_server_list.yml` during implementation.
* **Existing wallet integrations:** DigiByte is already supported by hardware (Ledger via Electrum, Trezor), mobile (Trust Wallet, Coinomi, Edge, Exodus), and desktop (DigiByte Core, Atomic). This demonstrates mature third-party support and mature tooling.

## 4. Security, Compliance, and Maintenance

* **Security model:** Open-source, audited codebase with nearly a decade of production history and broad community node distribution (>300,000 full nodes historically reported). MultiShield protects against sudden hashrate swings on any algorithm.
* **Protocol upgrades:** Consensus changes are coordinated by the DigiByte Core developers and DigiByte Awareness Team; improvement proposals are tracked in the `DGBIPs` repository. Recent upgrades focused on SegWit adoption, Odocrypt (for FPGA resistance), and Digi-ID.
* **Ecosystem governance:** DigiByte is decentralized with no company ownership. The DigiByte Foundation (non-profit) and DigiByte Awareness Team handle outreach. Key contacts: `foundation@digibytefoundation.org` (foundation) and `hello@digibyte.io` (ecosystem coordination).
* **Regulatory posture:** Pure PoW utility token with no premine/ICO. Trading widely available on regulated exchanges (e.g., Bittrex, Coinbase custody support, KuCoin). No known securities enforcement actions.

## 5. Integration Checklist for Cake Wallet

1. **Wallet type plumbing** – Add a `WalletType.digibyte` entry in `cw_core/lib/wallet_type.dart`, update serialization helpers, and surface the human-readable name in `walletTypeToString`/`walletTypeToDisplayName`.
2. **Currency configuration** – The DigiByte asset is already declared in `cw_core/lib/crypto_currency.dart` (`CryptoCurrency.digibyte`) with ticker, icon, and 8 decimals. Ensure it is wired to the new wallet type once implemented. 【F:cw_core/lib/crypto_currency.dart†L215-L237】
3. **Node bootstrapping** – Default DigiByte Electrum endpoints are now shipped in `assets/digibyte_electrum_server_list.yml` and automatically registered by `lib/entities/node_list.dart` for new installs and migrations.
4. **Proxy package** – Scaffold a `cw_digibyte` package following the process documented in `docs/NEW_WALLET_TYPES.md` (code generation hooks, proxy wiring, DI registration, etc.). 【F:docs/NEW_WALLET_TYPES.md†L1-L120】
5. **Node configuration scripts** – Extend Android/iOS/macOS configuration scripts to include the DigiByte flag once the proxy package exists (see Section “Configuration Files Setup” in the same guide).
6. **Testing** – Sync against mainnet using a trusted node, validate send/receive flows, and ensure exchange integrations display correct decimal handling (8 decimals as per Step 2).

## 6. Outstanding Items / Data to Confirm

* Provide a list of Cake-controlled DigiByte Electrum or RPC nodes (hostname, ports, SSL) for production configuration.
* Decide when to enable the DigiByte proxy/package generation flag in `tool/configure.dart` and platform scripts once wallet service wiring is ready.
* Share updated contact details for the technical lead(s) responsible for coordinating with Cake Wallet should protocol updates occur.
* Confirm whether DigiByte requires any additional derivation paths beyond standard BIP44/49/84 for compatibility with existing user seeds.
* Supply any marketing collateral (brand guidelines, icon usage rights) if Cake Wallet requires explicit approval for app store submissions.