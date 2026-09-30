import "dart:async";
import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/.secrets.g.dart' as secrets;
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import "package:cw_bitcoin/bitcoin_receive_page_option.dart";
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/locktime.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/lightning/default_spark_tokens.dart';
import 'package:cw_bitcoin/lightning/lightning_wallet.dart';
import 'package:cw_bitcoin/hardware/bitcoin_ledger_service.dart';
import 'package:cw_bitcoin/output_ordering.dart';
import 'package:cw_bitcoin/payjoin/manager.dart';
import 'package:cw_bitcoin/payjoin/storage.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/psbt/signer.dart';
import 'package:cw_bitcoin/psbt/transaction_builder.dart';
import 'package:cw_bitcoin/psbt/v0_deserialize.dart';
import 'package:cw_bitcoin/psbt/v0_finalizer.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_bitcoin/lightning/conversion_status.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import "package:cw_core/node.dart";
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_bitcoin/lightning/spark_token.dart';
import 'package:cw_core/sync_status.dart';
import "package:cw_core/receive_page_option.dart";
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/zpub.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:mobx/mobx.dart';
import 'package:ur/cbor_lite.dart';
import 'package:ur/ur.dart';
import 'package:ur/ur_decoder.dart';

part 'bitcoin_wallet.g.dart';

/// Whether a send should be routed through [LightningWallet] rather than the on-chain
/// Electrum path. Kept as a static, pure method so the routing decision (which mixes an
/// explicit coin-type choice, address sniffing, and asset type) is testable without a real
/// Breez SDK connection.
class SparkSendRouting {
  static bool shouldRouteToLightning({
    required UnspentCoinType coinTypeToSpendFrom,
    required bool hasLightningWallet,
    required bool isLightningCompatibleAddress,
    required bool isSparkToken,
  }) {
    if (isSparkToken) {
      return true;
    } else if (isLightningCompatibleAddress) {
      return true;
    } else {
      return coinTypeToSpendFrom == UnspentCoinType.lightning && hasLightningWallet;
    }
  }
}

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends ElectrumWallet with Store {
  BitcoinWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Box<PayjoinSession> payjoinBox,
    required EncryptionFileUtils encryptionFileUtils,
    Uint8List? seedBytes,
    String? mnemonic,
    String? xpub,
    String? addressPageType,
    BasedUtxoNetwork? networkParam,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    ElectrumBalance? initialLightningBalance,
    List<SparkToken>? initialSparkTokens,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    String? passphrase,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    bool? alwaysScan,
    bool? useLightning,
    String? cachedLightningAddress,
    this.stableBalanceThresholdSats,
    this.stableBalanceMaxSlippageBps,
  }) : super(
          mnemonic: mnemonic,
          passphrase: passphrase,
          xpub: xpub,
          password: password,
          walletInfo: walletInfo,
          derivationInfo: derivationInfo,
          unspentCoinsInfo: unspentCoinsInfo,
          network: networkParam == null
              ? BitcoinNetwork.mainnet
              : networkParam == BitcoinNetwork.mainnet
                  ? BitcoinNetwork.mainnet
                  : BitcoinNetwork.testnet,
          initialAddresses: initialAddresses,
          initialBalance: initialBalance,
          seedBytes: seedBytes,
          encryptionFileUtils: encryptionFileUtils,
          currency:
              networkParam == BitcoinNetwork.testnet ? CryptoCurrency.tbtc : CryptoCurrency.btc,
          alwaysScan: alwaysScan,
          useLightning: useLightning ?? true,
        ) {
    // in a standard BIP44 wallet, mainHd derivation path = m/84'/0'/0'/0 (account 0, index unspecified here)
    // the sideHd derivation path = m/84'/0'/0'/1 (account 1, index unspecified here)
    // String derivationPath = walletInfo.derivationInfo!.derivationPath!;
    // String sideDerivationPath = derivationPath.substring(0, derivationPath.length - 1) + "1";
    // final hd = bitcoin.HDWallet.fromSeed(seedBytes, network: networkType);

    if (mnemonic != null && this.useLightning && LightningWallet.isAvailable) {
      try {
        lightningWallet = _newLightningWallet(
          mnemonic: mnemonic,
          passphrase: passphrase,
          seedBytes: seedBytes,
          cachedAddress: cachedLightningAddress,
        );
      } catch (e) {
        printV(e);
      }
    }

    payjoinManager = PayjoinManager(PayjoinStorage(payjoinBox), this);
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      mainHdByType: mainHdByType,
      sideHdByType: sideHdByType,
      legacyMainHd: mainHd,
      legacySideHd: sideHd,
      network: networkParam ?? network,
      masterHd: seedBytes != null ? Bip32Slip10Secp256k1.fromSeed(seedBytes) : null,
      isHardwareWallet: walletInfo.isHardwareWallet,
      payjoinManager: payjoinManager,
      lightningWallet: lightningWallet,
    );

    if (lightningWallet != null) {
      walletAddresses.setLightningAddress(walletInfo.name);
    }
    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });

    reaction((_) => this.useLightning, (bool useLightning) {
      if (useLightning && LightningWallet.isAvailable) {
        if (mnemonic != null) {
          // Reuse the instance walletAddresses holds (it's the one setLightningAddress connects);
          // a fresh one here would never connect while the old one kept running.
          lightningWallet = walletAddresses.lightningWallet ??
              _newLightningWallet(
                mnemonic: mnemonic,
                passphrase: passphrase,
                seedBytes: seedBytes,
                cachedAddress: cachedLightningAddress,
              );
          walletAddresses.setLightningAddress(walletInfo.name);
        }
      } else {
        // Disconnect rather than just drop it - an abandoned SDK keeps syncing and running its
        // own Stable Balance conversions.
        lightningWallet?.close();
        lightningWallet = null;
      }
    });

    if (initialLightningBalance != null) {
      balance[CryptoCurrency.btcln] = initialLightningBalance;
    }

    _sparkTokens = initialSparkTokens ?? [];

    for (final token in _sparkTokens.where((t) => t.enabled)) {
      balance[token] = ElectrumBalance(
        confirmed: Money.zero(token),
        unconfirmed: Money.zero(token),
        frozen: Money.zero(token),
      );
    }
  }

  bool get isLightningInitialized => lightningWallet?.isInitialized == true;

  /// Stable Balance's "Convert above" threshold, or null for the SDK default.
  BigInt? stableBalanceThresholdSats;

  /// Stable Balance's "Max conversion slippage", in basis points, or null for the default.
  int? stableBalanceMaxSlippageBps;

  @override
  Map<String, dynamic> toJSONMap() => {
        ...super.toJSONMap(),
        'stableBalanceThresholdSats': stableBalanceThresholdSats?.toString(),
        'stableBalanceMaxSlippageBps': stableBalanceMaxSlippageBps,
      };

  LightningWallet _newLightningWallet({
    required String mnemonic,
    String? passphrase,
    Uint8List? seedBytes,
    String? cachedAddress,
  }) =>
      LightningWallet(
        mnemonic: mnemonic,
        passphrase: passphrase,
        seedBytes: seedBytes,
        apiKey: secrets.breezApiKey,
        lnurlDomain: "cake.cash",
        cachedAddress: cachedAddress,
        tokenCurrencyResolver: (id) =>
            _sparkTokens.firstWhereOrNull((t) => t.tokenIdentifier == id),
        stableBalanceSettings: () => (
          tokens: LightningWallet.stableBalanceTokensFrom(_sparkTokens),
          thresholdSats: stableBalanceThresholdSats,
          maxSlippageBps: stableBalanceMaxSlippageBps,
        ),
      );

  List<SparkToken> _sparkTokens = [];

  List<SparkToken> get sparkTokenCurrencies => _sparkTokens.toList();

  SparkToken? getSparkTokenByIdentifier(String tokenIdentifier) =>
      _sparkTokens.firstWhereOrNull((t) => t.tokenIdentifier == tokenIdentifier);

  void _upsertCachedSparkToken(SparkToken token) {
    _sparkTokens.removeWhere((t) => t.tokenIdentifier == token.tokenIdentifier);
    _sparkTokens.add(token);
  }

  /// Idempotent: seeds the default Spark tokens (currently just USDB) for wallets that don't
  /// have them yet, preserving the enabled/disabled state of any that already exist.
  Future<void> addInitialSparkTokens() async {
    if (!useLightning || !LightningWallet.isAvailable) {
      return;
    }

    final defaults = DefaultSparkTokens().initialSparkTokens(walletInfo.name);

    for (final token in defaults) {
      final existing = getSparkTokenByIdentifier(token.tokenIdentifier);
      final newToken = SparkToken.copyWith(
        token,
        enabled: existing?.enabled ?? token.enabled,
        walletName: walletInfo.name,
      );

      await newToken.save();
      _upsertCachedSparkToken(newToken);

      if (newToken.enabled) {
        final existingBalance = balance[newToken];
        balance.remove(newToken);
        balance[newToken] = existingBalance ??
            ElectrumBalance(
              confirmed: Money.zero(newToken),
              unconfirmed: Money.zero(newToken),
              frozen: Money.zero(newToken),
            );
      }
    }
  }

  Future<void> addSparkToken(SparkToken token) async {
    final newToken =
        SparkToken.copyWith(token, walletName: walletInfo.name, enabled: token.enabled);

    await newToken.save();

    _upsertCachedSparkToken(newToken);

    if (newToken.enabled) {
      balance[newToken] = balance[newToken] ??
          ElectrumBalance(
            confirmed: Money.zero(newToken),
            unconfirmed: Money.zero(newToken),
            frozen: Money.zero(newToken),
          );
    } else {
      balance.remove(newToken);
    }
  }

  Future<void> deleteSparkToken(SparkToken token) async {
    await SparkToken.deleteForWallet(walletInfo.name, token.tokenIdentifier);

    _sparkTokens.removeWhere((t) => t.tokenIdentifier == token.tokenIdentifier);

    balance.remove(token);
  }

  /// Changes Stable Balance's `thresholdSats`/`maxSlippageBps`, which requires a full
  /// disconnect/reconnect of the Lightning session (see [LightningWallet.reconnectWithStableBalanceSettings]
  /// for why). Re-subscribes to wallet events afterward, since a reconnect replaces the
  /// underlying event stream and drops whatever was listening to the old one.
  Future<bool> reconnectStableBalanceSettings({BigInt? thresholdSats, int? maxSlippageBps}) async {
    if (lightningWallet == null) {
      return false;
    }

    final previousThresholdSats = stableBalanceThresholdSats;
    final previousMaxSlippageBps = stableBalanceMaxSlippageBps;
    stableBalanceThresholdSats = thresholdSats;
    stableBalanceMaxSlippageBps = maxSlippageBps;

    final path = await pathForWalletDir(name: walletInfo.name, type: WalletType.bitcoin);
    final success = await lightningWallet!.reconnectWithStableBalanceSettings(path);

    if (success) {
      await subscribeForUpdates();
    } else {
      stableBalanceThresholdSats = previousThresholdSats;
      stableBalanceMaxSlippageBps = previousMaxSlippageBps;
    }

    return success;
  }

  @override
  bool get hasRescan => true;

  static Future<BitcoinWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Box<PayjoinSession> payjoinBox,
    required EncryptionFileUtils encryptionFileUtils,
    String? passphrase,
    String? addressPageType,
    BasedUtxoNetwork? network,
    List<BitcoinAddressRecord>? initialAddresses,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    int initialSilentAddressIndex = 0,
  }) async {
    late Uint8List seedBytes;

    final derivationInfo = await walletInfo.getDerivationInfo();

    switch (derivationInfo.derivationType) {
      case DerivationType.bip39:
        seedBytes = await bip39.mnemonicToSeed(
          mnemonic,
          passphrase: passphrase ?? "",
        );
        break;
      case DerivationType.electrum:
      default:
        seedBytes = await mnemonicToSeedBytes(mnemonic, passphrase: passphrase ?? "");
        break;
    }

    // Passed in as initialSparkTokens (not just added afterwards): the constructor kicks off
    // LightningWallet.init() (via setLightningAddress) without awaiting it, and that init reads
    // the wallet's in-memory Spark tokens to build the Stable Balance config. Added any later,
    // they'd race it and lose, silently leaving this wallet's first session with no
    // Stable-Balance-eligible tokens.
    final defaultSparkTokens = LightningWallet.isAvailable
        ? DefaultSparkTokens().initialSparkTokens(walletInfo.name)
        : <SparkToken>[];

    for (final token in defaultSparkTokens) {
      await token.save();
    }

    final wallet = BitcoinWallet(
      mnemonic: mnemonic,
      passphrase: passphrase ?? "",
      password: password,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      initialBalance: initialBalance,
      initialSparkTokens: defaultSparkTokens,
      encryptionFileUtils: encryptionFileUtils,
      seedBytes: seedBytes,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      addressPageType: addressPageType,
      networkParam: network,
      payjoinBox: payjoinBox,
      useLightning: true,
    );

    await wallet.addInitialSparkTokens();

    return wallet;
  }

  static Future<BitcoinWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Box<PayjoinSession> payjoinBox,
    required String password,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final network = walletInfo.network != null
        ? BasedUtxoNetwork.fromName(walletInfo.network!)
        : BitcoinNetwork.mainnet;

    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);

    ElectrumWalletSnapshot? snp = null;

    try {
      snp = await ElectrumWalletSnapshot.load(
        encryptionFileUtils,
        name,
        walletInfo.type,
        password,
        network,
      );
    } catch (e) {
      if (!hasKeysFile) rethrow;
    }

    final WalletKeysData keysData;
    // Migrate wallet from the old scheme to then new .keys file scheme
    if (!hasKeysFile) {
      keysData = WalletKeysData(
        mnemonic: snp!.mnemonic,
        xPub: snp.xpub,
        passphrase: snp.passphrase,
      );
    } else {
      keysData = await WalletKeysFile.readKeysFile(
        name,
        walletInfo.type,
        password,
        encryptionFileUtils,
      );
    }

    final derivationInfo = await walletInfo.getDerivationInfo();

    // set the default if not present:
    derivationInfo.derivationPath ??= snp?.derivationPath ?? electrum_path;
    derivationInfo.derivationType ??= snp?.derivationType ?? DerivationType.electrum;
    if (derivationInfo.derivationType == DerivationType.unknown) {
      if (snp?.derivationPath == electrum_path || snp?.derivationType == DerivationType.electrum) {
        derivationInfo.derivationPath = electrum_path;
        derivationInfo.derivationType = DerivationType.electrum;
      } else {
        derivationInfo.derivationPath = segwit_path;
        derivationInfo.derivationType = DerivationType.bip39;
      }
    }
    await derivationInfo.save();

    Uint8List? seedBytes = null;
    final mnemonic = keysData.mnemonic;
    final passphrase = keysData.passphrase;

    if (mnemonic != null) {
      switch (derivationInfo.derivationType) {
        case DerivationType.electrum:
          seedBytes = await mnemonicToSeedBytes(mnemonic, passphrase: passphrase ?? "");
          break;
        case DerivationType.bip39:
        default:
          seedBytes = await bip39.mnemonicToSeed(
            mnemonic,
            passphrase: passphrase ?? '',
          );
          break;
      }
    }

    final initialSparkTokens = await SparkToken.getAllForWallet(name);

    final wallet = BitcoinWallet(
      mnemonic: mnemonic,
      xpub: keysData.xPub != null ? convertZpubToXpub(keysData.xPub!) : null,
      password: password,
      passphrase: passphrase,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp?.addresses,
      initialSilentAddresses: snp?.silentAddresses,
      initialSilentAddressIndex: snp?.silentAddressIndex ?? 0,
      initialBalance: snp?.balance,
      initialLightningBalance: snp?.lightningBalance,
      initialSparkTokens: initialSparkTokens,
      encryptionFileUtils: encryptionFileUtils,
      seedBytes: seedBytes,
      initialRegularAddressIndex: snp?.regularAddressIndex,
      initialChangeAddressIndex: snp?.changeAddressIndex,
      addressPageType: snp?.addressPageType,
      networkParam: network,
      alwaysScan: snp?.alwaysScan,
      useLightning: snp?.useLightning,
      cachedLightningAddress: snp?.cachedLightningAddress,
      stableBalanceThresholdSats: snp?.stableBalanceThresholdSats,
      stableBalanceMaxSlippageBps: snp?.stableBalanceMaxSlippageBps,
      payjoinBox: payjoinBox,
    );

    // Idempotent: backfills defaults (USDB) for wallets that predate this feature.
    await wallet.addInitialSparkTokens();

    return wallet;
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    payjoinManager.cleanupSessions();
    await lightningWallet?.close();
    super.close(shouldCleanup: shouldCleanup);
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    // Pull-to-refresh lands here; the SDK only syncs on its own schedule otherwise.
    unawaited(lightningWallet?.sync());
    return super.connectToNode(node: node);
  }

  @override
  Future<ElectrumBalance> fetchBalances() async {
    final balance = await super.fetchBalances();
    await _fetchLightningBalances();

    return ElectrumBalance(
      confirmed: balance.confirmed,
      unconfirmed: balance.unconfirmed,
      frozen: balance.frozen,
    );
  }

  /// The Lightning and Spark token balances only - kept separate from [fetchBalances] so an SDK
  /// sync can refresh them without an Electrum round trip per address.
  Future<void> _fetchLightningBalances() async {
    if (!isLightningInitialized || lightningWallet == null) {
      return;
    }

    try {
      final lBalance = await lightningWallet!.getBalance();

      this.balance[CryptoCurrency.btcln] = ElectrumBalance(
          confirmed: lBalance,
          unconfirmed: Money.zero(CryptoCurrency.btcln),
          frozen: Money.zero(CryptoCurrency.btcln));
    } catch (e) {
      printV("Error fetching lightning balance: $e");
    }

    try {
      final tokenBalances = await lightningWallet!.getTokenBalances();

      for (final token in _sparkTokens.where((t) => t.enabled)) {
        final tokenBalance = tokenBalances[token.tokenIdentifier];

        balance[token] = ElectrumBalance(
          confirmed: Money(tokenBalance?.balance ?? BigInt.zero, token),
          unconfirmed: Money.zero(token),
          frozen: Money.zero(token),
        );
      }
    } catch (e) {
      printV("Error fetching Spark token balances: $e");
    }
  }

  @override
  @action
  Future<void> subscribeForUpdates() async {
    if (isLightningInitialized && lightningWallet != null) {
      lightningWallet!.setEventListener(
        onTransactionEvent: (tx) async {
          final existing = transactionHistory.transactions[tx.id];
          // A conversion can flip from pending to completed/failed while the underlying
          // payment's own isPending is already false (e.g. the self-invoice payment settles
          // immediately, but the conversion itself keeps running) - without also checking this,
          // the row would stay on "Converting" forever once isPending stops changing.
          if (existing?.isPending != tx.isPending ||
              existing?.additionalInfo["conversionStatus"] !=
                  tx.additionalInfo["conversionStatus"]) {
            transactionHistory.addOne(tx);
            await transactionHistory.save();
            await fetchBalances();
          }
        },
        onCreateDepositTransactionEvent: (txs) async {
          if (txs.isNotEmpty) {
            transactionHistory.addMany(txs);
            await transactionHistory.save();
          }
        },
        onUpdateDepositTransactionEvent: (txs) async {
          if (txs.isNotEmpty) {
            txs.forEach((tx) => transactionHistory.transactions.remove(tx.id));
            await transactionHistory.save();
          }
        },
        onBalanceChangedEvent: fetchBalances,
        onSyncedEvent: () async {
          await _fetchLightningBalances();
          _fetchLightningTransactions(incrementalOnly: true);
          await _refreshPendingLightningTransactions();
        },
      );
    }

    return super.subscribeForUpdates();
  }

  /// A stored transaction predates either the conversion from/to ticker tags, or `paymentHash`
  /// Once re-fetched, a transaction always carries both, so this naturally stops re-triggering.
  bool _isStaleConversionTag(ElectrumTransactionInfo tx) =>
      tx.additionalInfo["paymentHash"] == null ||
      (tx.additionalInfo["conversionStatus"] != null &&
          tx.additionalInfo["conversionToTicker"] == null);

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    _fetchLightningTransactions();
    return super.fetchTransactions();
  }

  /// Re-reads every stored Lightning row that's still pending (or mid-conversion) by id - the
  /// incremental fetch only returns rows newer than the newest stored one, and the SDK sends no
  /// event for conversion legs, so nothing else would ever move them past "pending".
  Future<void> _refreshPendingLightningTransactions() async {
    final wallet = lightningWallet;

    if (wallet == null) {
      return;
    }

    final stale = transactionHistory.transactions.values
        .where((tx) =>
            tx.additionalInfo["isLightning"] == true &&
            tx.additionalInfo["isSparkDeposit"] != true &&
            (tx.isPending ||
                ConversionStatusUtils.fromAdditionalInfo(tx.additionalInfo) ==
                    ConversionStatus.pending ||
                // Stored under older tagging; the SDK may no longer list it (e.g. a conversion
                // leg it has since nested under its send), so only a by-id re-read updates it.
                tx.additionalInfo["lnTagVersion"] != LightningWallet.historyTagVersion))
        .toList();

    if (stale.isEmpty) {
      return;
    }

    final fresh = (await Future.wait(stale.map((tx) => wallet.getTransactionById(tx.id))))
        .whereType<ElectrumTransactionInfo>()
        .where((tx) {
      final stored = transactionHistory.transactions[tx.id];
      return stored == null ||
          stored.isPending != tx.isPending ||
          stored.additionalInfo["conversionStatus"] != tx.additionalInfo["conversionStatus"] ||
          stored.additionalInfo["conversionFromAmount"] !=
              tx.additionalInfo["conversionFromAmount"] ||
          stored.additionalInfo["lnTagVersion"] != tx.additionalInfo["lnTagVersion"];
    }).toList();

    if (fresh.isEmpty) {
      return;
    }

    transactionHistory.addMany({for (final tx in fresh) tx.id: tx});
    await transactionHistory.save();
  }

  /// [incrementalOnly] skips the stale-tag full refetch - token payments and Spark deposits never
  /// carry a paymentHash, so [_isStaleConversionTag] matches them forever and a per-sync caller
  /// would otherwise reload the whole history on every SDK sync.
  void _fetchLightningTransactions({bool incrementalOnly = false}) {
    if (lightningWallet != null) {
      final lightningTxs = transactionHistory.transactions.values
          .where((e) => (e.additionalInfo["isLightning"] as bool?) == true);

      // Newest by date among the rows the BTC query itself returns - not the last one inserted,
      // which can be a token row or a deposit placeholder dated "now".
      final existingTx = lightningTxs
          .where(
            (e) =>
                e.additionalInfo["tokenIdentifier"] == null &&
                e.additionalInfo["isSparkDeposit"] != true,
          )
          .sortedBy((e) => e.date)
          .lastOrNull;

      // A full refetch (ignoring the incremental fromDate) re-fetches these stale entries with
      // the tags they were missing - this naturally stops re-triggering once every stored
      // conversion is tagged.
      final needsFullRefetch = !incrementalOnly && lightningTxs.any(_isStaleConversionTag);

      lightningWallet!
          .getTransactionHistory(fromDate: needsFullRefetch ? null : existingTx?.date)
          .then((lnHistory) async {
        transactionHistory.addMany(lnHistory);
        await transactionHistory.save();
      }).onError((_, __) {});

      for (final token in _sparkTokens.where((t) => t.enabled)) {
        final tokenTxs = transactionHistory.transactions.values
            .where((e) => e.additionalInfo["tokenIdentifier"] == token.tokenIdentifier);
        final existingTokenTx = tokenTxs.sortedBy((e) => e.date).lastOrNull;
        final tokenNeedsFullRefetch = !incrementalOnly && tokenTxs.any(_isStaleConversionTag);

        lightningWallet!
            .getTokenTransactionHistory(
          token.tokenIdentifier,
          token,
          fromDate: tokenNeedsFullRefetch ? null : existingTokenTx?.date,
        )
            .then((tokenHistory) async {
          transactionHistory.addMany(tokenHistory);
          await transactionHistory.save();
        }).onError((_, __) {});
      }
    }
  }

  LightningWallet? lightningWallet;

  late final PayjoinManager payjoinManager;

  @override
  bool get hasPayjoinSupport => keys.privateKey.isNotEmpty;

  @override
  bool get hasLightningSupport => lightningWallet?.isInitialized == true;

  bool get isPayjoinAvailable => unspentCoinsInfo.values
      .where((element) => element.walletId == id && element.isSending && !element.isFrozen)
      .isNotEmpty;

  Future<PsbtV2> buildPsbt({
    required List<BitcoinOutput> outputs,
    required List<OutputInfo> cwOutputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
    required Uint8List masterFingerprint,
    String? memo,
    bool enableRBF = false,
    BitcoinOrdering inputOrdering = BitcoinOrdering.bip69,
    BitcoinOrdering outputOrdering = BitcoinOrdering.bip69,
  }) async {
    final psbtReadyInputs = <PSBTReadyUtxoWithAddress>[];
    for (final utxo in utxos) {
      final rawTx = await electrumClient.getTransactionHex(hash: utxo.utxo.txHash);
      final publicKeyAndDerivationPath = publicKeys[utxo.ownerDetails.address.pubKeyHash()]!;

      psbtReadyInputs.add(
        PSBTReadyUtxoWithAddress(
          utxo: utxo.utxo,
          rawTx: rawTx,
          ownerDetails: utxo.ownerDetails,
          ownerDerivationPath: publicKeyAndDerivationPath.derivationPath,
          ownerMasterFingerprint: masterFingerprint,
          ownerPublicKey: publicKeyAndDerivationPath.publicKey,
        ),
      );
    }

    final psbtReadyOutputs = outputs.map((o) {
      final cwOutput = cwOutputs
          .where(
            (e) => [e.address, e.extractedAddress]
                .map((e) => e?.toLowerCase())
                .contains(o.address.toAddress().toLowerCase()),
          )
          .firstOrNull;

      if (o.isChange && publicKeys.containsKey(o.address.pubKeyHash())) {
        final changeKey = publicKeys[o.address.pubKeyHash()]!;
        return PSBTReadyBitcoinOutput(
          address: o.address,
          value: o.value,
          isSilentPayment: o.isSilentPayment,
          isChange: o.isChange,
          changeMasterFingerprint: masterFingerprint,
          changeDerivationPath: changeKey.derivationPath,
          changePublicKey: changeKey.publicKey,
          outputInfo: cwOutput,
        );
      }
      return PSBTReadyBitcoinOutput(
        address: o.address,
        value: o.value,
        isSilentPayment: o.isSilentPayment,
        isChange: o.isChange,
        outputInfo: cwOutput,
      );
    }).toList();

    final locktime = antiFeeSnipingLocktime(
      chainTip: await getCurrentChainTip(),
      synced: syncStatus is SyncedSyncStatus,
    );

    return PSBTTransactionBuild(
      inputs: psbtReadyInputs,
      outputs: psbtReadyOutputs,
      enableRBF: enableRBF,
      locktime: locktime,
    ).psbt;
  }

  @override
  Future<BtcTransaction> buildHardwareWalletTransaction({
    required List<BitcoinOutput> outputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required List<OutputInfo> cwOutputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
    String? memo,
    bool enableRBF = false,
    BitcoinOrdering inputOrdering = BitcoinOrdering.bip69,
    BitcoinOrdering outputOrdering = BitcoinOrdering.bip69,
  }) async {
    final masterFingerprint =
        await (hardwareWalletService as BitcoinHardwareWalletService).getMasterFingerprint();

    final orderedOutputs = orderOutputs(outputs, outputOrdering);

    final psbt = await buildPsbt(
      outputs: orderedOutputs,
      fee: fee,
      network: network,
      utxos: utxos,
      cwOutputs: cwOutputs,
      publicKeys: publicKeys,
      masterFingerprint: masterFingerprint,
      memo: memo,
      enableRBF: enableRBF,
      inputOrdering: inputOrdering,
      // Already applied above; don't reorder again.
      outputOrdering: BitcoinOrdering.none,
    );

    final psbtStr = base64Encode(psbt.serialize());
    if (hardwareWalletService is BitcoinLedgerService && derivationInfo.derivationPath != null) {
      (hardwareWalletService as BitcoinLedgerService)
          .setAccountDerivationPath(derivationInfo.derivationPath!);
    }

    final rawHex = await hardwareWalletService!.signTransaction(transaction: psbtStr);
    return BtcTransaction.fromRaw(BytesUtils.toHexString(rawHex));
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    credentials = credentials as BitcoinTransactionCredentials;
    final lnAddr = credentials.outputs.first.isParsedAddress
        ? credentials.outputs.first.extractedAddress!
        : credentials.outputs.first.address;

    final sparkToken = credentials.currency as SparkToken?;
    final isLNCompatible = await lightningWallet?.isCompatible(lnAddr) ?? false;

    if (SparkSendRouting.shouldRouteToLightning(
      coinTypeToSpendFrom: credentials.coinTypeToSpendFrom,
      hasLightningWallet: lightningWallet != null,
      isLightningCompatibleAddress: isLNCompatible,
      isSparkToken: sparkToken != null,
    )) {
      Money amount;

      if (credentials.outputs.first.sendAll) {
        amount = sparkToken != null
            ? await lightningWallet!.getTokenBalance(sparkToken.tokenIdentifier, sparkToken)
            : await lightningWallet!.getBalance();
      } else {
        amount = credentials.outputs.first.cryptoAmount;
      }

      return lightningWallet!.createTransaction(
        lnAddr,
        amount.amount > BigInt.zero ? amount.amount : null,
        credentials.priority,
        feesIncluded: credentials.outputs.first.sendAll,
        tokenIdentifier: sparkToken?.tokenIdentifier,
        tokenCurrency: sparkToken,
        maxSlippageBps: stableBalanceMaxSlippageBps,
      );
    }

    final tx = (await super.createTransaction(credentials)) as PendingBitcoinTransaction;

    final payjoinUri = credentials.payjoinUri;
    if (payjoinUri == null && !tx.shouldCommitUR()) return tx;

    final transaction = await buildPsbt(
        utxos: tx.utxos,
        outputs: tx.outputs
            .map((e) => BitcoinOutput(
                  address: addressFromScript(e.scriptPubKey),
                  value: e.amount,
                  isSilentPayment: e.isSilentPayment,
                  isChange: e.isChange,
                ))
            .toList(),
        cwOutputs: credentials.outputs,
        fee: tx.fee.amount,
        network: network,
        memo: credentials.outputs.first.memo,
        outputOrdering: BitcoinOrdering.none,
        enableRBF: true,
        publicKeys: tx.publicKeys!,
        masterFingerprint: Uint8List.fromList([0, 0, 0, 0]));

    if (tx.shouldCommitUR()) {
      tx.unsignedPsbt = transaction.asPsbtV0();
      return tx;
    }

    final originalPsbt =
        await signPsbt(base64.encode(transaction.asPsbtV0()), getUtxoWithPrivateKeys());

    tx.commitOverride = () async {
      final sender =
          await payjoinManager.initSender(payjoinUri!, originalPsbt, int.parse(tx.feeRate));
      payjoinManager.spawnNewSender(sender: sender, pjUrl: payjoinUri, amount: tx.amount.amount);
    };

    return tx;
  }

  List<UtxoWithPrivateKey> getUtxoWithPrivateKeys({bool confirmedOnly = false}) => unspentCoins
      .where((e) => e.isSending && !e.isFrozen && (!confirmedOnly || (e.confirmations ?? 0) > 0))
      .map((unspent) => UtxoWithPrivateKey.fromUnspent(unspent, this))
      .toList();

  Future<void> commitPsbt(String finalizedPsbt) {
    final psbt = PsbtV2()..deserializeV0(base64.decode(finalizedPsbt));

    final btcTx = BtcTransaction.fromRaw(BytesUtils.toHexString(psbt.extract()));

    return PendingBitcoinTransaction(
      btcTx,
      type,
      electrumClient: electrumClient,
      amount: Money.zero(currency),
      fee: Money.zero(currency),
      feeRate: "",
      network: network,
      hasChange: true,
      isViewOnly: false,
    ).commit();
  }

  Future<String> signPsbt(String preProcessedPsbt, List<UtxoWithPrivateKey> utxos) async {
    final psbt = PsbtV2()..deserializeV0(base64Decode(preProcessedPsbt));

    await psbt.signWithUTXO(utxos, (txDigest, utxo, key, sighash) {
      return utxo.utxo.isP2tr()
          ? key.signTapRoot(
              txDigest,
              sighash: sighash,
              tweak: utxo.utxo.isSilentPayment != true,
            )
          : key.signInput(txDigest, sigHash: sighash);
    }, (txId, vout) async {
      final txHex = await electrumClient.getTransactionHex(hash: txId);
      final output = BtcTransaction.fromRaw(txHex).outputs[vout];
      return TaprootAmountScriptPair(output.amount, output.scriptPubKey);
    });

    psbt.finalizeV0();
    return base64Encode(psbt.asPsbtV0());
  }

  Future<void> commitPsbtUR(List<String> urCodes) async {
    if (urCodes.isEmpty) throw Exception("No QR code got scanned");
    bool isUr = urCodes.any((str) {
      return str.startsWith("ur:psbt/");
    });
    if (isUr) {
      final ur = URDecoder();
      for (final inp in urCodes) {
        ur.receivePart(inp);
      }
      final result = (ur.result as UR);
      final cbor = result.cbor;
      final cborDecoder = CBORDecoder(cbor);
      final out = cborDecoder.decodeBytes();
      final bytes = out.$1;
      final base64psbt = base64Encode(bytes);
      final psbt = PsbtV2()..deserializeV0(base64Decode(base64psbt));

      // psbt.finalize();
      final finalized = base64Encode(psbt.serialize());
      await commitPsbt(finalized);
    } else {
      final btcTx = BtcTransaction.fromRaw(urCodes.first);

      return PendingBitcoinTransaction(
        btcTx,
        type,
        electrumClient: electrumClient,
        amount: Money.zero(currency),
        fee: Money.zero(currency),
        feeRate: "",
        network: network,
        hasChange: true,
        isViewOnly: false,
      ).commit();
    }
  }

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    if (walletInfo.isHardwareWallet) {
      final addressEntry = address != null
          ? walletAddresses.allAddresses.firstWhere((element) => element.address == address)
          : null;
      final index = addressEntry?.index ?? 0;
      final isChange = addressEntry?.isHidden == true ? 1 : 0;
      final derivationInfo = await walletInfo.getDerivationInfo();
      final accountPath = derivationInfo.derivationPath;
      final derivationPath = accountPath != null ? "$accountPath/$isChange/$index" : null;

      final signature = await hardwareWalletService!
          .signMessage(message: ascii.encode(message), derivationPath: derivationPath);
      return base64Encode(signature);
    }

    return super.signMessage(message, address: address);
  }

  @override
  bool receiveOptionAvailable(ReceivePageOption option) {
    if (option == BitcoinReceivePageOption.lightning) {
      return hasLightningSupport;
    }

    if (option == BitcoinReceivePageOption.silent_payments) {
      return hasSilentPaymentsScanning;
    }

    return true;
  }
}
