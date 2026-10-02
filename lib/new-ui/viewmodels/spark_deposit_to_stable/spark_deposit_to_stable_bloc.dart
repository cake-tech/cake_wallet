import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/entities/pending_conversion.dart";
import "package:cake_wallet/entities/spark_conversion.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/dashboard/pending_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:collection/collection.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_groups.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:meta/meta.dart";

part "spark_deposit_to_stable_event.dart";
part "spark_deposit_to_stable_state.dart";

/// One-off "Deposit to Stable" conversion (BTC -> a stablecoin Spark token, e.g. USDB), reached
/// by tapping Swap on a stablecoin asset card. Completely separate from the Stable Balance
/// auto-convert toggle (`HomeSettingsViewModel`/`SparkSettingsPage`) - this Bloc never touches
/// that feature's settings.
class SparkDepositToStableBloc extends Bloc<SparkDepositToStableEvent, SparkDepositToStableState> {
  SparkDepositToStableBloc(
    this._wallet,
    this._fiatConversionStore,
    this._settingsStore,
    this._pendingConversionStore,
  ) : super(SparkDepositToStableNotLoaded()) {
    on<_Init>(_onInit);
    on<AmountChanged>(_onAmountChanged, transformer: restartable());
    on<MaxSlippageChanged>(_onMaxSlippageChanged, transformer: restartable());
    on<FiatEntryToggled>(_onFiatEntryToggled, transformer: restartable());
    on<DirectionChanged>(_onDirectionChanged, transformer: restartable());
    on<ConversionRequested>(_onConversionRequested, transformer: droppable());

    add(_Init());
  }

  final WalletBase _wallet;
  final FiatConversionStore _fiatConversionStore;
  final SettingsStore _settingsStore;
  final PendingConversionStore _pendingConversionStore;

  /// Mirrors `BalanceViewModel.isFiatDisabled`/`SendViewModel.isFiatDisabled` - the fiat<->sats
  /// switch is a no-op while fiat display is off in Settings.
  bool get isFiatDisabled => _settingsStore.fiatApiMode == FiatApiMode.disabled;

  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

  /// Mirrors `SendViewModel.setFiatCurrency` - a global Settings change, same as the regular
  /// Send flow's fiat currency picker. Re-requotes the currently typed amount under the new
  /// currency (the typed number itself isn't converted, matching that same precedent).
  void setFiatCurrency(FiatCurrency fiat) {
    _settingsStore.fiatCurrency = fiat;
    final current = state;
    if (current is SparkDepositToStableLoaded) {
      add(AmountChanged(current.amountText));
    }
  }

  /// The amount most recently sent to the SDK for each direction, and the resulting amount it
  /// quoted back - cached (separately per direction, since the spread can differ) so the NEXT
  /// typed amount can be estimated proportionally instead of guessing blind. Deliberately NOT
  /// derived from [_fiatConversionStore]: that price is in the user's settings fiat currency (off
  /// by the fiat's own exchange rate for non-USD users) and assumes a hard 1:1 USD peg, which
  /// would break for a non-USD-pegged stablecoin later. The SDK's own quotes are the only
  /// authoritative source for the BTC<->token rate.
  BigInt? _lastAmountInFwd;
  BigInt? _lastAmountOutFwd;
  BigInt? _lastAmountInRev;
  BigInt? _lastAmountOutRev;

  /// The wallet's current spendable Lightning/Spark BTC balance, shown as a "Max." reference
  /// next to the amount field (see `deposit_to_stable.dart`) when converting FROM Bitcoin - purely
  /// informational, since there's no correct way to auto-fill a token-denominated field from a
  /// sats value without a live reverse quote. A getter rather than a state field: it isn't
  /// something any event in this flow changes, so there's no reason to thread it through every
  /// state.
  Money? get availableLightningBalance => _wallet.balance[CryptoCurrency.btcln]?.available;

  /// The wallet's current spendable balance of [token], shown as the "Max." reference when
  /// converting TO Bitcoin (spending [token] instead of BTC/sats).
  Money? availableTokenBalance(CryptoCurrency token) => _wallet.balance[token]?.available;

  /// Mirrors `HomeSettingsViewModelBase.maxSlippagePresetsBps` - kept as this flow's own copy
  /// rather than a shared import, since Deposit to Stable is deliberately independent of the
  /// Stable Balance settings screen it otherwise resembles.
  static const List<int> maxSlippagePresetsBps = [50, 100, 200, 500];
  static const int defaultMaxSlippageBps = 100;

  String slippageLabel(int bps) => "${(bps / 100).toStringAsFixed(1)}%";

  /// Guards against [AmountChanged] and [MaxSlippageChanged] racing each other: they're
  /// separate event types, each with its own `restartable()` subscription, so `restartable()`
  /// alone only cancels a stale in-flight quote fetch against events of the *same* type - it
  /// does nothing if the other type starts a fetch concurrently. Every [_requote] call captures
  /// its own id from this counter and checks it's still current before emitting the fetch's
  /// result, so whichever fetch finishes last is never clobbered by a slower, now-stale one.
  int _requestSeq = 0;

  /// Parses [text] as typed into the amount field into a BTC-family [Money] - sats (a whole
  /// number, e.g. "1000") when `!isFiatEntry`, or the user's fiat currency (e.g. "12.50")
  /// converted to BTC via [_fiatConversionStore]'s rate when [isFiatEntry]. Null if blank, not a
  /// valid number, or (fiat only) no BTC/fiat rate is available yet.
  ///
  /// This is the BTC/sats *budget* the user is choosing to spend - never the token amount itself.
  /// The Breez SDK's `prepareSendPayment`/[ConversionType.fromBitcoin] only accepts a
  /// target-token amount directly (see `LightningWallet.prepareBitcoinToTokenConversion`'s doc
  /// comment), so the resulting stablecoin amount is only known once a quote comes back - see
  /// `_estimateTokenAmount`/`_requoteOrThrow`.
  Money? parseSatsOrFiatAmount(String text, {required bool isFiatEntry}) => isFiatEntry
      ? fiatTextToSats(text, _fiatConversionStore.prices[CryptoCurrency.btc])
      : satsTextToMoney(text);

  /// Converts [amountText] (denominated per [isFiatEntry]) into its equivalent amount in the
  /// OTHER denomination, as plain display text - "" if it can't be computed (invalid text, or no
  /// BTC/fiat rate yet). Purely for display (the amount field's own text after toggling
  /// [FiatEntryToggled], and [SparkDepositToStableLoaded]'s secondary amount in `deposit_to_stable.dart`)
  /// - never used for the actual token estimate, which only ever comes from the SDK's own quotes.
  String convertedAmountText(String amountText, {required bool isFiatEntry}) {
    final price = _fiatConversionStore.prices[CryptoCurrency.btc];
    if (isFiatEntry) {
      final sats = fiatTextToSats(amountText, price);
      return sats == null ? "" : sats.toStringWithPrecision(useBaseUnit: true);
    }
    final sats = satsTextToMoney(amountText);
    return sats == null ? "" : satsToFiatText(sats.amount, price);
  }

  /// Parses [text] as a whole number of sats into [CryptoCurrency.btcln] - the natural typed
  /// granularity for a Lightning/Spark balance (unlike a stablecoin's base units, which are a
  /// much finer subdivision than its natural "$" typed granularity - see `isBelowMinimum`'s
  /// callers for that other, unrelated trap). Pure - factored out so it's directly unit-testable.
  static Money? satsTextToMoney(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return Money.tryParse(trimmed, CryptoCurrency.btcln, isBaseUnit: true);
  }

  /// Converts a fiat-denominated [text] into BTC-family [Money], using [btcPrice] (the BTC price
  /// in that fiat currency) - null if the text is invalid or [btcPrice] is missing/non-positive.
  /// Pure - factored out so it's directly unit-testable without a [FiatConversionStore].
  static Money? fiatTextToSats(String text, double? btcPrice) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (btcPrice == null || !btcPrice.isFinite || btcPrice <= 0) {
      return null;
    }
    final fiatValue = double.tryParse(trimmed.replaceAll(",", "."));
    if (fiatValue == null || !fiatValue.isFinite) {
      return null;
    }
    final btcValue = fiatValue / btcPrice;
    if (!btcValue.isFinite) {
      return null;
    }
    return Money.tryParse(btcValue.toStringAsFixed(8), CryptoCurrency.btcln);
  }

  /// Inverse of [fiatTextToSats]: [sats] base units -> fiat display text (2 decimals), "" if
  /// [btcPrice] is missing/non-positive or the result isn't finite. Pure - factored out so it's
  /// directly unit-testable.
  static String satsToFiatText(BigInt sats, double? btcPrice) {
    if (btcPrice == null || !btcPrice.isFinite || btcPrice <= 0) {
      return "";
    }
    final btc = sats.toDouble() / 100000000;
    final fiat = btc * btcPrice;
    if (!fiat.isFinite) {
      return "";
    }
    return fiat.toStringAsFixed(2);
  }

  /// Estimates how much [inputAmount] (in whichever asset is being spent) should buy of the other
  /// asset, using the most recent SDK quote's rate ([lastIn]/[lastOut]) for the active direction.
  /// Falls back to [fallback] (the SDK's own reported minimum, when it has one, else a small
  /// constant) the very first time this flow quotes in a given direction - that first real quote
  /// then seeds the cached rate for every subsequent estimate. Rounded down: an overestimate could
  /// ask the SDK for more of the input asset than the user typed (or has available).
  BigInt _estimateFromRate(BigInt inputAmount, BigInt? lastIn, BigInt? lastOut, BigInt fallback) {
    if (lastIn != null && lastOut != null && lastIn > BigInt.zero) {
      final estimate = (inputAmount * lastOut) ~/ lastIn;
      if (estimate > BigInt.zero) {
        return estimate;
      }
    }
    return fallback;
  }

  void _cacheForwardRate(SparkConversionQuote quote) {
    if (quote.amountIn.amount > BigInt.zero && quote.amountOut.amount > BigInt.zero) {
      _lastAmountInFwd = quote.amountIn.amount;
      _lastAmountOutFwd = quote.amountOut.amount;
    }
  }

  void _cacheReverseRate(SparkConversionQuote quote) {
    if (quote.amountIn.amount > BigInt.zero && quote.amountOut.amount > BigInt.zero) {
      _lastAmountInRev = quote.amountIn.amount;
      _lastAmountOutRev = quote.amountOut.amount;
    }
  }

  /// True when [amount] is below [minimum] (when the SDK reports one at all). Pure/no SDK
  /// call - factored out so it's directly unit-testable.
  static bool isBelowMinimum(Money amount, Money? minimum) => minimum != null && amount < minimum;

  Future<void> _onInit(_Init event, Emitter<SparkDepositToStableState> emit) async {
    // Never null-guarded away for its own sake: a wallet reaching this Bloc without a stablecoin
    // Spark token, or without Lightning support to fetch its conversion limits, is a real
    // configuration error - this flow is only ever opened from a stablecoin asset card (see
    // `asset_details_modal.dart`), so this should be unreachable in practice, and the error state
    // says so rather than hiding it.
    final token = (bitcoin?.getSparkTokenCurrencies(_wallet) ?? const <CryptoCurrency>[])
        .firstWhereOrNull((currency) => currency.groups.contains(CurrencyGroups.stablecoin));
    if (token == null) {
      emit(SparkDepositToStableUnavailable(S.current.deposit_to_stable_unavailable_error));
      return;
    }

    try {
      final limits = await bitcoin?.fetchStableConversionLimits(_wallet, token);
      final reverseLimits = await bitcoin?.fetchReverseStableConversionLimits(_wallet, token);
      if (limits == null || reverseLimits == null) {
        emit(SparkDepositToStableUnavailable(S.current.deposit_to_stable_unavailable_error));
        return;
      }
      emit(
        SparkDepositToStableReady(
          token: token,
          limits: limits,
          reverseLimits: reverseLimits,
          amountText: "",
          maxSlippageBps: defaultMaxSlippageBps,
          isFiatEntry: false,
          direction: ConversionDirection.fromBitcoin,
        ),
      );
    } catch (e) {
      emit(SparkDepositToStableUnavailable(bitcoin?.getBreezSdkError(e) ?? e.toString()));
    }
  }

  Future<void> _onAmountChanged(
    AmountChanged event,
    Emitter<SparkDepositToStableState> emit,
  ) async {
    final current = state;
    if (current is! SparkDepositToStableLoaded) {
      return;
    }
    await _requote(
      current,
      emit,
      amountText: event.amountText,
      maxSlippageBps: current.maxSlippageBps,
      isFiatEntry: current.isFiatEntry,
      direction: current.direction,
    );
  }

  Future<void> _onMaxSlippageChanged(
    MaxSlippageChanged event,
    Emitter<SparkDepositToStableState> emit,
  ) async {
    final current = state;
    if (current is! SparkDepositToStableLoaded) {
      return;
    }
    await _requote(
      current,
      emit,
      amountText: current.amountText,
      maxSlippageBps: event.bps,
      isFiatEntry: current.isFiatEntry,
      direction: current.direction,
    );
  }

  Future<void> _onFiatEntryToggled(
    FiatEntryToggled event,
    Emitter<SparkDepositToStableState> emit,
  ) async {
    final current = state;
    // Only meaningful when converting FROM Bitcoin - the toBitcoin amount field is always
    // token-denominated (see SparkDepositToStableLoaded.isFiatEntry's doc comment).
    if (current is! SparkDepositToStableLoaded ||
        isFiatDisabled ||
        current.direction != ConversionDirection.fromBitcoin) {
      return;
    }
    final newIsFiatEntry = !current.isFiatEntry;
    final convertedText = convertedAmountText(current.amountText, isFiatEntry: current.isFiatEntry);
    await _requote(
      current,
      emit,
      amountText: convertedText,
      maxSlippageBps: current.maxSlippageBps,
      isFiatEntry: newIsFiatEntry,
      direction: current.direction,
    );
  }

  Future<void> _onDirectionChanged(
    DirectionChanged event,
    Emitter<SparkDepositToStableState> emit,
  ) async {
    final current = state;
    if (current is! SparkDepositToStableLoaded || current.direction == event.direction) {
      return;
    }
    // The same typed number means a different real amount once the asset being spent changes,
    // and there's no rate to convert it with until a quote comes back in the new direction - so
    // the field resets rather than showing a stale, now-meaningless number.
    await _requote(
      current,
      emit,
      amountText: "",
      maxSlippageBps: current.maxSlippageBps,
      isFiatEntry: false,
      direction: event.direction,
    );
  }

  /// Re-validates [amountText] and, if it's a valid amount at or above the minimum, fetches a
  /// fresh quote. There's no standalone "get a quote" SDK call - fetching one doubles as
  /// `prepareBitcoinToStableConversion`/`prepareTokenToBitcoinConversion`, the same call
  /// [ConversionRequested] later commits.
  ///
  /// Wrapped in a try/catch of its own (on top of the inner one around the SDK call): a bug in
  /// the validation logic above the SDK call (e.g. a currency-mismatch [ArgumentError]) would
  /// otherwise throw straight out of this `Bloc.on` handler before any `emit` runs, silently
  /// freezing the UI on whatever state came before - exactly what made an earlier bug this shape
  /// hard to see without device logs. Now any such bug surfaces as a visible error message
  /// instead.
  Future<void> _requote(
    SparkDepositToStableLoaded current,
    Emitter<SparkDepositToStableState> emit, {
    required String amountText,
    required int maxSlippageBps,
    required bool isFiatEntry,
    required ConversionDirection direction,
  }) async {
    try {
      if (direction == ConversionDirection.fromBitcoin) {
        await _requoteFromBitcoinOrThrow(
          current,
          emit,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: isFiatEntry,
        );
      } else {
        await _requoteToBitcoinOrThrow(
          current,
          emit,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
        );
      }
    } catch (e) {
      printV("SparkDepositToStable: _requote failed before completing: $e");
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: isFiatEntry,
          direction: direction,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _requoteFromBitcoinOrThrow(
    SparkDepositToStableLoaded current,
    Emitter<SparkDepositToStableState> emit, {
    required String amountText,
    required int maxSlippageBps,
    required bool isFiatEntry,
  }) async {
    const direction = ConversionDirection.fromBitcoin;
    final satsAmount = parseSatsOrFiatAmount(amountText, isFiatEntry: isFiatEntry);
    if (satsAmount == null) {
      _requestSeq++; // invalidates any still-in-flight fetch below - its result is now stale
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: isFiatEntry,
          direction: direction,
          error:
              amountText.trim().isEmpty ? null : S.current.deposit_to_stable_invalid_amount_error,
        ),
      );
      return;
    }

    if (isBelowMinimum(satsAmount, current.limits.minAmountIn)) {
      _requestSeq++;
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: isFiatEntry,
          direction: direction,
          error: S.current.deposit_to_stable_min_amount_error(
            current.limits.minAmountIn!.toStringWithSymbol(useBaseUnit: true),
          ),
        ),
      );
      return;
    }

    final requestId = ++_requestSeq;
    emit(
      SparkDepositToStableReady(
        token: current.token,
        limits: current.limits,
        reverseLimits: current.reverseLimits,
        amountText: amountText,
        maxSlippageBps: maxSlippageBps,
        isFiatEntry: isFiatEntry,
        direction: direction,
        isQuoting: true,
      ),
    );

    printV(
        "SparkDepositToStable: fetching quote #$requestId for ${satsAmount.toStringWithSymbol()} "
        "-> ${current.token.title} @ ${slippageLabel(maxSlippageBps)} slippage");
    try {
      final fallback = current.limits.minAmountOut?.amount ??
          (Money.tryParse("10", current.token)?.amount ?? BigInt.from(10));
      final tokenAmountGuess =
          _estimateFromRate(satsAmount.amount, _lastAmountInFwd, _lastAmountOutFwd, fallback);
      var quote = await bitcoin?.prepareBitcoinToStableConversion(
        _wallet,
        tokenAmount: tokenAmountGuess,
        token: current.token,
        maxSlippageBps: maxSlippageBps,
      );
      if (requestId != _requestSeq) {
        printV("SparkDepositToStable: quote #$requestId superseded, dropping result");
        return;
      }
      if (quote == null) {
        printV("SparkDepositToStable: quote #$requestId - bitcoin facade returned null");
        emit(
          SparkDepositToStableReady(
            token: current.token,
            limits: current.limits,
            reverseLimits: current.reverseLimits,
            amountText: amountText,
            maxSlippageBps: maxSlippageBps,
            isFiatEntry: isFiatEntry,
            direction: direction,
            error: S.current.deposit_to_stable_unavailable_error,
          ),
        );
        return;
      }
      _cacheForwardRate(quote);

      // The initial guess is rarely exact - refine once so the real sats cost lands close to
      // what the user typed. Capped at one extra SDK round trip; any remaining drift is shown
      // to the user via quote.amountIn rather than chased further.
      if (quote.amountIn.amount != satsAmount.amount && quote.amountIn.amount > BigInt.zero) {
        final refinedTokenAmount = (tokenAmountGuess * satsAmount.amount) ~/ quote.amountIn.amount;
        if (refinedTokenAmount > BigInt.zero && refinedTokenAmount != tokenAmountGuess) {
          final refinedQuote = await bitcoin?.prepareBitcoinToStableConversion(
            _wallet,
            tokenAmount: refinedTokenAmount,
            token: current.token,
            maxSlippageBps: maxSlippageBps,
          );
          if (requestId != _requestSeq) {
            printV(
              "SparkDepositToStable: quote #$requestId superseded during refinement, dropping",
            );
            return;
          }
          if (refinedQuote != null) {
            quote = refinedQuote;
            _cacheForwardRate(quote);
          }
        }
      }

      if (isBelowMinimum(quote.amountOut, current.limits.minAmountOut)) {
        emit(
          SparkDepositToStableReady(
            token: current.token,
            limits: current.limits,
            reverseLimits: current.reverseLimits,
            amountText: amountText,
            maxSlippageBps: maxSlippageBps,
            isFiatEntry: isFiatEntry,
            direction: direction,
            error: S.current.deposit_to_stable_min_amount_error(
              current.limits.minAmountOut!.toStringWithSymbol(),
            ),
          ),
        );
        return;
      }

      printV("SparkDepositToStable: quote #$requestId resolved - "
          "${quote.amountIn.toStringWithSymbol()} -> ${quote.amountOut.toStringWithSymbol()}");
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: isFiatEntry,
          direction: direction,
          quote: quote,
        ),
      );
    } catch (e) {
      printV("SparkDepositToStable: quote #$requestId failed: $e");
      if (requestId != _requestSeq) {
        return;
      }
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: isFiatEntry,
          direction: direction,
          error: bitcoin?.getBreezSdkError(e) ?? e.toString(),
        ),
      );
    }
  }

  /// The reverse of [_requoteFromBitcoinOrThrow]: [amountText] is always token-denominated (no
  /// fiat toggle in this direction). [current.reverseLimits.minAmountOut] (token, fixed meaning)
  /// validates it - NOT `minAmountIn`, which stays fixed to BTC regardless of direction (see
  /// [SparkDepositToStableLoaded.reverseLimits]'s doc comment).
  Future<void> _requoteToBitcoinOrThrow(
    SparkDepositToStableLoaded current,
    Emitter<SparkDepositToStableState> emit, {
    required String amountText,
    required int maxSlippageBps,
  }) async {
    const direction = ConversionDirection.toBitcoin;
    final trimmed = amountText.trim();
    final tokenAmount = trimmed.isEmpty ? null : Money.tryParse(trimmed, current.token);
    if (tokenAmount == null) {
      _requestSeq++;
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: false,
          direction: direction,
          error: trimmed.isEmpty ? null : S.current.deposit_to_stable_invalid_amount_error,
        ),
      );
      return;
    }

    if (isBelowMinimum(tokenAmount, current.reverseLimits.minAmountOut)) {
      _requestSeq++;
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: false,
          direction: direction,
          error: S.current.deposit_to_stable_min_amount_error(
            current.reverseLimits.minAmountOut!.toStringWithSymbol(),
          ),
        ),
      );
      return;
    }

    final requestId = ++_requestSeq;
    emit(
      SparkDepositToStableReady(
        token: current.token,
        limits: current.limits,
        reverseLimits: current.reverseLimits,
        amountText: amountText,
        maxSlippageBps: maxSlippageBps,
        isFiatEntry: false,
        direction: direction,
        isQuoting: true,
      ),
    );

    printV("SparkDepositToStable: fetching reverse quote #$requestId for "
        "${tokenAmount.toStringWithSymbol()} -> sats @ ${slippageLabel(maxSlippageBps)} slippage");
    try {
      final fallback = current.reverseLimits.minAmountIn?.amount ?? BigInt.from(1000);
      final satsAmountGuess =
          _estimateFromRate(tokenAmount.amount, _lastAmountInRev, _lastAmountOutRev, fallback);
      var quote = await bitcoin?.prepareTokenToBitcoinConversion(
        _wallet,
        satsAmount: satsAmountGuess,
        token: current.token,
        maxSlippageBps: maxSlippageBps,
      );
      if (requestId != _requestSeq) {
        printV("SparkDepositToStable: reverse quote #$requestId superseded, dropping result");
        return;
      }
      if (quote == null) {
        printV("SparkDepositToStable: reverse quote #$requestId - bitcoin facade returned null");
        emit(
          SparkDepositToStableReady(
            token: current.token,
            limits: current.limits,
            reverseLimits: current.reverseLimits,
            amountText: amountText,
            maxSlippageBps: maxSlippageBps,
            isFiatEntry: false,
            direction: direction,
            error: S.current.deposit_to_stable_unavailable_error,
          ),
        );
        return;
      }
      _cacheReverseRate(quote);

      // Same one-shot refinement as the forward direction: the initial sats guess is rarely
      // exact, so re-quote once so the real token cost lands close to what the user typed.
      if (quote.amountIn.amount != tokenAmount.amount && quote.amountIn.amount > BigInt.zero) {
        final refinedSatsAmount = (satsAmountGuess * tokenAmount.amount) ~/ quote.amountIn.amount;
        if (refinedSatsAmount > BigInt.zero && refinedSatsAmount != satsAmountGuess) {
          final refinedQuote = await bitcoin?.prepareTokenToBitcoinConversion(
            _wallet,
            satsAmount: refinedSatsAmount,
            token: current.token,
            maxSlippageBps: maxSlippageBps,
          );
          if (requestId != _requestSeq) {
            printV("SparkDepositToStable: reverse quote #$requestId superseded during refinement, "
                "dropping");
            return;
          }
          if (refinedQuote != null) {
            quote = refinedQuote;
            _cacheReverseRate(quote);
          }
        }
      }

      if (isBelowMinimum(quote.amountOut, current.reverseLimits.minAmountIn)) {
        emit(
          SparkDepositToStableReady(
            token: current.token,
            limits: current.limits,
            reverseLimits: current.reverseLimits,
            amountText: amountText,
            maxSlippageBps: maxSlippageBps,
            isFiatEntry: false,
            direction: direction,
            error: S.current.deposit_to_stable_min_amount_error(
              current.reverseLimits.minAmountIn!.toStringWithSymbol(useBaseUnit: true),
            ),
          ),
        );
        return;
      }

      printV("SparkDepositToStable: reverse quote #$requestId resolved - "
          "${quote.amountIn.toStringWithSymbol()} -> ${quote.amountOut.toStringWithSymbol()}");
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: false,
          direction: direction,
          quote: quote,
        ),
      );
    } catch (e) {
      printV("SparkDepositToStable: reverse quote #$requestId failed: $e");
      if (requestId != _requestSeq) {
        return;
      }
      emit(
        SparkDepositToStableReady(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: amountText,
          maxSlippageBps: maxSlippageBps,
          isFiatEntry: false,
          direction: direction,
          error: bitcoin?.getBreezSdkError(e) ?? e.toString(),
        ),
      );
    }
  }

  Future<void> _onConversionRequested(
    ConversionRequested event,
    Emitter<SparkDepositToStableState> emit,
  ) async {
    final current = state;
    final quote = current is SparkDepositToStableReady ? current.quote : null;
    if (current is! SparkDepositToStableReady || quote == null) {
      return;
    }

    emit(
      SparkDepositToStableSubmitting(
        token: current.token,
        limits: current.limits,
        reverseLimits: current.reverseLimits,
        amountText: current.amountText,
        maxSlippageBps: current.maxSlippageBps,
        isFiatEntry: current.isFiatEntry,
        direction: current.direction,
        quote: quote,
      ),
    );

    try {
      final paymentId = await quote.commit();
      printV(
        "SparkDepositToStable: conversion committed, paymentId=$paymentId - refreshing balance",
      );

      // Shown in history immediately - the real transaction record can take a few seconds to sync
      // in, and without this the conversion would look like it never happened until then. Removed
      // automatically by `PendingConversionStore.reconcile` once that real record shows up (see
      // `PendingConversion`'s own doc comment for why it's matched by id/hash, not by balance).
      final toIsToken = current.direction == ConversionDirection.fromBitcoin;
      await _pendingConversionStore.add(
        PendingConversion(
          paymentId: paymentId,
          walletId: _wallet.id,
          fromTicker: toIsToken ? "BTC" : current.token.title,
          toTicker: toIsToken ? current.token.title : "BTC",
          toIsToken: toIsToken,
          amountOutBaseUnits: quote.amountOut.toStringWithPrecision(useBaseUnit: true),
          amountOutDecimals: quote.amountOut.currency.decimals,
          createdAt: DateTime.now(),
        ),
      );

      // Necessary even when the commit genuinely succeeded: nothing else in this Bloc's flow
      // triggers a balance/history refresh, so without this the dashboard would keep showing
      // pre-conversion balances/history until some unrelated action happened to refresh them.
      await _wallet.updateBalance();
      await _wallet.fetchTransactions();
      emit(
        SparkDepositToStableSucceeded(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: current.amountText,
          maxSlippageBps: current.maxSlippageBps,
          isFiatEntry: current.isFiatEntry,
          direction: current.direction,
          quote: quote,
          paymentId: paymentId,
        ),
      );
    } catch (e) {
      emit(
        SparkDepositToStableFailed(
          token: current.token,
          limits: current.limits,
          reverseLimits: current.reverseLimits,
          amountText: current.amountText,
          maxSlippageBps: current.maxSlippageBps,
          isFiatEntry: current.isFiatEntry,
          direction: current.direction,
          quote: quote,
          error: bitcoin?.getBreezSdkError(e) ?? e.toString(),
        ),
      );
    }
  }
}
