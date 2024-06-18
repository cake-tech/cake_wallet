import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'buy_sell_view_model.g.dart';

class BuySellViewModel = BuySellViewModelBase with _$BuySellViewModel;

abstract class BuySellViewModelBase extends WalletChangeListenerViewModel with Store {
  @override
  void onWalletChange(wallet) {
    cryptoCurrency = wallet.currency;
  }

  BuySellViewModelBase(
    AppStore appStore,
    this.trades,
    this._exchangeTemplateStore,
    this.tradesStore,
    this._settingsStore,
    this.sharedPreferences,
    this.contactListViewModel,
  )   : _cryptoNumberFormat = NumberFormat(),
        isSendAllEnabled = false,
        isReceiveAmountEntered = false,
        cryptoAmount = '',
        fiatAmount = '',
        receiveAddress = '',
        depositAddress = '',
        isDepositAddressEnabled = false,
        isReceiveAmountEditable = false,
        _useTorOnly = false,
        cryptoCurrencies = <CryptoCurrency>[],
        fiatCurrencies = <FiatCurrency>[],
        limits = Limits(min: 0, max: 0),
        tradeState = ExchangeTradeStateInitial(),
        limitsState = LimitsInitialState(),
        cryptoCurrency = appStore.wallet!.currency,
        fiatCurrency = _settingsStore.fiatCurrency,
        providerList = [],
        selectedProviders = ObservableList<ExchangeProvider>(),
        super(appStore: appStore) {
    _useTorOnly = _settingsStore.exchangeStatus == ExchangeApiMode.torOnly;
    const excludeFiatCurrencies = [];
    const excludeCryptoCurrencies = [
      CryptoCurrency.xlm,
      CryptoCurrency.xrp,
      CryptoCurrency.bnb,
      CryptoCurrency.btt
    ];

    final Map<String, dynamic> exchangeProvidersSelection =
        json.decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}")
            as Map<String, dynamic>;

    /// if the provider is not in the user settings (user's first time or newly added provider)
    /// then use its default value decided by us
    selectedProviders = ObservableList.of(providerList
        .where((element) => exchangeProvidersSelection[element.title] == null
            ? element.isEnabled
            : (exchangeProvidersSelection[element.title] as bool))
        .toList());

    isDepositAddressEnabled = !(fiatCurrency == wallet.currency);
    cryptoAmount = '';
    fiatAmount = '';
    receiveAddress = '';
    depositAddress = fiatCurrency == wallet.currency ? wallet.walletAddresses.address : '';

    cryptoCurrencies = CryptoCurrency.all
        .where((cryptoCurrency) => !excludeCryptoCurrencies.contains(cryptoCurrency))
        .toList();
    fiatCurrencies = FiatCurrency.all
        .where((fiatCurrency) => !excludeFiatCurrencies.contains(fiatCurrency))
        .toList();
  }

  List<CryptoCurrency> cryptoCurrencies;

  List<FiatCurrency> fiatCurrencies;

  final NumberFormat _cryptoNumberFormat;

  final SettingsStore _settingsStore;

  final ContactListViewModel contactListViewModel;


  late Timer bestRateSync;

  bool _useTorOnly;
  final Box<Trade> trades;
  final ExchangeTemplateStore _exchangeTemplateStore;
  final TradesStore tradesStore;
  final SharedPreferences sharedPreferences;

  @observable
  ObservableList<ExchangeProvider> selectedProviders;

  @observable
  List<ExchangeProvider> providerList;

  @observable
  FiatCurrency fiatCurrency;

  @observable
  CryptoCurrency cryptoCurrency;

  @observable
  LimitsState limitsState;

  @observable
  ExchangeTradeState tradeState;

  @observable
  String cryptoAmount;

  @observable
  String fiatAmount;

  @observable
  String depositAddress;

  @observable
  String receiveAddress;

  @observable
  bool isDepositAddressEnabled;

  @observable
  bool isReceiveAmountEntered;

  @observable
  bool isReceiveAmountEditable;


  @observable
  bool isSendAllEnabled;

  @observable
  Limits limits;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  ObservableList<ExchangeTemplate> get templates => _exchangeTemplateStore.templates;

  @action
  void changeCryptoCurrency({required CryptoCurrency currency}) {
    cryptoCurrency = currency;
    //_onPairChange();
  }

  @action
  void changeFiatCurrency({required FiatCurrency currency}) {
    fiatCurrency = currency;
    //_onPairChange();
  }

  void _onPairChange() {
    cryptoAmount = '';
    fiatAmount = '';

  }
}
