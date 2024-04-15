import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/reactions/bip39_wallet_utils.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'pre_existing_seeds_view_model.g.dart';

class PreExistingSeedsViewModel = PreExistingSeedsViewModelBase with _$PreExistingSeedsViewModel;

abstract class PreExistingSeedsViewModelBase with Store {
  PreExistingSeedsViewModelBase(
    this._appStore,
    this._walletInfoSource,
    this._walletLoadingService, {
    required this.type,
  })  : useNewSeed = false,
        wallets = ObservableList<WalletListItem>() {
    reaction((_) => _appStore.wallet, (_) => updateWalletInfoSourceList());
    updateWalletInfoSourceList();
  }

  final WalletType type;
  final AppStore _appStore;
  final Box<WalletInfo> _walletInfoSource;
  final WalletLoadingService _walletLoadingService;

  @observable
  ObservableList<WalletListItem> wallets;

  @observable
  WalletListItem? selectedWallet;

  @observable
  bool useNewSeed;

  @observable
  String? parentAddress;

  @action
  Future<String?> getSelectedWalletMnemonic() async {
    if (selectedWallet == null) return null;

    final wallet = await _walletLoadingService.load(selectedWallet!.type, selectedWallet!.name);

    parentAddress = wallet.walletAddresses.address;

    return wallet.seed;
  }

  @action
  void selectWallet(WalletListItem wallet) {
    selectedWallet = wallet;
    useNewSeed = false;
  }

  @action
  void selectNewSeed() {
    useNewSeed = true;
    selectedWallet = null;
  }

  @action
  void updateWalletInfoSourceList() {
    wallets.clear();

    // For the list to be displayed, we'll filter based on four conditions
    final filteredInfoSource = _walletInfoSource.values.where((element) {
      // Condition 1: Wallets that are BIP39 seed type
      bool isBIP39 = isBIP39Wallet(element.type);

      // Condition 2: Wallets that are not the same as the selected WalletType
      bool isDifferentType = element.type != type;

      // Condition 3: Wallets whose parentAddress property is null
      bool isUniqueSeed = element.parentAddress == null;

      // Condition 4: Wallets that have not been used to create the selectedType before
      bool isUnusedSeed = !_walletInfoSource.values
          .any((info) => info.type == type && info.parentAddress == element.address);

      // Finally, we check to see if all conditions are met.
      return isBIP39 && isDifferentType && isUniqueSeed && isUnusedSeed;
    });

    wallets.addAll(
      filteredInfoSource.map(
        (info) => WalletListItem(
          name: info.name,
          type: info.type,
          key: info.key,
          isCurrent: info.name == _appStore.wallet?.name && info.type == _appStore.wallet?.type,
          isEnabled: availableWalletTypes.contains(info.type),
        ),
      ),
    );
  }
}
