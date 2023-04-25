import 'package:cake_wallet/entities/fiat_api_mode.dart';
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
import 'package:mobx/mobx.dart';

part 'balance_view_model.g.dart';

class BalanceRecord {
  const BalanceRecord({
    required this.availableBalance,
    required this.additionalBalance,
    required this.frozenBalance,
    required this.fiatAvailableBalance,
    required this.fiatAdditionalBalance,
    required this.fiatFrozenBalance,
    required this.asset,
    required this.formattedAssetTitle});
  final String fiatAdditionalBalance;
  final String fiatAvailableBalance;
  final String fiatFrozenBalance;
  final String additionalBalance;
  final String availableBalance;
  final String frozenBalance;
  final CryptoCurrency asset;
  final String formattedAssetTitle;
}

class BalanceViewModel = BalanceViewModelBase with _$BalanceViewModel;

abstract class BalanceViewModelBase with Store {
  BalanceViewModelBase(
      {required this.appStore,
      required this.settingsStore,
      required this.fiatConvertationStore})
    : isReversing = false,
      isShowCard = appStore.wallet!.walletInfo.isShowIntroCakePayCard,
      wallet = appStore.wallet! {
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
  double get price {
    final price = fiatConvertationStore.prices[appStore.wallet!.currency];

    if (price == null) {
      throw Exception('No price for ${appStore.wallet!.currency} (current wallet)');
    }

    return price;
  }

  @computed
  BalanceDisplayMode get savedDisplayMode => settingsStore.balanceDisplayMode;

  @computed
  bool get isFiatDisabled => settingsStore.fiatApiMode == FiatApiMode.disabled;

  @computed
  String get asset {
    final typeFormatted = walletTypeToString(appStore.wallet!.type);

    switch(wallet.type) {
      case WalletType.haven:
        return '$typeFormatted Assets';
      default:
        return typeFormatted;
    }
  }

  @computed
  BalanceDisplayMode get displayMode {
    if (isReversing) {
      if (savedDisplayMode == BalanceDisplayMode.hiddenBalance) {
        return BalanceDisplayMode.displayableBalance;
      } else {
        return BalanceDisplayMode.hiddenBalance;
      }
    }

    return savedDisplayMode;
  }

  @computed
  String get availableBalanceLabel {
    switch(wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
        return S.current.xmr_available_balance;
      default:
        return S.current.confirmed;
    }
  }

  @computed
  String get additionalBalanceLabel {
    switch(wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
        return S.current.xmr_full_balance;
      default:
        return S.current.unconfirmed;
    }
  }

  @computed
  bool get hasMultiBalance => appStore.wallet!.type == WalletType.haven;

  @computed
  String get availableBalance {
    final walletBalance = _walletBalance;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return walletBalance.formattedAvailableBalance;
  }

  @computed
  String get frozenBalance {
    final walletBalance = _walletBalance;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return getFormattedFrozenBalance(walletBalance);
  }

  @computed
  String get frozenFiatBalance {
    final walletBalance = _walletBalance;
    final fiatCurrency = settingsStore.fiatCurrency;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return  _getFiatBalance(
        price: price,
        cryptoAmount: getFormattedFrozenBalance(walletBalance)) + ' ' + fiatCurrency.toString();

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
          frozenBalance: '---',
          fiatAdditionalBalance: isFiatDisabled ? '' : '---',
          fiatAvailableBalance: isFiatDisabled ? '' : '---',
          fiatFrozenBalance: isFiatDisabled ? '' : '---',
          asset: key,
          formattedAssetTitle: _formatterAsset(key)));
      }
      final fiatCurrency = settingsStore.fiatCurrency;
      final price = fiatConvertationStore.prices[key] ?? 0;

      // if (price == null) {
      //   throw Exception('Price is null for: $key');
      // }

      final additionalFiatBalance = isFiatDisabled ? '' : (fiatCurrency.toString()
        + ' '
        + _getFiatBalance(
            price: price,
            cryptoAmount: value.formattedAdditionalBalance));

      final availableFiatBalance = isFiatDisabled ? '' : (fiatCurrency.toString()
        + ' '
        + _getFiatBalance(
            price: price,
            cryptoAmount: value.formattedAvailableBalance));


      final frozenFiatBalance = isFiatDisabled ? '' : (fiatCurrency.toString()
          + ' '
          + _getFiatBalance(
              price: price,
              cryptoAmount: getFormattedFrozenBalance(value)));


      return MapEntry(
          key,
          BalanceRecord(
              availableBalance: value.formattedAvailableBalance,
              additionalBalance: value.formattedAdditionalBalance,
              frozenBalance: getFormattedFrozenBalance(value),
              fiatAdditionalBalance: additionalFiatBalance,
              fiatAvailableBalance: availableFiatBalance,
              fiatFrozenBalance: frozenFiatBalance,
              asset: key,
              formattedAssetTitle: _formatterAsset(key)));
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
  Balance get _walletBalance {
    final balance = wallet.balance[wallet.currency];

    if (balance == null) {
      throw Exception('No balance for ${wallet.currency}');
    }

    return balance;
  }

  @computed
  CryptoCurrency get currency => appStore.wallet!.currency;

  @observable
  bool isShowCard;

  ReactionDisposer? _onCurrentWalletChangeReaction;

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>?
          wallet) {
    if (wallet == null) {
      return;
    }

    this.wallet = wallet;
    _onCurrentWalletChangeReaction?.reaction.dispose();
    isShowCard = wallet.walletInfo.isShowIntroCakePayCard;
  }

  @action
  Future<void> disableIntroCakePayCard () async {
    const cardDisplayStatus = false;
    wallet.walletInfo.showIntroCakePayCard = cardDisplayStatus;
    await wallet.walletInfo.save();
    isShowCard = cardDisplayStatus;
  }

  String _getFiatBalance({required double price, String? cryptoAmount}) {
    if (cryptoAmount == null || cryptoAmount.isEmpty) {
      return '0.00';
    }

    return calculateFiatAmount(price: price, cryptoAmount: cryptoAmount);
  }

  String _formatterAsset(CryptoCurrency asset) {
    switch (wallet.type) {
      case WalletType.haven:
        final assetStringified = asset.toString();

        if (asset != CryptoCurrency.xhv && assetStringified[0].toUpperCase() == 'X') {
          return assetStringified.replaceFirst('X', 'x');
        }

        return asset.toString();
      default:
        return asset.toString();
    }
  }

  String getFormattedFrozenBalance(Balance walletBalance) => walletBalance.formattedFrozenBalance;
}

