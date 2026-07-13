# Guide: Adding a New EVM L2 Network

This is the complete, current process for adding an EVM-compatible chain (L1 or L2) to Cake Wallet. Everything you need is in this document — read it top to bottom before starting.

---

## What is (and isn't) shared

EVM chains share the `cw_evm` package, the `EvmChainRegistry`, the single `EVMChainWallet` class, and the generic `EVMChainClient`. Operations are keyed by `chainId`.

They do **not** share their identity. **There is no `WalletType.evm`.** Every EVM chain has:

- its **own `WalletType` enum value**, and
- its **own native `CryptoCurrency`** (e.g. `baseEth`, `arbEth`, `robEth`).

Because of that, adding a chain fans out to **~50–65 files** — almost all of them exhaustive `switch (walletType)` arms that the Dart analyzer will point you to.

You do **not** create:

- a `cw_<chain>/` package (EVM chains live in `cw_evm`),
- a `lib/<chain>/<chain>.dart` proxy (the unified `lib/evm/evm.dart` proxy handles every EVM chain via `chainId`),
- any new Hive storage (see the persistence table below — nodes and wallet metadata are SQLite now).

---

## The reliable method

1. Gather the chain facts (below).
2. Add the `WalletType` enum value **first** (Step A1).
3. Run `dart analyze` in `cw_core`, `cw_evm`, and `lib/`. It lists **every** exhaustive `switch (walletType)` that now needs the new arm — that is your worklist.
4. Fill in the arms. **Rule of thumb:** wherever `WalletType.bsc` is handled, the new chain usually joins the same group — *except* fee/priority behaviour, where an Optimistic-rollup / no-priority-fee chain (Arbitrum, Robinhood Chain) mirrors `**WalletType.arbitrum`** instead. Grep for **both** `WalletType.bsc` and `WalletType.arbitrum` — some groups (e.g. the null-priority allow-lists) only contain `arbitrum`.
5. Wire nodes, build flags, UI/logo, tokens.
6. Verify (checklist at the end).

---

## Prerequisites — chain facts you must confirm (no guesses)

- **Chain ID** (decimal). Cross-check on [https://chainlist.org](https://chainlist.org) and the chain's official docs — a wrong chainId silently signs for the wrong network.
- **Network name** and a short code / tag.
- **Native currency** (almost always ETH for an L2).
- **Public RPC endpoint(s)**.
- **Block explorer** URL, and **whether it is Etherscan-family or Blockscout** (this decides the transaction-history client — see "Blockscout explorers").
- **Fee model** — does the chain use EIP-1559 priority fees? Optimistic rollups (Arbitrum Orbit, etc.) generally do **not**.
- **Default ERC20 tokens** and their contract addresses — verify each address from the block explorer, never from memory.

---

## Persistence reference (what lives where — read before writing storage code)


| Concern                                 | Mechanism today                                                                                                                                                                                                                        | Notes                                                                                                                                 |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Nodes / node list**                   | **SQLite** (`Node` table in `cw_core/lib/db/sqlite.dart`, since schema v7)                                                                                                                                                             | Seeded from `assets/<chain>_node_list.yml` via the settings migration; `addWalletNodeList` does `node.save()` = SQL insert.           |
| **Wallet info / list**                  | **SQLite** (schema v9)                                                                                                                                                                                                                 | `WalletInfo.type` is an int via `serializeToInt`. No schema change to add a chain.                                                    |
| `**WalletType`**                        | **Dual codec** — the hand-maintained Hive adapter (`wallet_type.part.dart`, enum-ordinal byte) **and** `serializeToInt`/`deserializeFromInt` (a *different* offset int, used by the SQLite `WalletInfo.type` / `Node.typeRaw` columns) | Both append-only. A wrong value corrupts persisted wallets.                                                                           |
| `**CryptoCurrency`**                    | In-memory constant, `raw` int (persisted only inside `Trade`/`Contact`)                                                                                                                                                                | Add a const + register it in the `all` list.                                                                                          |
| **ERC20 token boxes**                   | **Hive** (`Box<Erc20Token>` per wallet)                                                                                                                                                                                                | The one add-chain touchpoint still on Hive. Unknown chainId silently falls back to the Ethereum box — you must add the box-name case. |
| **EVM tx history**                      | Flat encrypted JSON file (`transactions_<chainId>.json`)                                                                                                                                                                               | Never Hive/SQL.                                                                                                                       |
| **Settings / prefs / selected node id** | `SharedPreferences`                                                                                                                                                                                                                    | Never Hive.                                                                                                                           |


**Do not add new Hive storage.** The only Hive touchpoint is the ERC20 token box name (which follows the existing pattern).

---

## Step A — Identity & persistence (`cw_core`)

### A1. `cw_core/lib/wallet_type.dart` — the enum and its codecs (highest risk)

Append the new value at the **end** of the enum (never insert in the middle — the Hive adapter serializes by ordinal):

```dart
enum WalletType {
  // ... existing, ending with bsc ...
  // @HiveField(20)
  robinhood,
}
```

Then extend, **in lockstep** (the Dart compiler enforces exhaustiveness on the switches, so it will stop you if you miss one):

- `serializeToInt` → next int (e.g. `19`) and `deserializeFromInt` → matching `case`. **These back the SQLite columns.**
- `walletTypeToString`, `walletTypeToDisplayName`, `walletTypeToDisplayTicker`, `_cryptoCurrencyToWalletType`.
- the `walletTypes` and `evmWalletTypes` lists (not `electrumWalletTypes`).

> The **enum-ordinal byte** (used by the Hive adapter) and the `**serializeToInt` int** are different numbers (e.g. `bsc` is byte 19 / int 18). Keep both append-only.

### A2. `cw_core/lib/wallet_type.part.dart` — the Hive adapter

This file is headed "GENERATED", but the enum's `@HiveType`/`@HiveField` annotations are **commented out**, so `build_runner` will **not** regenerate it. **Hand-add** the next byte to `WalletTypeAdapter.read()` (a `case`) and `write()` (a `writeByte(...)`), matching the enum ordinal.

### A3. `cw_core/lib/crypto_currency.dart` — the native currency

Add a native `CryptoCurrency` const with the **next free `raw`** (scan all `raw:` values; they are contiguous). Mirror `baseEth`/`arbEth`:

```dart
static const robEth = CryptoCurrency(
  title: 'ETH', tag: 'ROB', fullName: 'Ethereum', raw: 111, name: 'robeth',
  iconPath: 'assets/new-ui/crypto_full_icons/ethereum.svg', decimals: 18,
  flatIconPath: "assets/new-ui/crypto_full_icons/robinhood.svg",   // chain logo (see Step F)
  chainIconPath: "assets/new-ui/crypto_full_icons/robinhood.svg");
```

- Add the const to the `**all` list** (otherwise it won't deserialize).
- Add a `_schemeCurrencyMap` entry keyed by the **lowercased tag** (e.g. `'rob': robEth`) — this is what makes `cryptoCurrencyOrTokenToWalletType(robEth)` resolve. Add the URI scheme key too if you add a payment URI (Step A7).

### A4. `cw_core/lib/currency_for_wallet_type.dart`

Add arms to: `walletTypeToCryptoCurrency` (exhaustive), `getCryptoCurrencyByChainId` (`4663 → robEth`), `getChainIdByCryptoCurrency` (`robEth → 4663`). For the wallet-list logo, add a case to `getCryptoCurrencyIconForWalletListItem` (Step F).

### A5. `cw_core/lib/erc20_token.dart`

Add a box-name const: `static const robinhoodBoxName = 'RobinhoodErc20Tokens';`. (`Erc20Token` already supports a `groups` param — used for tokenized-stock grouping, Step E.)

### A6. `cw_core/lib/node.dart`

Add the new `WalletType` to the two EVM-grouped switches (`_uri` getter and `requestNode`).

### A7. `cw_core/lib/payment_uris.dart` (moved here from `lib/core/`)

Add a `<Chain>URI` class (copy `BSCURI`, pick a scheme) and add the producer arm in `lib/view_model/exchange/exchange_trade_view_model.dart`.

---

## Step B — Chain behaviour (`cw_evm`)

### B1. `cw_evm/lib/evm_chain_registry.dart` — the one mandatory registry edit

Add a `_registerChain(...)` block inside `initialize()`:

```dart
_registerChain(
  const ChainConfig(
    chainId: 4663,
    name: 'Robinhood Chain',
    shortCode: 'robinhood',
    caip2: 'eip155:4663',
    nativeCurrency: CryptoCurrency.robEth,
    capabilities: ChainCapabilities(
      supportsERC20: true, supportsEIP1559: true,
      supportsInternalTx: true, supportsSubscriptions: false, supportsENS: false,
    ),
    defaultRpcEndpoints: ['rpc.mainnet.chain.robinhood.com'],
    explorerUrls: ['https://robinhoodchain.blockscout.com'],
    feeModel: FeeModel(type: FeeType.eip1559, defaultGasLimit: 21000),
  ),
  WalletType.robinhood,
  'ROB',
);
```

Registering the chain makes it appear in the switcher and resolves the explorer link, WalletConnect namespace/name, `caip2`, and native currency automatically (all registry-driven).

### B2. `cw_evm/lib/utils/evm_chain_utils.dart` — chainId switches

Add a `case` for your chainId to (at minimum) `getErc20TokensBoxName`, `getTransactionHistoryFileName`, and `getScanProviderPreferenceKey` (these need unique per-chain values). The rest (`getDefaultTokenTag`, `getFeeCurrency`, `getDefaultTokenSymbol`) fall back to ETH sensibly but should be filled for clarity. For a **no-priority-fee** chain, mirror Arbitrum: `getTotalPriorityFee → 0` and `hasPriorityFee → false`.

### B3. Native-send allowlist — **required, or native sends crash**

The native-token check is keyed on `CryptoCurrency` identity, not chainId. Add your native currency to:

- the `assert` **and** the `isNativeToken` list in `cw_evm/lib/clients/evm_chain_client.dart`, and
- the native-currency `switch` in `cw_evm/lib/evm_chain_wallet.dart` (`createCallDataTransaction`).

Also add your chain to `_getUSDCContractAddress` in `evm_chain_wallet.dart` — return the chain's **canonical dollar stablecoin** (used for gas estimation and node health checks). If the chain has no USDC, use its equivalent (Robinhood Chain uses **USDG**); return `null` only if it truly has none.

### B4. Custom client (`cw_evm/lib/clients/<chain>_client.dart` + factory)

Add a client only if the chain needs non-default behaviour, then register it in `evm_chain_client_factory.dart` (else the default `EVMChainClient(chainId:)` is used). Two common reasons:

- **Transaction formatting.** Arbitrum-Orbit chains collapse EIP-1559 to a legacy `gasPrice` — mirror `ArbitrumClient` (override `createTransaction`, `prepareSignedTransactionForSending`, `chainId`).
- **Blockscout explorer** — see below.

### B5. `evm_chain_wallet_addresses.dart`

Add a `case` to `getPaymentUri` returning your `<Chain>URI`.

---

## Blockscout explorers

`EVMChainClient` fetches transaction history from the **Etherscan v2** unified API (`api.etherscan.io/v2/api?chainid=...`). Chains **not** on Etherscan's supported list (e.g. Robinhood Chain uses Blockscout) get an empty history from the default client.

To fix it, override `fetchTransactions` / `fetchInternalTransactions` in your client against Blockscout's **Etherscan-compatible** account API (`<host>/api?module=account&action=txlist|tokentx|txlistinternal`), and reuse the shared `@protected parseTransactions` in the base class (it does the spam-filter / merge / mapping). See `RobinhoodClient` for the exact pattern. Balances, send, and receive are RPC-only and work without this, so history can ship as a fast-follow (it fails soft to an empty list).

---

## Step C — `lib/` wiring (the analyzer-driven bulk)

After adding the enum value, `dart analyze` flags these. Most are one-line arms grouped with `bsc`/`arbitrum`.

- **WalletConnect:** `reactions/wallet_connect.dart` (`walletConnectCompatibleChains`, `isEVMCompatibleChain`, `getChainNameSpaceAndIdBasedOnWalletType`, `getChainSupportedMethodsOnWalletType`), `reactions/wallet_utils.dart` (`isBIP39Wallet`, `hasTokens`, `tokenStandardFor`), `src/screens/wallet_connect/services/chain_service/eth/evm_chain_id.dart` (enum + `_getChainIdForEnum`), `.../key_service/wallet_connect_key_service.dart` (add `'eip155:<id>'` to the chains list too).
- **Creation / validation / DI:** `lib/di.dart`, `lib/core/wallet_creation_service.dart`, `lib/core/seed_validator.dart`, `lib/entities/priority_for_wallet_type.dart` (no-priority-fee chains go in the `arbitrum → []` group).
- **Send / fees:** `lib/view_model/send/send_view_model.dart` (the EVM credential group **and** the `_credentials()` null-priority allow-list — the latter only lists `arbitrum`, so it's easy to miss and **breaks sending** if omitted), `lib/view_model/send/output.dart` (add the native currency to the `isNative` list), `lib/view_model/send/fees_view_model.dart` (no-priority-fee chains join the `→ false` `isSlow` group).
- **Settings:** `lib/view_model/settings/other_settings_view_model.dart` — `displayTransactionPriority` is a `**.contains([solana, tron, arbitrum])` exclusion list**; a no-priority-fee chain must be added or opening Other Settings for that wallet **throws**.
- **Exchange:** `exchange_view_model.dart` (default deposit pair), `exchange_trade_view_model.dart` (URI producer + `_isXToken` helper).
- **The rest:** `balance_view_model`, `dashboard_view_model`, `home_settings_view_model`, `transaction_list_item`, `transaction_details_view_model` (explorer tx URL), `wallet_keys_view_model` (also the `'<chain>-wallet'` string), `wallet_new_vm`, `wallet_restore_view_model`, `wallet_restore_from_qr_code` (the `'<chain>-wallet'` map), `advanced_privacy_settings_view_model`, `node_create_or_edit_view_model`, `utils/token_utilities.dart` (ERC20 box name), `utils/qr_util.dart` (`getQrImage` is exhaustive — needs an arm).

> `WalletType.arbitrum` parity: after wiring, grep every `WalletType.arbitrum` occurrence and confirm the new chain is present in the same **group** (fall-through `case` blocks and `.contains([...])` lists). The analyzer catches missing exhaustive-switch arms but **not** missing members of a non-exhaustive `.contains` list.

---

## Step D — Nodes, settings, migration (all SQLite/SharedPrefs, no Hive)

1. `assets/<chain>_node_list.yml` — one entry per RPC (`uri`, `useSSL: true`, `isDefault: true`, `isEnabledForAutoSwitching: true`, `label`). URI is host-only, no `https://`.
2. Bundle it in **both** `pubspec.yaml` and `pubspec_base.yaml`.
3. `cw_core/lib/node_list.dart` — add the `WalletType` → path case in `loadDefaultNodes`, and add the chain to `loadAllDefaultNodes`.
4. `lib/entities/preferences_key.dart` — `current<Chain>NodeIdKey`.
5. `lib/entities/node_check.dart` — add the chain to the `nodePreferenceKeys` map.
6. `lib/store/settings_store.dart` — `_getEVMNodePreferenceKey` (`4663 → key`), the `_changeCurrentNode` EVM group, and both node-map builder methods (the `nodeSource.firstWhereOrNull(...)` one and the `Node.get(...)` one).
7. `lib/entities/default_settings_migration.dart` — a `<chain>DefaultNodeUri` const and a new numbered `case N:` calling `addWalletNodeList(type:)` + `_changeDefaultNode(...)`.
8. `lib/main.dart` — bump `initialMigrationVersion` to `N`.

---

## Step E — Default tokens & their icons

1. `cw_evm/lib/tokens/<chain>_tokens.dart` — an `Erc20Token` list. **Verify every contract address, symbol, and decimals from the block explorer** (the token page or the Blockscout `/api/v2/tokens` JSON). Lowercase addresses to match the other token files. End the list with the standard post-processing that resolves each token's icon by symbol against `CryptoCurrency.all` and applies the chain `tag`:
  ```dart
   return tokens.map((token) {
     String? iconPath = (token.iconPath?.isEmpty ?? true)
         ? CryptoCurrency.all.firstWhereOrNull(
             (e) => e.title.toUpperCase() == token.symbol.toUpperCase())?.iconPath
         : token.iconPath;
     return Erc20Token.copyWith(token, icon: iconPath, tag: 'ROB');
   }).toList();
  ```
2. `cw_evm/lib/evm_chain_default_tokens.dart` — add `4663 => RobinhoodTokens.tokens`.
3. **Token icons:** if a token's symbol matches an existing `CryptoCurrency` it resolves automatically; otherwise set `iconPath` explicitly and add the asset (PNG under `assets/images/` or `assets/images/stocks/`, or an SVG). Verify each icon is the correct brand by sight — logo-by-ticker APIs have collisions.
4. **Tokenized stocks** (Robinhood Tokens, Solana xStocks): give each `groups: const {CurrencyGroups.tokenizedStock}` and `enabled: false`. They render in the picker's xStocks section automatically.

---

## Step F — UI & chain logo (mirror Base)

If the chain has its own brand logo but a shared native token (like Base/Robinhood using ETH), show the logo in the chain/wallet contexts while the *currency* icon stays ETH.

1. **Get the logo as an SVG** and place it in `assets/new-ui/crypto_full_icons/<chain>.svg`. Compile the optimized form: `dart run vector_graphics_compiler -i assets/new-ui/crypto_full_icons/<chain>.svg -o assets/new-ui/crypto_full_icons/<chain>.svg.vec`. `CakeImageWidget` loads the `.svg.vec` and falls back to the raw `.svg`.
2. Point the currency's `flatIconPath` and `chainIconPath` at it (Step A3); leave `iconPath` as `ethereum.svg`.
3. `cw_core/lib/currency_for_wallet_type.dart` → `getCryptoCurrencyIconForWalletListItem` (the **create-wallet listing + wallet-list** icon).
4. `lib/src/widgets/evm_switcher.dart` → `_getSvgPathForChain` (keyed on `ChainConfig.name.toLowerCase()`).
5. `lib/src/screens/dashboard/widgets/menu_widget.dart` and `.../desktop_widgets/desktop_wallet_selection_dropdown.dart` — add an icon field. These return `Widget`, so use `SvgPicture.asset('<chain>.svg')` (not `Image.asset`, which cannot render SVG).
6. `lib/new-ui/widgets/receive_page/receive_info_box.dart` and `receive_token_display.dart` — return the logo path for the chain badge.
7. *(Optional)* `cw_core/lib/card_design.dart` — a branded balance-card design needs chain-specific card-icon assets + colours; without it the card falls back to a clean generic design (no crash).

---

## Step G — Build flags & platform

- `tool/configure.dart` — add `final has<Chain> = args.contains('${prefix}<chain>');`, include it in `hasEVM`, thread it through the `generatePubspec` + `generateWalletTypes` calls and signatures (and the `cwEVM` condition), and emit it in the `availableWalletTypes` output. **Without this the chain never compiles into a build.**
- `scripts/{android,ios,linux,macos}/app_config.sh` and `cakewallet.bat` — add `--<chain>` to `CONFIG_ARGS`.
- `android/app/src/main/AndroidManifestBase.xml` + `ios/Runner/InfoBase.plist` — add the payment-URI URL schemes (`<chain>`, `<chain>-wallet`, `<chain>_wallet`), matching the scheme you chose in Step A7. Make sure it doesn't collide with an unrelated existing scheme.
- `integration_test/components/common_test_flows.dart` — add arms to the seed/address switches (group with the throw/`default` if you have no test wallet for the chain).

---

## Step H — i18n

Usually **none.** The wallet's display name comes from `walletTypeToDisplayName` (a Dart literal). Only add ARB keys if the chain introduces a genuinely new user-facing string (e.g. a scan-provider toggle). Use `dart run tool/append_translation.dart "key" "English text"`.

---

## Regeneration

- You normally do **not** run `build_runner`: the only "generated" file you touch (`wallet_type.part.dart`) is hand-maintained, and `availableWalletTypes` is regenerated by the build's `configure.dart` step (via `app_config.sh`). Run that build step so the chain appears in the UI.
- If you added `.svg` icons, compile their `.svg.vec` with `vector_graphics_compiler` (Step F).

---

## Verification checklist

- `dart analyze` is clean in `cw_core`, `cw_evm`, and `lib/` (this proves every exhaustive switch is handled).
- `WalletType.arbitrum` group parity: every fall-through group and `.contains([...])` list containing `arbitrum` also contains the new chain (or is deliberately excluded).
- The CI guards pass: no `print(`, no `package:http`, no `package:cw_<chain>` import under `lib/`, ARBs still in lock-step. Run the `cake-pr-checklist` skill.
- Every token contract address and icon was verified from the explorer (no guesses).
- Runtime (the analyzer can't confirm these): the chain appears in the switcher with its logo; a wallet can be created; balance loads; **send works** (native + token); receive works; transaction history renders (or is a known Blockscout follow-up); WalletConnect resolves for the chainId.

---

## Critical rules

- `**WalletType` codecs are append-only.** The Hive adapter byte and the `serializeToInt` int are different numbers; a wrong value corrupts persisted wallets.
- **Native sends crash** without the currency in the `isNativeToken` allowlist + assert (`evm_chain_client.dart`) and the native-currency switch (`evm_chain_wallet.dart`).
- **No-priority-fee chains mirror Arbitrum, not BSC** — including the easy-to-miss `_credentials()` null-priority allow-list and the `displayTransactionPriority` exclusion list.
- **Verify every token address and icon from the explorer.** A wrong address risks user funds; a wrong logo is a ticker collision waiting to happen.
- **Don't hardcode RPC URLs in `.dart`** — they belong in the YAML node list. (A Blockscout tx client's explorer host is the one exception, mirroring how the base client hardcodes `api.etherscan.io`.)
- `**lib/` may not import `package:cw_evm**` — go through the `lib/evm/evm.dart` proxy.

