import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';

part 'balance_view_model.g.dart';

class BalanceRecord {
  const BalanceRecord({this.availableBalance,
    this.additionalBalance,
    this.fiatAvailableBalance,
    this.fiatAdditionalBalance,
    this.asset});
  final String fiatAdditionalBalance;
  final String fiatAvailableBalance;
  final String additionalBalance;
  final String availableBalance;
  final CryptoCurrency asset;
}

class BalanceViewModel = BalanceViewModelBase with _$BalanceViewModel;

abstract class BalanceViewModelBase with Store {
  BalanceViewModelBase(
      {@required this.appStore,
      @required this.settingsStore,
      @required this.fiatConvertationStore}) {
    isReversing = false;
    wallet ??= appStore.wallet;
    reaction((_) => appStore.wallet, _onWalletChange);
  }

  final AppStore appStore;
  final SettingsStore settingsStore;
  final FiatConversionStore fiatConvertationStore;

  bool get canReverse => false;

  @observable
  bool isReversing;

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>
      wallet;

  @computed
  double get price => fiatConvertationStore.prices[appStore.wallet.currency];

  @computed
  BalanceDisplayMode get savedDisplayMode => settingsStore.balanceDisplayMode;

    @computed
  String get asset {
    
    switch(appStore.wallet.currency){
      case CryptoCurrency.btc:
        return 'Bitcoin Assets';
      case CryptoCurrency.xmr:
        return 'Monero Assets';
      case CryptoCurrency.ltc:
        return 'Litecoin Assets';
      default:
        return '';
    }
    
  }

  @computed
  BalanceDisplayMode get displayMode => isReversing
      ? savedDisplayMode == BalanceDisplayMode.hiddenBalance
          ? BalanceDisplayMode.displayableBalance
          : savedDisplayMode
      : savedDisplayMode;

  @computed
  String get availableBalanceLabel {
    if (wallet.type == WalletType.monero) {
      return S.current.xmr_available_balance;
    }

    return S.current.confirmed;
  }

  @computed
  String get additionalBalanceLabel {
    if (wallet.type == WalletType.monero) {
      return S.current.xmr_full_balance;
    }

    return S.current.unconfirmed;
  }

  @computed
  bool get hasMultiBalance => appStore.wallet.type == WalletType.haven;

  @computed
  String get availableBalance {
    final walletBalance = _walletBalance;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return walletBalance.formattedAvailableBalance;
  }

  @computed
  String get additionalBalance {
    final walletBalance = _walletBalance;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return walletBalance.formattedAdditionalBalance;
  }

  @computed
  String get availableFiatBalance {
    final walletBalance = _walletBalance;
    final fiatCurrency = settingsStore.fiatCurrency;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return  _getFiatBalance(
            price: price,
            cryptoAmount: walletBalance.formattedAvailableBalance) + ' ' + fiatCurrency.toString();
       
  }

  @computed
  String get additionalFiatBalance {
    final walletBalance = _walletBalance;
    final fiatCurrency = settingsStore.fiatCurrency;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return   _getFiatBalance(
            price: price,
            cryptoAmount: walletBalance.formattedAdditionalBalance) + ' ' + fiatCurrency.toString();
       
  }

  @computed
  Map<CryptoCurrency, BalanceRecord> get balances {
    return wallet.balance.map((key, value) {
      if (displayMode == BalanceDisplayMode.hiddenBalance) {
        return MapEntry(key, BalanceRecord(
          availableBalance: '---',
          additionalBalance: '---',
          fiatAdditionalBalance: '---',
          fiatAvailableBalance: '---',
          asset: key));
      }
      final fiatCurrency = settingsStore.fiatCurrency;
      final additionalFiatBalance = fiatCurrency.toString()
        + ' ' 
        + _getFiatBalance(
            price: fiatConvertationStore.prices[key],
            cryptoAmount: value.formattedAdditionalBalance);

      final availableFiatBalance = fiatCurrency.toString()
        + ' ' 
        + _getFiatBalance(
            price: fiatConvertationStore.prices[key],
            cryptoAmount: value.formattedAvailableBalance);

      return MapEntry(key, BalanceRecord(
        availableBalance: value.formattedAvailableBalance,
        additionalBalance: value.formattedAdditionalBalance,
        fiatAdditionalBalance: additionalFiatBalance,
        fiatAvailableBalance: availableFiatBalance,
        asset: key));
      });
  }

  @computed
  List<BalanceRecord> get formattedBalances {
    final balance = balances.values.toList();

    balance.sort((BalanceRecord a, BalanceRecord b) {
      if (b.asset == CryptoCurrency.xhv) {
        return 1;
      }

      if (b.asset == CryptoCurrency.xusd) {
        if (a.asset == CryptoCurrency.xhv) {
          return -1;
        }

        return 1;
      }

      if (b.asset == CryptoCurrency.xbtc) {
        return 1;
      }

      if (b.asset == CryptoCurrency.xeur) {
        return 1;
      }

      return 0;
    });

    return balance;
  }

  @computed
  Balance get _walletBalance => wallet.balance[wallet.currency];

  @computed
  CryptoCurrency get currency => appStore.wallet.currency;

  ReactionDisposer _onCurrentWalletChangeReaction;

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet) {
     this.wallet = wallet;
    _onCurrentWalletChangeReaction?.reaction?.dispose();
  }

  String _getFiatBalance({double price, String cryptoAmount}) {
    if (cryptoAmount == null) {
      return '0.00';
    }

    return calculateFiatAmount(price: price, cryptoAmount: cryptoAmount);
  }
}

