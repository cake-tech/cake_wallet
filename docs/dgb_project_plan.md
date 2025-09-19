# DigiByte (DGB) Integration Plan for Cake Wallet

This plan breaks the DigiByte listing effort into implementation phases, ensuring that we stage code changes in the order required by Cake Wallet's architecture. Each phase calls out the artifacts we must add or modify, internal dependencies, and any external resources still needed from the DigiByte team or community.

## Phase 0 – Discovery & Requirements
- ✅ Confirm existing DigiByte currency metadata in `cw_core/lib/crypto_currency.dart` (ticker, display name, icon, decimals).
- ☐ Gather canonical Electrum server inventory and uptime data to seed the default node list.
- ☐ Validate JSON-RPC compatibility (e.g. `digibyted` version, pruning requirements, fee policy) for potential full node support.
- ☐ Obtain official contacts for escalation (foundation/maintainers) to include with listing submission.

**Resources Needed from DigiByte representatives**
1. Endorsed Electrum servers (at least three, SSL-enabled) with operator contacts for ongoing maintenance.
2. Confirmation of minimum node version that Cake Wallet should target.
3. Guidance on any DigiByte-specific transaction relay quirks (e.g. DigiShield, MultiAlgo) that could affect fee estimation.
4. Optional: Community-run public RPC endpoints if we decide to surface full-node connectivity.

## Phase 1 – Core Type & Assets
Goal: teach the shared core about the new wallet type so that UI scaffolding and dependency injection recognize DigiByte.


- ✅ Add `WalletType.digibyte` enum value and update all switch statements (`walletTypeToString`, `walletTypeToDisplayName`, serialization helpers, etc.).
- ✅ Map DigiByte to its currency via `walletTypeToCryptoCurrency` and `cryptoCurrencyToWalletType`.
- ✅ Register DigiByte in the generated wallet type lists (`tool/configure.dart`, `scripts/*/app_config.sh`) to unblock proxy generation.
- ✅ Extend `lib/entities/node_list.dart` to load DigiByte default nodes and ensure `resetToDefault` persists them.
- ✅ Ship `assets/digibyte_electrum_server_list.yml` and register it in `pubspec_base.yaml`.
- [ ] Add `WalletType.digibyte` enum value and update all switch statements (`walletTypeToString`, `walletTypeToDisplayName`, serialization helpers, etc.).
- [ ] Map DigiByte to its currency via `walletTypeToCryptoCurrency` and `cryptoCurrencyToWalletType`.
- ✅ Register DigiByte in the generated wallet type lists (`tool/configure.dart`, `scripts/*/app_config.sh`) to unblock proxy generation.
- [ ] Extend `lib/entities/node_list.dart` to load DigiByte default nodes and ensure `resetToDefault` persists them.
- [ ] Ship `assets/digibyte_electrum_server_list.yml` and register it in `pubspec_base.yaml`.

## Phase 2 – Node Defaults & Settings Migration
Goal: guarantee that new installs and migrations receive functional DigiByte nodes.

- [ ] Define DigiByte default node URI constants and helpers in `lib/entities/default_settings_migration.dart` (mirroring Dogecoin).
- [ ] Wire DigiByte into `addWalletNodeList`, `_changeDefaultNode`, and migration switch cases.
- [ ] Add persistent storage keys in `lib/entities/preferences_key.dart` for tracking the current DigiByte node.

## Phase 3 – DigiByte Wallet Package (`cw_digibyte`)
Goal: encapsulate DigiByte Electrum integration in a dedicated package, following the Bitcoin-family architecture.

- ✅ Scaffold `cw_digibyte` package with wallet service, wallet class, address management, transaction priority, etc. (reference `cw_dogecoin`).
- [ ] Add build scripts (`model_generator.sh`, `scripts/*/app_config.sh`) to include DigiByte package in generated outputs.
- [ ] Implement DigiByte-specific constants (SLIP44 coin type 20, network magic, address prefixes, fee policy) inside the package.
- [ ] Provide unit tests that cover balance parsing, transaction decoding, and fee rate calculation for DigiByte.

## Phase 4 – Proxy Wiring & Dependency Injection
Goal: expose DigiByte functionality to the application layer via generated proxies.

- ✅ Create proxy configuration entries in `tool/configure.dart` and run the generator to produce `lib/digibyte/digibyte.dart`.
- [ ] Register DigiByte services in dependency injection (`lib/di.dart`) and wallet creation flows (`lib/view_model/wallet_new_vm.dart`, etc.).
- [ ] Update UI selectors, routing, and localization strings to surface DigiByte in wallet creation/import screens.

## Phase 5 – QA, Documentation & Submission Packet
Goal: finish the listing packet with test evidence and handoff notes.

- [ ] Document QA checklist results (sync, send, receive on mainnet/testnet if available).
- [ ] Update `docs/dgb_listing_requirements.md` with final node list, maintainers, and test logs.
- [ ] Prepare submission summary for Cake Wallet maintainers.
- [ ] Refresh top-level documentation (README, changelog highlights, marketing copy) to call out DigiByte support once feature-complete.

---

Tracking this checklist inside the repository keeps the effort transparent and makes it easy to raise follow-up PRs for each phase. As we progress, we'll convert the checkbox items to ✅ with links to the corresponding commits.
