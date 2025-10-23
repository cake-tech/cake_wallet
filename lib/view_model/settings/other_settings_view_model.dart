import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/package_info.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'other_settings_view_model.g.dart';

class OtherSettingsViewModel = OtherSettingsViewModelBase
    with _$OtherSettingsViewModel;

abstract class OtherSettingsViewModelBase with Store {
  OtherSettingsViewModelBase(this._settingsStore, this._wallet, this.sendViewModel)
      : walletType = _wallet.type,
        currentVersion = '' {
    PackageInfo.fromPlatform().then(
        (PackageInfo packageInfo) => currentVersion = packageInfo.version);

    final priority = _settingsStore.priority[_wallet.type];
    final priorities = priorityForWalletType(_wallet.type);

    if (!priorities.contains(priority) && priorities.isNotEmpty) {
      _settingsStore.priority[_wallet.type] = priorities.first;
    }
  }

  final WalletType walletType;
  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
      TransactionInfo> _wallet;

  @observable
  String currentVersion;

  final SettingsStore _settingsStore;
  final SendViewModel sendViewModel;

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
      [WalletType.nano, WalletType.banano].contains(_wallet.type);

  @computed
  bool get changeHardwareWalletTypeEnabled => [
        HardwareWalletType.cupcake,
        HardwareWalletType.coldcard,
        HardwareWalletType.seedsigner,
      ].contains(_wallet.hardwareWalletType);

  @computed
  bool get displayTransactionPriority =>
      !(changeRepresentativeEnabled || [WalletType.solana, WalletType.tron].contains(_wallet.type));

  String getDisplayPriority(dynamic priority) {
    final _priority = priority as TransactionPriority;

    if ([
      WalletType.bitcoin,
      WalletType.litecoin,
      WalletType.bitcoinCash,
      WalletType.dogecoin,
    ].contains(_wallet.type)) {
      final rate = bitcoin!.getFeeRate(_wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate);
    }

    return priority.toString();
  }

  String getDisplayBitcoinPriority(dynamic priority, int customValue) {
    final _priority = priority as TransactionPriority;

    if ([
      WalletType.bitcoin,
      WalletType.litecoin,
      WalletType.bitcoinCash,
      WalletType.dogecoin,
    ].contains(_wallet.type)) {
      final rate = bitcoin!.getFeeRate(_wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate,
          customRate: customValue);
    }

    return priority.toString();
  }

  void onDisplayPrioritySelected(TransactionPriority priority) =>
      _settingsStore.priority[walletType] = priority;

  void onDisplayBitcoinPrioritySelected(
      TransactionPriority priority, double customValue) {
    if (_wallet.type == WalletType.bitcoin) {
      _settingsStore.customBitcoinFeeRate = customValue.round();
    }
    _settingsStore.priority[_wallet.type] = priority;
  }

  @action
  Future<void> onHardwareWalletTypeChanged(HardwareWalletType hwType) async {
    _wallet.walletInfo.hardwareWalletType = hwType;
    return _wallet.walletInfo.save();
  }

  @computed
  double get customBitcoinFeeRate =>
      _settingsStore.customBitcoinFeeRate.toDouble();

  int? get customPriorityItemIndex {
    final priorities = priorityForWalletType(walletType);
    final customItem = priorities.firstWhereOrNull(
        (element) => element == bitcoin!.getBitcoinTransactionPriorityCustom());
    return customItem != null ? priorities.indexOf(customItem) : null;
  }

  int? get maxCustomFeeRate {
    if (_wallet.type == WalletType.bitcoin) {
      return bitcoin!.getMaxCustomFeeRate(_wallet);
    }
    return null;
  }
}
