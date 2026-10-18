import "package:bloc/bloc.dart";
import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/src/screens/wallet_connect/utils/string_parsing.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:mobx/mobx.dart";

class MoneySettingsCubit extends Cubit<MoneySettingsState> {
  MoneySettingsCubit(SettingsStore _settingsStore)
      : super(
    MoneySettingsState(
      bitcoinAmountDisplayMode: _settingsStore.displayAmountsInSatoshi,
      displayMode: _settingsStore.balanceDisplayMode,
    ),
  ) {
    _bitcoinAmountDisplayModeDisposer = reaction(
          (_) => _settingsStore.displayAmountsInSatoshi,
          (displayMode) => emit(state.copyWith(bitcoinAmountDisplayMode: displayMode)),
    );
    _displayModeDisposer = reaction(
          (_) => _settingsStore.balanceDisplayMode,
          (displayMode) => emit(state.copyWith(displayMode: displayMode)),
    );
  }

  late final ReactionDisposer _bitcoinAmountDisplayModeDisposer;

  late final ReactionDisposer _displayModeDisposer;

  @override
  Future<void> close() {
    if (!_bitcoinAmountDisplayModeDisposer.reaction.isDisposed) {
      _bitcoinAmountDisplayModeDisposer.reaction.dispose();
    }
    if (!_displayModeDisposer.reaction.isDisposed) {
      _displayModeDisposer.reaction.dispose();
    }
    return super.close();
  }
}

class MoneySettingsState {
  const MoneySettingsState({required this.bitcoinAmountDisplayMode, required this.displayMode});

  final BitcoinAmountDisplayMode bitcoinAmountDisplayMode;
  final BalanceDisplayMode displayMode;

  bool useBaseUnit(Currency currency) =>
      ([CryptoCurrency.btc, CryptoCurrency.btcln].contains(currency) &&
          bitcoinAmountDisplayMode == BitcoinAmountDisplayMode.satoshi) ||
          (CryptoCurrency.btcln == currency &&
              bitcoinAmountDisplayMode == BitcoinAmountDisplayMode.satoshiForLightning);

  bool get isHidden => displayMode == BalanceDisplayMode.hiddenBalance;

  String getSymbol(Currency currency, {bool? overrideSettings}) {
    if (overrideSettings == null) {
      return useBaseUnit(currency) ? "sats" : currency.symbol.safeSubString(0, 8);
    }

    if (overrideSettings == true && [CryptoCurrency.btc, CryptoCurrency.btcln].contains(currency)) {
      return "sats";
    }
    return currency.symbol.safeSubString(0, 8);
  }


  MoneySettingsState copyWith({
    BitcoinAmountDisplayMode? bitcoinAmountDisplayMode,
    BalanceDisplayMode? displayMode,
  }) =>
      MoneySettingsState(
        bitcoinAmountDisplayMode: bitcoinAmountDisplayMode ?? this.bitcoinAmountDisplayMode,
        displayMode: displayMode ?? this.displayMode,
      );
}
