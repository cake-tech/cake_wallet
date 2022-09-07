import 'dart:collection';
import 'dart:convert';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/exchange/sideshift/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/sideshift/sideshift_request.dart';
import 'package:cake_wallet/exchange/simpleswap/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/simpleswap/simpleswap_request.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/changenow/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/changenow/changenow_request.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_trade_request.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_request.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'exchange_view_model.g.dart';

class ExchangeViewModel = ExchangeViewModelBase with _$ExchangeViewModel;

abstract class ExchangeViewModelBase with Store {
  ExchangeViewModelBase(this.wallet, this.trades, this._exchangeTemplateStore,
      this.tradesStore, this._settingsStore, this.sharedPreferences) {
    const excludeDepositCurrencies = [CryptoCurrency.btt, CryptoCurrency.nano];
    const excludeReceiveCurrencies = [CryptoCurrency.xlm, CryptoCurrency.xrp,
      CryptoCurrency.bnb, CryptoCurrency.btt, CryptoCurrency.nano];
    providerList = [ChangeNowExchangeProvider(), SideShiftExchangeProvider(), SimpleSwapExchangeProvider()];
    _initialPairBasedOnWallet();
    currentTradeAvailableProviders = SplayTreeMap<double, ExchangeProvider>();

    final Map<String, dynamic> exchangeProvidersSelection = json
        .decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}") as Map<String, dynamic>;

    /// if the provider is not in the user settings (user's first time or newly added provider)
    /// then use its default value decided by us
    selectedProviders = ObservableList.of(providersForCurrentPair().where(
            (element) => exchangeProvidersSelection[element.title] == null
            ? element.isEnabled
            : (exchangeProvidersSelection[element.title] as bool))
        .toList());

    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
    depositAmount = '';
    receiveAmount = '';
    receiveAddress = '';
    depositAddress = depositCurrency == wallet.currency
        ? wallet.walletAddresses.address : '';
    limitsState = LimitsInitialState();
    tradeState = ExchangeTradeStateInitial();
    _cryptoNumberFormat = NumberFormat()..maximumFractionDigits = wallet.type == WalletType.bitcoin ? 8 : 12;
    provider = providersForCurrentPair().first;
    final initialProvider = provider;
    provider.checkIsAvailable().then((bool isAvailable) {
      if (!isAvailable && provider == initialProvider) {
        provider = providerList.firstWhere(
            (provider) => provider is ChangeNowExchangeProvider,
            orElse: () => providerList.last);
        _onPairChange();
      }
    });
    receiveCurrencies = CryptoCurrency.all
      .where((cryptoCurrency) => !excludeReceiveCurrencies.contains(cryptoCurrency))
      .toList();
    depositCurrencies = CryptoCurrency.all
      .where((cryptoCurrency) => !excludeDepositCurrencies.contains(cryptoCurrency))
      .toList();
    isReverse = false;
    isFixedRateMode = false;
    isReceiveAmountEntered = false;
    _defineIsReceiveAmountEditable();
    loadLimits();
    reaction(
      (_) => isFixedRateMode,
      (Object _) => loadLimits());
  }

  final WalletBase wallet;
  final Box<Trade> trades;
  final ExchangeTemplateStore _exchangeTemplateStore;
  final TradesStore tradesStore;
  final SharedPreferences sharedPreferences;

  @observable
  ExchangeProvider provider;

  /// Maps in dart are not sorted by default
  /// SplayTreeMap is a map sorted by keys
  /// will use it to sort available providers
  /// depending on the amount they yield for the current trade
  SplayTreeMap<double, ExchangeProvider> currentTradeAvailableProviders;

  @observable
  ObservableList<ExchangeProvider> selectedProviders;

  @observable
  List<ExchangeProvider> providerList;

  @observable
  CryptoCurrency depositCurrency;

  @observable
  CryptoCurrency receiveCurrency;

  @observable
  LimitsState limitsState;

  @observable
  ExchangeTradeState tradeState;

  @observable
  String depositAmount;

  @observable
  String receiveAmount;

  @observable
  String depositAddress;

  @observable
  String receiveAddress;

  @observable
  bool isDepositAddressEnabled;

  @observable
  bool isReceiveAddressEnabled;

  @observable
  bool isReceiveAmountEntered;

  @observable
  bool isReceiveAmountEditable;

  @observable
  bool isFixedRateMode;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  ObservableList<ExchangeTemplate> get templates =>
      _exchangeTemplateStore.templates;

  bool get hasAllAmount =>
      wallet.type == WalletType.bitcoin && depositCurrency == wallet.currency;

  bool get isMoneroWallet  => wallet.type == WalletType.monero;

  List<CryptoCurrency> receiveCurrencies;

  List<CryptoCurrency> depositCurrencies;

  Limits limits;

  bool isReverse;

  NumberFormat _cryptoNumberFormat;

  final SettingsStore _settingsStore;

  @action
  void changeDepositCurrency({CryptoCurrency currency}) {
    depositCurrency = currency;
    isFixedRateMode = false;
    _onPairChange();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
  }

  @action
  void changeReceiveCurrency({CryptoCurrency currency}) {
    receiveCurrency = currency;
    isFixedRateMode = false;
    _onPairChange();
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
  }

  @action
  void changeReceiveAmount({String amount}) {
    receiveAmount = amount;
    isReverse = true;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _enteredAmount = double.parse(amount.replaceAll(',', '.')) ?? 0;

    currentTradeAvailableProviders.clear();
    for (var provider in selectedProviders) {
      /// if this provider is not valid for the current pair, skip it
      if (!providersForCurrentPair().contains(provider)) {
        continue;
      }
      provider
          .calculateAmount(
              from: receiveCurrency,
              to: depositCurrency,
              amount: _enteredAmount,
              isFixedRateMode: isFixedRateMode,
              isReceiveAmount: true)
          .then((amount) {

        final from = isFixedRateMode
            ? receiveCurrency
            : depositCurrency;
        final to = isFixedRateMode
            ? depositCurrency
            : receiveCurrency;

        provider.fetchLimits(
          from: from,
          to: to,
          isFixedRateMode: isFixedRateMode,
        ).then((limits) {
          /// if the entered amount doesn't exceed the limits of this provider
          if ((limits?.max ?? double.maxFinite) >= _enteredAmount
              && (limits?.min ?? 0) <= _enteredAmount) {
            /// add this provider as its valid for this trade
            /// will be sorted ascending already since
            /// we seek the least deposit amount
            currentTradeAvailableProviders[amount] = provider;
          }
          return amount;
        }).then((amount) => depositAmount = _cryptoNumberFormat
            .format(amount)
            .toString()
            .replaceAll(RegExp('\\,'), ''));
      });
    }
  }

  @action
  void changeDepositAmount({String amount}) {
    depositAmount = amount;
    isReverse = false;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      receiveAmount = '';
      return;
    }

    final _enteredAmount = double.tryParse(amount.replaceAll(',', '.')) ?? 0;

    currentTradeAvailableProviders.clear();
    for (var provider in selectedProviders) {
      /// if this provider is not valid for the current pair, skip it
      if (!providersForCurrentPair().contains(provider)) {
        continue;
      }
      provider
          .calculateAmount(
              from: depositCurrency,
              to: receiveCurrency,
              amount: _enteredAmount,
              isFixedRateMode: isFixedRateMode,
              isReceiveAmount: false)
          .then((amount) {

        final from = isFixedRateMode
            ? receiveCurrency
            : depositCurrency;
        final to = isFixedRateMode
            ? depositCurrency
            : receiveCurrency;

        provider.fetchLimits(
          from: from,
          to: to,
          isFixedRateMode: isFixedRateMode,
        ).then((limits) {

          /// if the entered amount doesn't exceed the limits of this provider
          if ((limits?.max ?? double.maxFinite) >= _enteredAmount
              && (limits?.min ?? 0) <= _enteredAmount) {
            /// add this provider as its valid for this trade
            /// subtract from maxFinite so the provider
            /// with the largest amount would be sorted ascending
            currentTradeAvailableProviders[double.maxFinite - amount] = provider;
          }
          return amount;
        }).then((amount) => receiveAmount =
            receiveAmount = _cryptoNumberFormat
            .format(amount)
            .toString()
            .replaceAll(RegExp('\\,'), ''));
      });
    }
  }

  @action
  Future loadLimits() async {
    if (selectedProviders.isEmpty) {
      return;
    }

    limitsState = LimitsIsLoading();

    try {
      final from = isFixedRateMode
        ? receiveCurrency
        : depositCurrency;
      final to = isFixedRateMode
        ? depositCurrency
        : receiveCurrency;

      limits = await selectedProviders.first.fetchLimits(
          from: from,
          to: to,
          isFixedRateMode: isFixedRateMode);

      /// if the first provider limits is bounded then check with other providers
      /// for the highest maximum limit
      if (limits.max != null) {
        for (int i = 1;i < selectedProviders.length;i++) {
          final Limits tempLimits = await selectedProviders[i].fetchLimits(
              from: from,
              to: to,
              isFixedRateMode: isFixedRateMode);

          /// set the limits with the maximum provider limit
          /// if there is a provider with null max then it's the maximum limit
          if ((tempLimits.max ?? double.maxFinite) > limits.max) {
            limits = tempLimits;
          }
        }
      }

      limitsState = LimitsLoadedSuccessfully(limits: limits);
    } catch (e) {
      limitsState = LimitsLoadedFailure(error: e.toString());
    }
  }

  @action
  Future createTrade() async {
    TradeRequest request;
    String amount;

    for (var provider in currentTradeAvailableProviders.values) {
      if (!(await provider.checkIsAvailable())) {
        continue;
      }

      if (provider is SideShiftExchangeProvider) {
        request = SideShiftRequest(
          depositMethod: depositCurrency,
          settleMethod: receiveCurrency,
          depositAmount: depositAmount?.replaceAll(',', '.'),
          settleAddress: receiveAddress,
          refundAddress: depositAddress,
        );
        amount = depositAmount;
      }

      if (provider is SimpleSwapExchangeProvider) {
        request = SimpleSwapRequest(
          from: depositCurrency,
          to: receiveCurrency,
          amount: depositAmount?.replaceAll(',', '.'),
          address: receiveAddress,
          refundAddress: depositAddress,
        );
        amount = depositAmount;
      }

      if (provider is XMRTOExchangeProvider) {
        request = XMRTOTradeRequest(
            from: depositCurrency,
            to: receiveCurrency,
            amount: depositAmount?.replaceAll(',', '.'),
            receiveAmount: receiveAmount?.replaceAll(',', '.'),
            address: receiveAddress,
            refundAddress: depositAddress,
            isBTCRequest: isReceiveAmountEntered);
        amount = depositAmount;
      }

      if (provider is ChangeNowExchangeProvider) {
        request = ChangeNowRequest(
            from: depositCurrency,
            to: receiveCurrency,
            fromAmount: depositAmount?.replaceAll(',', '.'),
            toAmount: receiveAmount?.replaceAll(',', '.'),
            refundAddress: depositAddress,
            address: receiveAddress,
            isReverse: isReverse);
        amount = isReverse ? receiveAmount : depositAmount;
      }

      if (provider is MorphTokenExchangeProvider) {
        request = MorphTokenRequest(
            from: depositCurrency,
            to: receiveCurrency,
            amount: depositAmount?.replaceAll(',', '.'),
            refundAddress: depositAddress,
            address: receiveAddress);
        amount = depositAmount;
      }

      amount = amount.replaceAll(',', '.');

      if (limitsState is LimitsLoadedSuccessfully && amount != null) {
        if (double.parse(amount) < limits.min) {
          continue;
        } else if (limits.max != null && double.parse(amount) > limits.max) {
          continue;
        } else {
          try {
            tradeState = TradeIsCreating();
            final trade = await provider.createTrade(
                request: request, isFixedRateMode: isFixedRateMode);
            trade.walletId = wallet.id;
            tradesStore.setTrade(trade);
            await trades.add(trade);
            tradeState = TradeIsCreatedSuccessfully(trade: trade);
            /// return after the first successful trade
            return;
          } catch (e) {
            continue;
          }
        }
      }
    }

    /// if the code reached here then none of the providers succeeded
    tradeState = TradeIsCreatedFailure(
        title: S.current.trade_not_created,
        error: S.current.none_of_selected_providers_can_exchange);
  }

  @action
  void reset() {
    _initialPairBasedOnWallet();
    isReceiveAmountEntered = false;
    depositAmount = '';
    receiveAmount = '';
    depositAddress = depositCurrency == wallet.currency
        ? wallet.walletAddresses.address : '';
    receiveAddress = receiveCurrency == wallet.currency
        ? wallet.walletAddresses.address : '';
    isDepositAddressEnabled = !(depositCurrency == wallet.currency);
    isReceiveAddressEnabled = !(receiveCurrency == wallet.currency);
    isFixedRateMode = false;
    _onPairChange();
  }

  @action
  void calculateDepositAllAmount() {
    if (wallet.type == WalletType.bitcoin) {
      final availableBalance = wallet.balance[wallet.currency].available;
      final priority = _settingsStore.priority[wallet.type];
      final fee = wallet.calculateEstimatedFee(priority, null);

      if (availableBalance < fee || availableBalance == 0) {
        return;
      }

      final amount = availableBalance - fee;
      changeDepositAmount(amount: bitcoin.formatterBitcoinAmountToString(amount: amount));
    }
  }

  void updateTemplate() => _exchangeTemplateStore.update();

  void addTemplate(
          {String amount,
          String depositCurrency,
          String receiveCurrency,
          String provider,
          String depositAddress,
          String receiveAddress}) =>
      _exchangeTemplateStore.addTemplate(
          amount: amount,
          depositCurrency: depositCurrency,
          receiveCurrency: receiveCurrency,
          provider: provider,
          depositAddress: depositAddress,
          receiveAddress: receiveAddress);

  void removeTemplate({ExchangeTemplate template}) =>
      _exchangeTemplateStore.remove(template: template);

  List<ExchangeProvider> providersForCurrentPair() {
    return _providersForPair(from: depositCurrency, to: receiveCurrency);
  }

  List<ExchangeProvider> _providersForPair(
      {CryptoCurrency from, CryptoCurrency to}) {
    final providers = providerList
        .where((provider) => provider.pairList
            .where((pair) =>
                pair.from == (from ?? depositCurrency) && pair.to == (to ?? receiveCurrency))
            .isNotEmpty)
        .toList();

    return providers;
  }

  void _onPairChange() {
    depositAmount = '';
    receiveAmount = '';
  }

  void _initialPairBasedOnWallet() {
    switch (wallet.type) {
      case WalletType.monero:
        depositCurrency = CryptoCurrency.xmr;
        receiveCurrency = CryptoCurrency.btc;
        break;
      case WalletType.bitcoin:
        depositCurrency = CryptoCurrency.btc;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.litecoin:
        depositCurrency = CryptoCurrency.ltc;
        receiveCurrency = CryptoCurrency.xmr;
        break;
      case WalletType.haven:
        depositCurrency = CryptoCurrency.xhv;
        receiveCurrency = CryptoCurrency.btc;
        break;
      default:
        break;
    }
  }

  void _defineIsReceiveAmountEditable() {
    /*if ((provider is ChangeNowExchangeProvider)
        &&(depositCurrency == CryptoCurrency.xmr)
        &&(receiveCurrency == CryptoCurrency.btc)) {
      isReceiveAmountEditable = true;
    } else {
      isReceiveAmountEditable = false;
    }*/
    //isReceiveAmountEditable = false;
    // isReceiveAmountEditable = selectedProviders.any((provider) => provider is ChangeNowExchangeProvider);
    // isReceiveAmountEditable = provider is ChangeNowExchangeProvider ||  provider is SimpleSwapExchangeProvider;
    isReceiveAmountEditable = true;
  }

  @action
  void addExchangeProvider(ExchangeProvider provider) {
    selectedProviders.add(provider);
  }

  @action
  void removeExchangeProvider(ExchangeProvider provider) {
    selectedProviders.remove(provider);
  }

  @action
  void saveSelectedProviders() {
    depositAmount = '';
    receiveAmount = '';
    isFixedRateMode = false;
    _defineIsReceiveAmountEditable();
    loadLimits();

    final Map<String, dynamic> exchangeProvidersSelection = json
        .decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}") as Map<String, dynamic>;

    exchangeProvidersSelection.updateAll((key, dynamic value) => false);
    for (var provider in selectedProviders) {
      exchangeProvidersSelection[provider.title] = true;
    }

    sharedPreferences.setString(
      PreferencesKey.exchangeProvidersSelection,
      json.encode(exchangeProvidersSelection),
    );
  }

  bool get isAvailableInSelected {
    final providersForPair = providersForCurrentPair();
    return selectedProviders.any((element) => element.isAvailable && providersForPair.contains(element));
  }
}
