import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import '../reactions/wallet_utils.dart' show isBIP39Wallet;

part 'new_wallet_type_view_model.g.dart';

class NewWalletTypeViewModel = NewWalletTypeViewModelBase
    with _$NewWalletTypeViewModel;

abstract class NewWalletTypeViewModelBase with Store {
  NewWalletTypeViewModelBase(this._walletInfoSource) {
    itemSelection = ObservableMap<WalletType, bool>.of({
      WalletType.monero: false,
      WalletType.bitcoin: false,
      WalletType.ethereum: false,
      WalletType.litecoin: false,
      WalletType.dogecoin: false,
      WalletType.bitcoinCash: false,
      WalletType.polygon: false,
      WalletType.solana: false,
      WalletType.tron: false,
      WalletType.nano: false,
      WalletType.wownero: false,
    });
  }

  final Box<WalletInfo> _walletInfoSource;
  late final ObservableMap<WalletType, bool> itemSelection;


  @computed
  bool get hasExisitingWallet => _walletInfoSource.isNotEmpty;

  @computed
  bool get hasAnySelected => selectedTypes.isNotEmpty;

  @computed
  List<WalletType> get selectedTypes =>
      itemSelection.entries.where((e) => e.value).map((e) => e.key).toList();

  @action
  void deselectAllNonBIP39 () {
    for (var type in itemSelection.keys) {
      if (!isBIP39Wallet(type)) {
        itemSelection[type] = false;
      }
    }
  }

  @action
  void deselectAll () {
    for (var type in itemSelection.keys) {
      itemSelection[type] = false;
    }
  }

  @action
  void toggleSelection(WalletType type) {
    final newValue = !(itemSelection[type] ?? false);
    itemSelection[type] = newValue;
  }
}
