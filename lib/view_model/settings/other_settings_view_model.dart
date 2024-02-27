import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info/package_info.dart';

part 'other_settings_view_model.g.dart';

class OtherSettingsViewModel = OtherSettingsViewModelBase with _$OtherSettingsViewModel;

abstract class OtherSettingsViewModelBase with Store {
  OtherSettingsViewModelBase(this._settingsStore, this._wallet)
      : walletType = _wallet.type,
        currentVersion = '' {
    PackageInfo.fromPlatform()
        .then((PackageInfo packageInfo) => currentVersion = packageInfo.version);

    final priority = _settingsStore.priority[_wallet.type];
    final priorities = priorityForWalletType(_wallet.type);

    if (!priorities.contains(priority) && priorities.isNotEmpty) {
      _settingsStore.priority[_wallet.type] = priorities.first;
    }
  }

  final WalletType walletType;
  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;

  @observable
  String currentVersion;

  final SettingsStore _settingsStore;

  @computed
  TransactionPriority get transactionPriority {
    final priority = _settingsStore.priority[walletType];

    if (priority == null) {
      throw Exception('Unexpected type ${walletType.toString()}');
    }

    return priority;
  }

  @computed
  bool get changeRepresentativeEnabled =>
      _wallet.type == WalletType.nano || _wallet.type == WalletType.banano;

  @computed
  bool get displayTransactionPriority =>
      !(changeRepresentativeEnabled || _wallet.type == WalletType.solana);

  @computed
  bool get isEnabledBuyAction => !_settingsStore.disableBuy && _wallet.type != WalletType.haven;

  @computed
  bool get isEnabledSellAction => !_settingsStore.disableSell && _wallet.type != WalletType.haven;

  List<ProviderType> get availableBuyProvidersTypes {
    return ProvidersHelper.getAvailableBuyProviderTypes(walletType);
  }

  List<ProviderType> get availableSellProvidersTypes =>
      ProvidersHelper.getAvailableSellProviderTypes(walletType);

  ProviderType get buyProviderType =>
      _settingsStore.defaultBuyProviders[walletType] ?? ProviderType.askEachTime;

  ProviderType get sellProviderType =>
      _settingsStore.defaultSellProviders[walletType] ?? ProviderType.askEachTime;

  String getDisplayPriority(dynamic priority) {
    final _priority = priority as TransactionPriority;

    if (_wallet.type == WalletType.bitcoin ||
        _wallet.type == WalletType.litecoin ||
        _wallet.type == WalletType.bitcoinCash) {
      final rate = bitcoin!.getFeeRate(_wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate);
    }

    return priority.toString();
  }

  String getBuyProviderType(dynamic buyProviderType) {
    final _buyProviderType = buyProviderType as ProviderType;
    return _buyProviderType == ProviderType.askEachTime
        ? S.current.ask_each_time
        : _buyProviderType.title;
  }

  String getSellProviderType(dynamic sellProviderType) {
    final _sellProviderType = sellProviderType as ProviderType;
    return _sellProviderType == ProviderType.askEachTime
        ? S.current.ask_each_time
        : _sellProviderType.title;
  }

  void onDisplayPrioritySelected(TransactionPriority priority) =>
      _settingsStore.priority[_wallet.type] = priority;

  @action
  ProviderType onBuyProviderTypeSelected(ProviderType buyProviderType) =>
      _settingsStore.defaultBuyProviders[walletType] = buyProviderType;

  @action
  ProviderType onSellProviderTypeSelected(ProviderType sellProviderType) =>
      _settingsStore.defaultSellProviders[walletType] = sellProviderType;
}
