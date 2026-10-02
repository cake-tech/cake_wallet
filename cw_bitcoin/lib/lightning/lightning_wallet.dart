import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";
import "package:collection/collection.dart";
import "package:cw_bitcoin/bitcoin_transaction_priority.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_bitcoin/lightning/conversion_status.dart" show ConversionAmountAdjustment;
import "package:cw_bitcoin/lightning/pending_lightning_transaction.dart";
import "package:cw_bitcoin/lightning/spark_conversion.dart";
import "package:cw_bitcoin/lightning/spark_token.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/currency_groups.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart" show Observable, runInAction;

bool _breezSdkSparkLibUninitialized = true;
Stream<LogEntry>? _logStream;

/// What [LightningWallet] needs from its wallet to configure Stable Balance at connect time.
typedef StableBalanceConnectSettings = ({
  List<StableBalanceToken> tokens,
  BigInt? thresholdSats,
  int? maxSlippageBps,
});

class LightningWallet {
  LightningWallet({
    required this.mnemonic,
    required this.apiKey,
    required this.lnurlDomain,
    this.network = Network.mainnet,
    this.passphrase,
    this.seedBytes,
    this.cachedAddress,
    this.tokenCurrencyResolver,
    this.stableBalanceSettings,
  });

  final String mnemonic;
  final String? passphrase;
  final Uint8List? seedBytes;
  final String apiKey;
  final String lnurlDomain;
  final Network network;
  BreezSdk? _sdk;

  /// Resolves a Spark token identifier to the wallet's own [Currency] for it (e.g. USDB) - used
  /// by [_getElectrumTransactionInfoFromPayment] so every code path that turns a live SDK
  /// `Payment` into an [ElectrumTransactionInfo] (not just the ones that already know the token,
  /// like [getTokenTransactionHistory]) denominates a token payment's amount/fee correctly
  /// instead of mislabeling it in [currency] (BTC/sats). [BitcoinWallet] wires this to its own
  /// Spark token registry, which [LightningWallet] has no access to on its own.
  final Currency? Function(String tokenIdentifier)? tokenCurrencyResolver;

  /// The wallet's current Stable Balance settings, read on every connect ([init] and
  /// [reconnectWithStableBalanceSettings]). [BitcoinWallet] wires this to its own Spark tokens
  /// and persisted threshold/slippage.
  final StableBalanceConnectSettings Function()? stableBalanceSettings;

  String? cachedAddress;

  static int MAX_RETRIES = 10;

  /// Matches Spark Settings' default (`HomeSettingsViewModelBase.defaultMaxSlippageBps`); the
  /// SDK's own default is 0.1%, which would silently differ from what Settings shows.
  static const int defaultMaxSlippageBps = 100;

  /// Bumped whenever how a payment is tagged for history changes, so stored rows get re-read.
  static const int historyTagVersion = 2;

  static bool get isAvailable => Platform.isIOS || Platform.isAndroid || Platform.isMacOS;

  Currency get currency => CryptoCurrency.btcln;

  BreezSdk get sdk => _sdk!;

  StreamSubscription<SdkEvent>? _eventSubscription;
  Stream<SdkEvent>? _eventStream;

  StreamSubscription<LogEntry>? _logSubscription;

  bool get isInitialized => _eventStream != null;

  /// Whether Stable Balance is on, as last read from or written to the SDK - observable, so every
  /// screen reading it (balance card, settings toggle) agrees without its own copy.
  final Observable<bool> stableBalanceActive = Observable(false);

  void _setStableBalanceActive(bool value) => runInAction(() => stableBalanceActive.value = value);

  /// The Stable Balance tokens registered at the last [init] - lets a conversion leg that only
  /// knows its own side (e.g. the sats leg) name the token on the other side.
  List<StableBalanceToken> _stableBalanceTokens = const [];

  /// Connect/disconnect run one at a time: two overlapping [init]s would each connect their own
  /// SDK on the same storage dir, and the orphaned one keeps running its own Stable Balance state
  /// (e.g. still auto-converting after the user turned it off on the other).
  Future<void> _lifecycle = Future.value();

  // Runs fn() after every previously-queued _runExclusive call has settled, without an explicit lock.
  Future<T> _runExclusive<T>(Future<T> Function() fn) {
    // Chains onto the current tail so fn() only starts once every prior queued fn has settled.
    final result = _lifecycle.then((_) => fn());

    // Swallow the error into the tail so one failed fn doesn't permanently reject later ones;
    // the caller still gets the real success/error via the returned result.
    _lifecycle = result.then((_) {}, onError: (_) {});

    return result;
  }

  Future<void> _disconnectCurrent() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    final current = _sdk;
    _sdk = null;
    _eventStream = null;

    if (current == null) {
      return;
    }

    try {
      await current.disconnect();
    } catch (e) {
      printV("LightningWallet: disconnect failed: $e");
    }
  }

  void _subscribeToLogStream(File logFile) {
    _logSubscription?.cancel();
    _logSubscription = _logStream?.listen((logEntry) {
      try {
        // Check if file exists before writing (optional, but safer)
        if (!logFile.existsSync()) {
          logFile.createSync(recursive: true);
        }
        logFile.writeAsStringSync("[${logEntry.level}] ${logEntry.line}\n", mode: FileMode.append);
      } catch (e) {
        // Silently fail or use printV(e) so it doesn't crash the app
        printV("Failed to write to log: $e");
      }
    }, onError: (e) {
      try {
        if (!logFile.existsSync()) {
          logFile.createSync(recursive: true);
        }
        logFile.writeAsStringSync("[ERROR] $e\n", mode: FileMode.append);
      } catch (err) {
        printV("Failed to write error to log: $err");
      }
    });
  }

  /// Derives the Stable-Balance-eligible token list from a wallet's Spark tokens: every
  /// currently-enabled token tagged [CurrencyGroups.stablecoin] (not hardcoded to USDB alone),
  /// so any future stablecoin Cake adds is automatically eligible with no further code change.
  static List<StableBalanceToken> stableBalanceTokensFrom(List<SparkToken> tokens) => tokens
      .where((token) => token.enabled && token.groups.contains(CurrencyGroups.stablecoin))
      .map(
        (token) => StableBalanceToken(label: token.symbol, tokenIdentifier: token.tokenIdentifier),
      )
      .toList();

  /// Builds the [StableBalanceConfig] passed to [init], or null when there's nothing to
  /// register. Deliberately never sets `defaultActiveLabel`: Stable Balance must start inactive
  /// for every wallet and only be turned on by an explicit user action via
  /// [setStableBalanceActive]. [thresholdSats]/[maxSlippageBps] only take effect at connect time
  /// (see [reconnectWithStableBalanceSettings]) - they're not part of [UpdateUserSettingsRequest].
  static StableBalanceConfig? buildStableBalanceConfig(
    List<StableBalanceToken> tokens, {
    BigInt? thresholdSats,
    int? maxSlippageBps,
  }) =>
      tokens.isEmpty
          ? null
          : StableBalanceConfig(
              tokens: tokens,
              thresholdSats: thresholdSats,
              maxSlippageBps: maxSlippageBps,
            );

  /// Connects with [stableBalanceSettings] as they are right now. They only take effect for THIS
  /// connect - a token added or a threshold/slippage changed after connecting needs a reconnect
  /// (see [reconnectWithStableBalanceSettings]), per the SDK's own design.
  Future<bool> init(String appPath) => _runExclusive(() => _init(appPath));

  Future<bool> _init(String appPath) async {
    try {
      await _disconnectCurrent();

      final settings = stableBalanceSettings?.call();
      final stableBalanceTokens = settings?.tokens ?? const <StableBalanceToken>[];

      if (_breezSdkSparkLibUninitialized) {
        await BreezSdkSparkLib.init();
        _breezSdkSparkLibUninitialized = false;
      }

      final seed = seedBytes != null
          ? Seed.entropy(seedBytes!)
          : Seed.mnemonic(mnemonic: mnemonic, passphrase: passphrase);
      final config = defaultConfig(network: Network.mainnet).copyWith(
        lnurlDomain: lnurlDomain,
        apiKey: apiKey,
        privateEnabledDefault: true,
        maxDepositClaimFee: MaxFee.rate(satPerVbyte: BigInt.from(5)),
        stableBalanceConfig: LightningWallet.buildStableBalanceConfig(
          stableBalanceTokens,
          thresholdSats: settings?.thresholdSats,
          maxSlippageBps: settings?.maxSlippageBps ?? defaultMaxSlippageBps,
        ),
      );

      final connectRequest = ConnectRequest(
        config: config,
        seed: seed,
        storageDir: "$appPath/.breez/",
      );

      _sdk = await connect(request: connectRequest);
      _stableBalanceTokens = stableBalanceTokens;

      // Reassigned unconditionally (not `??=`): a reconnect via
      // [reconnectWithStableBalanceSettings] replaces `_sdk`, so the old event stream - bound to
      // the now-disconnected session - must not linger. Callers re-subscribe after a successful
      // reconnect (see that method's doc comment).
      _eventStream = sdk.addEventListener().asBroadcastStream();
      _attachEventListener?.call();

      try {
        _setStableBalanceActive((await sdk.getUserSettings()).stableBalanceActiveLabel != null);
      } catch (e) {
        printV("LightningWallet: reading Stable Balance state failed: $e");
      }

      // Best-effort only: [initLogging] wraps a native, process-wide singleton that stays
      // initialized for the lifetime of the OS process, surviving a Dart-side hot restart even
      // though the `_logStream ??=` guard above it does not (hot restart resets top-level Dart
      // variables back to their initial values, but not native/FFI state). [_sdk]/[_eventStream]
      // are already validly set above by this point, so a failure here must not fail the whole
      // connect/reconnect - it would otherwise falsely report Stable Balance's
      // reconnect-to-apply-new-settings flow as failed despite the reconnect having actually
      // succeeded.
      try {
        _logStream ??= initLogging().asBroadcastStream();
      } catch (e) {
        printV("LightningWallet: initLogging failed (non-fatal): $e - an earlier Dart session in "
            "this process (e.g. a hot restart) left its SDK instances running, still syncing and "
            "converting with their own Stable Balance state; force-stop the app before testing it");
      }

      try {
        final logFile = File("$appPath/lightning.log")..createSync();
        _subscribeToLogStream(logFile);
      } catch (e) {
        printV(e);
      }

      await sdk.syncWallet(request: const SyncWalletRequest());

      return true;
    } catch (e) {
      printV(e);
      return false;
    }
  }

  /// Applies changed [stableBalanceSettings] (threshold/slippage/tokens) to an already-connected
  /// wallet. Since they only exist on the connect-time [StableBalanceConfig] (not
  /// [UpdateUserSettingsRequest]), the only way to change them is a full disconnect + reconnect.
  /// The on/off toggle itself ([setStableBalanceActive]) needs none of this - it's a live
  /// settings write.
  ///
  /// On success, [_eventStream] points at the new session; the caller MUST re-subscribe (e.g.
  /// `BitcoinWalletBase.subscribeForUpdates()`) or Lightning/Spark events go unheard after this
  /// call, since the reconnect cancels whatever was listening to the old stream.
  Future<bool> reconnectWithStableBalanceSettings(String appPath) async {
    await close();

    return init(appPath);
  }

  Future<void> close() => _runExclusive(() async {
        await _disconnectCurrent();
        await _logSubscription?.cancel();
        _logSubscription = null;
      });

  /// Asks the SDK for a fresh sync; its Synced event is what refreshes balances and history.
  Future<void> sync() async {
    final current = _sdk;

    if (current == null) {
      return;
    }

    try {
      await current.syncWallet(request: const SyncWalletRequest());
    } catch (e) {
      printV("LightningWallet: sync failed: $e");
    }
  }

  Future<String?> getAddress() async {
    var retries = 0;
    while (retries < MAX_RETRIES) {
      try {
        final address = (await sdk.getLightningAddress())?.lightningAddress;

        if (address != null) {
          cachedAddress = address;
          return address;
        }
      } catch (_) {} // No need to log here since it should be in the lightning log
      retries++;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return cachedAddress;
  }

  Future<String> getDepositAddress() async => (await sdk.receivePayment(
        request: const ReceivePaymentRequest(paymentMethod: ReceivePaymentMethod.bitcoinAddress()),
      ))
          .paymentRequest;

  /// Requests a specific amount of a specific Spark token, the way a BOLT11 invoice requests a
  /// specific amount of BTC.
  Future<String> getSparkInvoice({
    String? tokenIdentifier,
    BigInt? amount,
    String? description,
    BigInt? expiryTime,
    String? senderPublicKey,
  }) async =>
      (await sdk.receivePayment(
        request: ReceivePaymentRequest(
          paymentMethod: ReceivePaymentMethod.sparkInvoice(
            tokenIdentifier: tokenIdentifier,
            amount: amount,
            description: description,
            expiryTime: expiryTime,
            senderPublicKey: senderPublicKey,
          ),
        ),
      ))
          .paymentRequest;

  Future<Money> getBalance() async {
    try {
      return Money(
        (await sdk.getInfo(request: const GetInfoRequest(ensureSynced: true))).balanceSats,
        CryptoCurrency.btcln,
      );
    } on SdkError_Generic catch (_) {
    } on SdkError_NetworkError catch (_) {}

    return Money.zero(CryptoCurrency.btcln);
  }

  /// Every Spark token balance currently held, keyed by tokenIdentifier. Rides the same
  /// cache/sync lifecycle as [getBalance] (both come off the one `getInfo` call).
  /// The Stable Balance label currently active (matches a [StableBalanceToken.label] passed to
  /// [init]), or null if Stable Balance is off. Never active unless the user explicitly turned it
  /// on via [setStableBalanceActive] - see [init]'s doc comment.
  Future<String?> getActiveStableBalanceLabel() async {
    final label = (await sdk.getUserSettings()).stableBalanceActiveLabel;

    _setStableBalanceActive(label != null);

    return label;
  }

  /// Turns Stable Balance on for [label] (a [StableBalanceToken.label] registered at [init]
  /// time), or off when [label] is null.
  Future<void> setStableBalanceActive(String? label) async {
    await sdk.updateUserSettings(
      request: UpdateUserSettingsRequest(
        stableBalanceActiveLabel: label != null
            ? StableBalanceActiveLabel.set_(label: label)
            : const StableBalanceActiveLabel.unset(),
      ),
    );

    // Unlike `sendPayment`, `sdk.updateUserSettings` returns `Result<(), SdkError>` with no
    // independent status to second-guess - not throwing above already is the SDK's confirmation
    // the write applied, so just use label != null to identify true/false.
    _setStableBalanceActive(label != null);
  }

  Future<Map<String, TokenBalance>> getTokenBalances() async {
    try {
      return (await sdk.getInfo(request: const GetInfoRequest(ensureSynced: true))).tokenBalances;
    } on SdkError_Generic catch (_) {
    } on SdkError_NetworkError catch (_) {}

    return const {};
  }

  Future<Money> getTokenBalance(String tokenIdentifier, Currency currency) async {
    final balances = await getTokenBalances();

    final balance = balances[tokenIdentifier];

    if (balance == null) {
      return Money.zero(currency);
    }

    return Money(balance.balance, currency);
  }

  /// Fetches metadata (name, ticker, decimals, ...) for token identifiers not currently held,
  /// e.g. when a user manually adds a Spark token by its identifier.
  Future<List<TokenMetadata>> getTokensMetadata(List<String> tokenIdentifiers) async {
    final response = await sdk.getTokensMetadata(
      request: GetTokensMetadataRequest(tokenIdentifiers: tokenIdentifiers),
    );

    return response.tokensMetadata;
  }

  Future<String> registerAddress(String username) async => (await sdk.registerLightningAddress(
        request: RegisterLightningAddressRequest(username: username),
      ))
          .lightningAddress;

  Future<String?> getBolt11Invoice(BigInt? amount, String description) async {
    try {
      final response = await sdk.receivePayment(
        request: ReceivePaymentRequest(
          paymentMethod: ReceivePaymentMethod.bolt11Invoice(
            description: description,
            amountSats: amount,
          ),
        ),
      );

      return response.paymentRequest;
    } on SdkError_NetworkError catch (_) {
      return null;
    } on SdkError_SparkError catch (e) {
      if (!e.field0.contains("dns") && !e.field0.contains("TimedOut")) {
        rethrow;
      }
      return null;
    }
  }

  Future<bool> isCompatible(String input) async {
    try {
      final inputType = await sdk.parse(input: input);
      return (inputType is InputType_Bolt11Invoice) ||
          (inputType is InputType_LightningAddress) ||
          (inputType is InputType_LnurlPay);
    } catch (_) {
      return false;
    }
  }

  Future<PendingLightningTransaction> createTransaction(
    String address,
    BigInt? amountSats,
    BitcoinTransactionPriority? priority, {
    required bool feesIncluded,
    String? tokenIdentifier,
    Currency? tokenCurrency,
    int? maxSlippageBps,
  }) async {
    final inputType = await sdk.parse(input: address);

    // When sending a Spark token, amounts/fees are denominated in the token's own currency
    // (e.g. a SparkToken) rather than BTC/Lightning.
    final txCurrency = tokenIdentifier != null ? (tokenCurrency ?? currency) : currency;

    final isSparkDestination =
        inputType is InputType_SparkAddress || inputType is InputType_SparkInvoice;

    // A Bolt11/LNURL/Bitcoin-address destination only ever settles in sats - it has no Spark
    // token field to deliver [tokenIdentifier] to directly. Spending the token to fund a sats
    // payment (rather than delivering it) is still possible, by asking the SDK to convert it -
    // see the docs' "Sending payments with stable balance". amountSats is then denominated in
    // the token's own base units (an [AmountIn] to convert), same as a direct Spark send below.
    final needsConversion = tokenIdentifier != null && !isSparkDestination;
    final conversionOptions = needsConversion
        ? ConversionOptions(
            conversionType: ConversionType.toBitcoin(fromTokenIdentifier: tokenIdentifier),
            maxSlippageBps: maxSlippageBps ?? defaultMaxSlippageBps,
          )
        : null;

    // The SDK rejects any other policy for a token-funded LNURL send, and it's the right
    // semantics either way for a conversion: the amount is the total spent, fee already included,
    // not something to add on top of.
    final feePolicy =
        feesIncluded || conversionOptions != null ? FeePolicy.feesIncluded : FeePolicy.feesExcluded;

    if (isSparkDestination) {
      final resolvedTokenIdentifier = tokenIdentifier ??
          (inputType is InputType_SparkInvoice ? inputType.field0.tokenIdentifier : null);

      final request = PrepareSendPaymentRequest(
        paymentRequest: PaymentRequest.input(input: address),
        amount: amountSats,
        tokenIdentifier: resolvedTokenIdentifier,
        feePolicy: feePolicy,
      );

      final prepareResponse = await sdk.prepareSendPayment(request: request);
      final paymentMethod = prepareResponse.paymentMethod;

      BigInt? fee;

      if (paymentMethod is SendPaymentMethod_SparkAddress) {
        fee = paymentMethod.fee;
      } else if (paymentMethod is SendPaymentMethod_SparkInvoice) {
        fee = paymentMethod.fee;
      }

      if (fee != null) {
        return PendingLightningTransaction(
          id: "",
          amount: Money(prepareResponse.amount, txCurrency),
          fee: Money(fee, txCurrency),
          conversion: _sendConversionFrom(prepareResponse.conversionEstimate),
          commitOverride: () async {
            final res = await sdk.sendPayment(
              request: SendPaymentRequest(prepareResponse: prepareResponse),
            );
            return res.payment.id;
          },
        );
      }
    } else if (inputType is InputType_Bolt11Invoice) {
      // A token-funded conversion can't be combined with a fixed invoice amount (the SDK
      // rejects it as ambiguous - the converted sats may not match) - omit it and let the SDK
      // derive the sats needed from the invoice itself.
      final hasFixedAmount = inputType.field0.amountMsat != null;

      final request = PrepareSendPaymentRequest(
        paymentRequest: PaymentRequest.input(input: inputType.field0.invoice.bolt11),
        amount: conversionOptions != null && hasFixedAmount ? null : amountSats,
        tokenIdentifier: conversionOptions != null ? tokenIdentifier : null,
        conversionOptions: conversionOptions,
        feePolicy: feePolicy,
      );

      final prepareResponse = await sdk.prepareSendPayment(request: request);

      final paymentMethod = prepareResponse.paymentMethod;

      if (paymentMethod is SendPaymentMethod_Bolt11Invoice) {
        final lightningFeeSats = paymentMethod.lightningFeeSats;
        final sparkTransferFeeSats = paymentMethod.sparkTransferFeeSats;

        return PendingLightningTransaction(
          id: paymentMethod.invoiceDetails.paymentHash,
          // Always the sats actually paid over Lightning - a Bolt11 send is never itself a
          // "token payment" even when a token conversion funds it (unlike the Spark branch above,
          // where the payment itself is denominated in the token).
          amount: Money(prepareResponse.amount, currency),
          fee: Money(lightningFeeSats + (sparkTransferFeeSats ?? BigInt.zero), currency),
          conversion: _sendConversionFrom(prepareResponse.conversionEstimate),
          commitOverride: () async {
            try {
              final res = await sdk.sendPayment(
                request: SendPaymentRequest(prepareResponse: prepareResponse),
              );

              return res.payment.id;
            } on SdkError_SparkError catch (e) {
              if (e.field0.contains("AlreadyExists")) {
                throw Exception("Invoice already paid");
              }

              rethrow;
            }
          },
        );
      }
    } else if (inputType is InputType_LightningAddress || inputType is InputType_LnurlPay) {
      const optionalValidateSuccessActionUrl = true;

      PrepareLnurlPayRequest request;
      if (inputType is InputType_LightningAddress) {
        request = PrepareLnurlPayRequest(
          amount: amountSats!,
          payRequest: inputType.field0.payRequest,
          validateSuccessActionUrl: optionalValidateSuccessActionUrl,
          tokenIdentifier: tokenIdentifier,
          conversionOptions: conversionOptions,
          feePolicy: feePolicy,
        );
      } else {
        request = PrepareLnurlPayRequest(
          amount: amountSats!,
          payRequest: (inputType as InputType_LnurlPay).field0,
          validateSuccessActionUrl: optionalValidateSuccessActionUrl,
          tokenIdentifier: tokenIdentifier,
          conversionOptions: conversionOptions,
          feePolicy: feePolicy,
        );
      }

      final prepareResponse = await sdk.prepareLnurlPay(request: request);

      return PendingLightningTransaction(
        id: prepareResponse.invoiceDetails.paymentHash,
        amount: Money(prepareResponse.amountSats, currency),
        fee: Money(prepareResponse.feeSats, currency),
        conversion: _sendConversionFrom(prepareResponse.conversionEstimate),
        commitOverride: () async {
          final res =
              await sdk.lnurlPay(request: LnurlPayRequest(prepareResponse: prepareResponse));
          printV(res.payment.status.name);
          return res.payment.id;
        },
      );
    } else if (inputType is InputType_BitcoinAddress) {
      final request = PrepareSendPaymentRequest(
        paymentRequest: PaymentRequest.input(input: inputType.field0.address),
        amount: amountSats,
        tokenIdentifier: conversionOptions != null ? tokenIdentifier : null,
        conversionOptions: conversionOptions,
        feePolicy: feePolicy,
      );
      final prepareResponse = await sdk.prepareSendPayment(request: request);

      final paymentMethod = prepareResponse.paymentMethod;
      if (paymentMethod is SendPaymentMethod_BitcoinAddress) {
        final feeQuote = paymentMethod.feeQuote;

        OnchainConfirmationSpeed onchainConfirmationSpeed;
        BigInt fee;
        switch (priority) {
          case BitcoinTransactionPriority.fast:
            fee = feeQuote.speedFast.userFeeSat + feeQuote.speedFast.l1BroadcastFeeSat;
            onchainConfirmationSpeed = OnchainConfirmationSpeed.fast;
            break;
          case BitcoinTransactionPriority.medium:
            fee = feeQuote.speedMedium.userFeeSat + feeQuote.speedMedium.l1BroadcastFeeSat;
            onchainConfirmationSpeed = OnchainConfirmationSpeed.medium;
            break;
          case BitcoinTransactionPriority.slow:
          default:
            fee = feeQuote.speedSlow.userFeeSat + feeQuote.speedSlow.l1BroadcastFeeSat;
            onchainConfirmationSpeed = OnchainConfirmationSpeed.slow;
        }

        return PendingLightningTransaction(
          id: "", // ToDo: Find out where to get it
          amount: Money(prepareResponse.amount, currency),
          fee: Money(fee, currency),
          conversion: _sendConversionFrom(prepareResponse.conversionEstimate),
          isOnChain: true,
          commitOverride: () async {
            final options =
                SendPaymentOptions.bitcoinAddress(confirmationSpeed: onchainConfirmationSpeed);
            final res = await sdk.sendPayment(
              request: SendPaymentRequest(prepareResponse: prepareResponse, options: options),
            );
            return res.payment.id;
          },
        );
      }
    }

    // If not returned earlier
    throw UnimplementedError();
  }

  /// Prepares [address]/[amountSats] like [createTransaction] without sending anything.
  Future<LightningSendQuote> quoteSend(
    String address,
    BigInt amountSats, {
    String? tokenIdentifier,
    Currency? tokenCurrency,
    bool sendAll = false,
    int? maxSlippageBps,
  }) async {
    final tx = await createTransaction(
      address,
      amountSats,
      null,
      feesIncluded: sendAll,
      tokenIdentifier: tokenIdentifier,
      tokenCurrency: tokenCurrency,
      maxSlippageBps: maxSlippageBps,
    );

    return LightningSendQuote(
      amount: tx.amount,
      fee: tx.fee,
      conversion: tx.conversion,
      isOnChain: tx.isOnChain,
    );
  }

  StableBalanceSendConversion? _sendConversionFrom(ConversionEstimate? estimate) =>
      sendConversionFrom(estimate, resolveToken: tokenCurrencyResolver);

  /// The stablecoin -> sats conversion the SDK added to a send, or null if it pays from sats (or
  /// the token isn't one [resolveToken] knows).
  static StableBalanceSendConversion? sendConversionFrom(
    ConversionEstimate? estimate, {
    required Currency? Function(String tokenIdentifier)? resolveToken,
  }) {
    final type = estimate?.options.conversionType;
    if (estimate == null || type is! ConversionType_ToBitcoin) {
      return null;
    }
    final token = resolveToken?.call(type.fromTokenIdentifier);
    if (token == null) {
      return null;
    }
    return StableBalanceSendConversion(
      amountIn: Money(estimate.amountIn, token),
      amountOut: Money(estimate.amountOut, CryptoCurrency.btcln),
      fee: Money(estimate.fee, token),
      amountAdjustment:
          ConversionAmountAdjustment.values.asNameMap()[estimate.amountAdjustment?.name],
    );
  }

  Future<Map<String, ElectrumTransactionInfo>> getTransactionHistory({DateTime? fromDate}) async {
    final request = ListPaymentsRequest(
      typeFilter: [PaymentType.send, PaymentType.receive],
      // statusFilter: [PaymentStatus.completed],
      fromTimestamp:
          fromDate != null ? BigInt.from((fromDate.millisecondsSinceEpoch / 1000).round()) : null,
      assetFilter: const AssetFilter.bitcoin(),
      offset: 0,
      limit: 50,
      sortAscending: false, // Sort order (true = oldest first, false = newest first)
    );
    final response = await sdk.listPayments(request: request);
    final payments = response.payments;

    final txHistory = <String, ElectrumTransactionInfo>{};
    for (final payment in payments) {
      txHistory[payment.id] = _getElectrumTransactionInfoFromPayment(payment);
    }

    return txHistory;
  }

  /// Return a list of UnclaimedDeposits including a possible reason why they where not auto-claimed
  /// A unclaimed deposit is a [Map] consisting of the following datatypes
  ///
  /// | ----------------- | --------- |--------------------------------------------------- |
  /// | key-name          | data-type | description                                        |
  /// | ----------------- | --------- |--------------------------------------------------- |
  /// | txId              | String    | The txId of the deposit transaction                |
  /// | vout              | int       | The output index of the deposit                    |
  /// | amount            | BigInt    | Amount of the deposit in sats.                     |
  /// | claimError        | String?   | The type of Claim error                            |
  /// | actualFee         | BigInt?   | The actualFee in case of a DepositClaimFeeExceeded |
  /// | claimErrorMessage | String?   | The claimErrorMessage in case of a Generic Error   |
  ///
  Future<List<Map<String, dynamic>>> getUnclaimedDeposits() async {
    final unclaimedDeposits = <Map<String, dynamic>>[];
    final response = await sdk.listUnclaimedDeposits(request: const ListUnclaimedDepositsRequest());
    for (final deposit in response.deposits) {
      final unclaimedDeposit = {
        "txId": deposit.txid,
        "vout": deposit.vout,
        "amount": deposit.amountSats,
      };

      final claimError = deposit.claimError;
      if (claimError is DepositClaimError_MaxDepositClaimFeeExceeded) {
        unclaimedDeposit["claimError"] = "DepositClaimError_MaxDepositClaimFeeExceeded";
        unclaimedDeposit["actualFee"] = claimError.requiredFeeSats;
      } else if (claimError is DepositClaimError_MissingUtxo) {
        unclaimedDeposit["claimError"] = "MissingUtxo";
      } else if (claimError is DepositClaimError_Generic) {
        unclaimedDeposit["claimError"] = "Generic";
        unclaimedDeposit["claimErrorMessage"] = claimError.message;
      }
    }

    return unclaimedDeposits;
  }

  Future<ElectrumTransactionInfo?> claimDeposit(String txId, int vout, BigInt newFee) async {
    final response = await sdk.claimDeposit(
      request: ClaimDepositRequest(
        txid: txId,
        vout: vout,
        maxFee: MaxFee.fixed(amount: newFee),
      ),
    );

    if (response.payment == null) {
      return null;
    }
    return _getElectrumTransactionInfoFromPayment(response.payment!);
  }

  Future<String> refundDeposit(
    String txId,
    int vout,
    String destinationAddress,
    BigInt feeRate,
  ) async {
    final response = await sdk.refundDeposit(
      request: RefundDepositRequest(
        txid: txId,
        vout: vout,
        destinationAddress: destinationAddress,
        fee: Fee.rate(satPerVbyte: feeRate),
      ),
    );

    return response.txHex;
  }

  /// Requests a refund for every conversion currently in a refundable state (i.e.
  /// [ConversionStatus.refundNeeded]) - distinct from [refundDeposit], which refunds an
  /// unclaimed on-chain deposit UTXO, not a failed Stable Balance conversion.
  Future<RefundPendingConversionsResponse> refundPendingConversions() =>
      sdk.refundPendingConversions();

  /// Converts Bitcoin into [tokenIdentifier] using the Breez SDK's Flashnet-based on-the-fly
  /// conversion. There's no standalone "convert" API - the SDK only converts as a side-effect of
  /// a payment - so this pays the wallet's own Spark address, which has the effect of a pure
  /// self-conversion with no external recipient. See
  /// https://sdk-doc-spark.breez.technology/guide/token_conversion.html.
  ///
  /// [tokenAmount] is denominated in [tokenIdentifier]'s own base units (e.g. USDB), NOT sats -
  /// per the SDK's own example, `PrepareSendPaymentRequest.amount` always means "how much of the
  /// target token to end up with" when a [tokenIdentifier] is set, even under
  /// [ConversionType.fromBitcoin]. The BTC actually spent is computed by the SDK and reported
  /// back as [ConversionEstimate.amountIn] - it can't be specified directly. Passing a sats
  /// amount here instead (an earlier version of this method did) makes the SDK compare that raw
  /// number against its token-amount minimum, failing confusingly for any real sats value.
  Future<SparkConversionQuote> prepareBitcoinToTokenConversion({
    required BigInt tokenAmount,
    required String tokenIdentifier,
    required Currency tokenCurrency,
    int? maxSlippageBps,
    int? completionTimeoutSecs,
  }) async {
    final request = PrepareSendPaymentRequest(
      paymentRequest: PaymentRequest.input(input: await getSparkInvoice()),
      amount: tokenAmount,
      tokenIdentifier: tokenIdentifier,
      conversionOptions: ConversionOptions(
        conversionType: const ConversionType.fromBitcoin(),
        maxSlippageBps: maxSlippageBps,
        completionTimeoutSecs: completionTimeoutSecs,
      ),
    );

    final prepareResponse = await sdk.prepareSendPayment(request: request);
    final estimate = prepareResponse.conversionEstimate;

    if (estimate == null) {
      throw StateError("Breez SDK did not return a conversion estimate for this request");
    }

    return SparkConversionQuote(
      amountIn: Money(estimate.amountIn, currency),
      amountOut: Money(estimate.amountOut, tokenCurrency),
      fee: Money(estimate.fee, tokenCurrency),
      commit: () async {
        final res =
            await sdk.sendPayment(request: SendPaymentRequest(prepareResponse: prepareResponse));

        // `sendPayment` not throwing only means the SDK accepted the request, not that the
        // payment/conversion actually completed - a failed status still comes back as a normal
        // (non-throwing) response, which would otherwise show as a false "success" with nothing
        // actually changing in the wallet.
        if (res.payment.status == PaymentStatus.failed) {
          throw StateError("Conversion payment failed (id=${res.payment.id})");
        }

        return res.payment.id;
      },
    );
  }

  /// Minimum amounts the SDK will accept for a Bitcoin -> [tokenIdentifier] conversion - fetch
  /// this before letting the user submit an amount, since [prepareBitcoinToTokenConversion] will
  /// otherwise fail server-side for amounts below the protocol minimum.
  Future<SparkConversionLimits> fetchBitcoinToTokenConversionLimits({
    required String tokenIdentifier,
    required Currency tokenCurrency,
  }) async {
    final response = await sdk.fetchConversionLimits(
      request: FetchConversionLimitsRequest(
        conversionType: const ConversionType.fromBitcoin(),
        tokenIdentifier: tokenIdentifier,
      ),
    );

    return SparkConversionLimits(
      minAmountIn: response.minFromAmount == null ? null : Money(response.minFromAmount!, currency),
      minAmountOut:
          response.minToAmount == null ? null : Money(response.minToAmount!, tokenCurrency),
    );
  }

  /// The reverse of [prepareBitcoinToTokenConversion]: converts [tokenIdentifier] into Bitcoin,
  /// via [ConversionType.toBitcoin]. Per the Breez SDK docs, this direction derives the amount to
  /// convert from the PAYMENT REQUEST itself (`amount` is left null) rather than from a request
  /// field - so [satsAmount] is realized by first creating a self-addressed BOLT11 invoice for
  /// exactly that many sats (reusing [getBolt11Invoice]), then paying it via a conversion that
  /// pulls the required token amount from the wallet's own Spark token balance.
  Future<SparkConversionQuote> prepareTokenToBitcoinConversion({
    required BigInt satsAmount,
    required String tokenIdentifier,
    required Currency tokenCurrency,
    int? maxSlippageBps,
    int? completionTimeoutSecs,
  }) async {
    final selfInvoice = await getBolt11Invoice(satsAmount, "Stable Conversion");

    if (selfInvoice == null) {
      throw StateError("Could not create a self-invoice for this conversion");
    }

    final request = PrepareSendPaymentRequest(
      paymentRequest: PaymentRequest.input(input: selfInvoice),
      conversionOptions: ConversionOptions(
        conversionType: ConversionType.toBitcoin(fromTokenIdentifier: tokenIdentifier),
        maxSlippageBps: maxSlippageBps,
        completionTimeoutSecs: completionTimeoutSecs,
      ),
    );

    final prepareResponse = await sdk.prepareSendPayment(request: request);
    final estimate = prepareResponse.conversionEstimate;

    if (estimate == null) {
      throw StateError("Breez SDK did not return a conversion estimate for this request");
    }

    return SparkConversionQuote(
      amountIn: Money(estimate.amountIn, tokenCurrency),
      amountOut: Money(estimate.amountOut, currency),
      fee: Money(estimate.fee, tokenCurrency),
      commit: () async {
        final res =
            await sdk.sendPayment(request: SendPaymentRequest(prepareResponse: prepareResponse));

        if (res.payment.status == PaymentStatus.failed) {
          throw StateError("Conversion payment failed (id=${res.payment.id})");
        }

        return res.payment.id;
      },
    );
  }

  /// Minimum amounts the SDK will accept for a [tokenIdentifier] -> Bitcoin conversion. Note the
  /// SDK's `minFromAmount`/`minToAmount` follow the conversion's own from/to direction (from =
  /// token, to = BTC) here, the opposite of [fetchBitcoinToTokenConversionLimits] - mapped back
  /// onto [SparkConversionLimits]'s fixed BTC-in/token-out fields accordingly.
  Future<SparkConversionLimits> fetchTokenToBitcoinConversionLimits({
    required String tokenIdentifier,
    required Currency tokenCurrency,
  }) async {
    final response = await sdk.fetchConversionLimits(
      request: FetchConversionLimitsRequest(
        conversionType: ConversionType.toBitcoin(fromTokenIdentifier: tokenIdentifier),
      ),
    );

    return SparkConversionLimits(
      minAmountIn: response.minToAmount == null ? null : Money(response.minToAmount!, currency),
      minAmountOut:
          response.minFromAmount == null ? null : Money(response.minFromAmount!, tokenCurrency),
    );
  }

  void setEventListener({
    required Function(ElectrumTransactionInfo) onTransactionEvent,
    required Function onBalanceChangedEvent,
    required Function onSyncedEvent,
    required Function(Map<String, ElectrumTransactionInfo>) onCreateDepositTransactionEvent,
    required Function(List<ElectrumTransactionInfo>) onUpdateDepositTransactionEvent,
  }) {
    // Kept so every later (re)connect re-attaches the same listener to its new event stream -
    // otherwise any path that re-inits (username change, Lightning re-enabled) goes deaf.
    _attachEventListener = () {
      _eventSubscription?.cancel();
      _eventSubscription = _eventStream?.listen(_onSdkEvent);
    };

    _onSdkEvent = (sdkEvent) {
      // The SDK suppresses payment events for Stable Balance auto-conversions; Synced is the only
      // signal one finished.
      if (sdkEvent is SdkEvent_Synced) {
        onSyncedEvent();
      } else if (sdkEvent is SdkEvent_PaymentSucceeded) {
        onTransactionEvent(_getElectrumTransactionInfoFromPayment(sdkEvent.payment));
      } else if (sdkEvent is SdkEvent_PaymentPending) {
        onTransactionEvent(_getElectrumTransactionInfoFromPayment(sdkEvent.payment));
      } else if (sdkEvent is SdkEvent_PaymentFailed) {
        // Otherwise a failed conversion (e.g. refund needed) never updates past "pending" in
        // history - there's no dedicated conversion-status event, only whichever payment event
        // happens to fire next for that payment.
        onTransactionEvent(_getElectrumTransactionInfoFromPayment(sdkEvent.payment));
      } else if (sdkEvent is SdkEvent_ClaimedDeposits) {
        onBalanceChangedEvent();

        onUpdateDepositTransactionEvent(
          sdkEvent.claimedDeposits.map(_getElectrumTransactionInfoFromDepositInfo).toList(),
        );
      } else if (sdkEvent is SdkEvent_UnclaimedDeposits) {
        final unclaimedDeposits = <String, ElectrumTransactionInfo>{};

        for (final deposit in sdkEvent.unclaimedDeposits) {
          unclaimedDeposits[deposit.txid] = _getElectrumTransactionInfoFromDepositInfo(deposit);
        }

        onCreateDepositTransactionEvent(unclaimedDeposits);
      }
    };

    _attachEventListener!();
  }

  void Function()? _attachEventListener;
  void Function(SdkEvent) _onSdkEvent = (_) {};

  ElectrumTransactionInfo _getElectrumTransactionInfoFromPayment(
    Payment payment, {
    Currency? currencyOverride,
  }) {
    var direction = TransactionDirection.outgoing;

    if (payment.paymentType == PaymentType.receive) {
      direction = TransactionDirection.incoming;
    }
    if (payment.method == PaymentMethod.deposit) {
      direction = TransactionDirection.incoming;
    }

    String? preimage;
    if (payment.details != null && payment.details is PaymentDetails_Lightning) {
      preimage = (payment.details as PaymentDetails_Lightning).htlcDetails.preimage;
    }

    String? tokenIdentifier;
    final details = payment.details;
    if (details is PaymentDetails_Token) {
      tokenIdentifier = details.metadata.identifier;
    }

    // Pairing key for the twin send+receive records the SDK creates when paying your own
    // invoice (e.g. our own toBitcoin self-invoice conversion) - both twins share the same HTLC,
    // so the same paymentHash, even though they're two separate `payment.id`s.
    String? paymentHash;
    ConversionInfo? conversionInfo;
    switch (details) {
      case PaymentDetails_Lightning():
        paymentHash = details.htlcDetails.paymentHash;
        conversionInfo = details.conversionInfo;
      case PaymentDetails_Spark():
        paymentHash = details.htlcDetails?.paymentHash;
        conversionInfo = details.conversionInfo;
      case PaymentDetails_Token():
        conversionInfo = details.conversionInfo;
      default:
        break;
    }

    final isSelfTransfer = conversionInfo is ConversionInfo_Amm &&
        conversionInfo.purpose is ConversionPurpose_SelfTransfer;

    final txCurrency = currencyOverride ??
        (tokenIdentifier != null ? tokenCurrencyResolver?.call(tokenIdentifier) : null) ??
        currency;

    // The conversion's actual from/to assets, straight from the SDK - not inferred from ticker
    // string comparisons, since a BTC-destination conversion's asset has no `identifier` while a
    // token-destination one always does, regardless of what either ticker happens to read.
    final conversion = payment.conversionDetails?.conversions.firstOrNull;

    // A send the SDK funded by converting from a token (Stable Balance, or an explicitly
    // token-denominated send) is still just a send to its recipient - the conversion is how it
    // was paid for, not what happened. Tagged separately so it isn't shown as a conversion.
    final fundedSendConversion = payment.paymentType == PaymentType.send &&
            conversion != null &&
            conversion.to.asset.identifier == null
        ? conversion
        : null;

    // A conversion's own internal legs (e.g. the token send + sats receive of a Stable Balance
    // conversion) carry this until the SDK links them under their parent - which only happens
    // after the conversion finishes, and never for a failed one. Both legs share conversionId.
    final leg = conversionInfo is ConversionInfo_Amm && fundedSendConversion == null
        ? conversionInfo
        : null;

    final legTags = <String, dynamic>{};

    if (leg != null) {
      legTags["conversionId"] = leg.conversionId;

      // "ongoingPayment" legs are plumbing of a send (see [fundedSendConversion]) rather than
      // something the user did.
      legTags["conversionPurpose"] = switch (leg.purpose) {
        ConversionPurpose_OngoingPayment() => "ongoingPayment",
        ConversionPurpose_SelfTransfer() => "selfTransfer",
        ConversionPurpose_AutoConversion() => "autoConversion",
        null => "unknown",
      };

      if (payment.conversionDetails == null) {
        final legIsToken = tokenIdentifier != null;
        final ownTicker = legIsToken ? txCurrency.symbol : "BTC";
        final otherTicker = legIsToken ? "BTC" : (_stableBalanceTokens.firstOrNull?.label ?? "USD");
        final incoming = direction == TransactionDirection.incoming;

        legTags.addAll({
          "conversionStatus": leg.status.name,
          "conversionFromTicker": incoming ? otherTicker : ownTicker,
          "conversionToTicker": incoming ? ownTicker : otherTicker,
          "conversionToIsToken": incoming ? legIsToken : !legIsToken,
        });
      }
    }

    final amountAdjustment = conversion?.amountAdjustment ?? leg?.amountAdjustment;

    return ElectrumTransactionInfo(
      WalletType.bitcoin,
      id: payment.id,
      amount: Money(payment.amount, txCurrency),
      direction: direction,
      isPending: payment.status == PaymentStatus.pending,
      fee: Money(payment.fees, txCurrency),
      date: DateTime.fromMillisecondsSinceEpoch(payment.timestamp.toInt() * 1000),
      confirmations: payment.status == PaymentStatus.pending ? 0 : 10,
      additionalInfo: {
        "isLightning": true,
        "lnTagVersion": historyTagVersion,
        if (preimage != null) "preimage": preimage,
        if (paymentHash != null) "paymentHash": paymentHash,
        if (isSelfTransfer) "isSelfTransfer": true,
        if (tokenIdentifier != null) "tokenIdentifier": tokenIdentifier,
        if (payment.conversionDetails != null && fundedSendConversion == null)
          "conversionStatus": payment.conversionDetails!.status.name,
        ...legTags,
        if (fundedSendConversion != null) ...{
          "paidFromTicker": fundedSendConversion.from.asset.ticker,
          "paidFromAmount": fundedSendConversion.from.amount.toString(),
          "paidFromDecimals": fundedSendConversion.from.asset.decimals,
        },
        if (conversion != null && fundedSendConversion == null) ...{
          "conversionFromTicker": conversion.from.asset.ticker,
          "conversionToTicker": conversion.to.asset.ticker,
          "conversionToIsToken": conversion.to.asset.identifier != null,
          "conversionFromAmount": conversion.from.amount.toString(),
          "conversionFromFee": conversion.from.fee.toString(),
          "conversionFromDecimals": conversion.from.asset.decimals,
          "conversionToAmount": conversion.to.amount.toString(),
          "conversionToFee": conversion.to.fee.toString(),
          "conversionToDecimals": conversion.to.asset.decimals,
        },
        if (amountAdjustment != null) "conversionAmountAdjustment": amountAdjustment.name,
      },
    );
  }

  /// Re-reads one payment by id. The SDK sends no event when a conversion leg completes, so this
  /// is how a stored pending row learns it finished (or failed).
  Future<ElectrumTransactionInfo?> getTransactionById(String paymentId) async {
    try {
      final response = await sdk.getPayment(request: GetPaymentRequest(paymentId: paymentId));
      return _getElectrumTransactionInfoFromPayment(response.payment);
    } catch (e) {
      printV("LightningWallet: getPayment($paymentId) failed: $e");
      return null;
    }
  }

  /// Payment history for one Spark token, denominated in [tokenCurrency] rather than BTC.
  Future<Map<String, ElectrumTransactionInfo>> getTokenTransactionHistory(
    String tokenIdentifier,
    Currency tokenCurrency, {
    DateTime? fromDate,
  }) async {
    final request = ListPaymentsRequest(
      typeFilter: [PaymentType.send, PaymentType.receive],
      fromTimestamp:
          fromDate != null ? BigInt.from((fromDate.millisecondsSinceEpoch / 1000).round()) : null,
      assetFilter: AssetFilter.token(tokenIdentifier: tokenIdentifier),
      offset: 0,
      limit: 50,
      sortAscending: false,
    );

    final response = await sdk.listPayments(request: request);

    final txHistory = <String, ElectrumTransactionInfo>{};

    for (final payment in response.payments) {
      txHistory[payment.id] =
          _getElectrumTransactionInfoFromPayment(payment, currencyOverride: tokenCurrency);
    }

    return txHistory;
  }

  ElectrumTransactionInfo _getElectrumTransactionInfoFromDepositInfo(DepositInfo deposit) =>
      ElectrumTransactionInfo(
        WalletType.bitcoin,
        id: deposit.txid,
        amount: Money(deposit.amountSats, currency),
        direction: TransactionDirection.incoming,
        isPending: true,
        fee: Money.zero(currency),
        date: DateTime.now(),
        confirmations: 0,
        additionalInfo: {"isLightning": true, "isSparkDeposit": true},
      );
}
