import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
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

    if (!priorities.contains(priority)) {
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

  String getDisplayPriority(dynamic priority) {
    final _priority = priority as TransactionPriority;

    if (_wallet.type == WalletType.bitcoin || _wallet.type == WalletType.litecoin) {
      final rate = bitcoin!.getFeeRate(_wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate);
    }

    return priority.toString();
  }

  void onDisplayPrioritySelected(TransactionPriority priority) =>
      _settingsStore.priority[_wallet.type] = priority;
}
