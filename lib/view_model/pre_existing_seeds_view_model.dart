import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:cake_wallet/reactions/bip39_wallet_utils.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'pre_existing_seeds_view_model.g.dart';

class PreExistingSeedsViewModel = PreExistingSeedsViewModelBase with _$PreExistingSeedsViewModel;

abstract class PreExistingSeedsViewModelBase with Store {
  PreExistingSeedsViewModelBase(
    this._appStore,
    this._walletLoadingService,
    this._walletManager, {
    required this.type,
  })  : useNewSeed = false,
        isFetchingMnemonic = false,
        wallets = ObservableList<WalletGroup>() {
    reaction((_) => _appStore.wallet, (_) => updateWalletInfoSourceList());
    updateWalletInfoSourceList();
  }

  final WalletType type;
  final AppStore _appStore;
  final WalletManager _walletManager;
  final WalletLoadingService _walletLoadingService;

  @observable
  ObservableList<WalletGroup> wallets;

  @observable
  WalletGroup? selectedWalletGroup;

  @observable
  bool useNewSeed;

  @observable
  String? parentAddress;

  @observable
  bool isFetchingMnemonic;

  @action
  Future<String?> getSelectedWalletMnemonic() async {
    if (selectedWalletGroup == null) return null;

    try {
      isFetchingMnemonic = true;
      final wallet = await _walletLoadingService.load(
        selectedWalletGroup!.leadWallet!.type,
        selectedWalletGroup!.leadWallet!.name,
      );

      parentAddress = selectedWalletGroup!.parentAddress;

      return wallet.seed;
    } catch (e) {
      return null;
    } finally {
      isFetchingMnemonic = false;
    }
  }

  @action
  void selectWalletGroup(WalletGroup wallet) {
    selectedWalletGroup = wallet;
    useNewSeed = false;
  }

  @action
  void selectNewSeed() {
    useNewSeed = true;
    selectedWalletGroup = null;
  }

  @action
  void updateWalletInfoSourceList() {
    wallets.clear();

    _walletManager.updateWalletGroups();

    final walletGroups = _walletManager.walletGroups;

    // Iterate through the wallet groups to filter and categorize wallets
    for (var group in walletGroups) {
      // Get the lead wallet (which could be the parent or the first child wallet)
      WalletInfo? leadWalletInfo = group.leadWallet;

      // If no lead wallet, skip this group
      if (leadWalletInfo == null) continue;

      if (!isBIP39Wallet(leadWalletInfo.type)) continue;

      if (leadWalletInfo.type == WalletType.nano &&
          leadWalletInfo.derivationInfo?.derivationType == DerivationType.nano) continue;

      // Check if the lead wallet type is not the same as the selected type
      bool isSameTypeAsSelectedWallet = leadWalletInfo.type == type;

      // Check if the any of the child wallets in the group has the same type as the selected type
      bool isUsedSeed = walletGroups.any(
        (walletGroup) => walletGroup.wallets.any(
          (info) => info.type == type && info.parentAddress == leadWalletInfo.address,
        ),
      );

      // Exclude wallets that don't meet the criteria
      if (isSameTypeAsSelectedWallet || isUsedSeed) continue;

      // If the group passes the filters, add it to the wallets list
      wallets.add(group);
    }
  }

  WalletListItem convertWalletInfoToWalletListItem(WalletInfo info) {
    return WalletListItem(
      name: info.name,
      type: info.type,
      key: info.key,
      isCurrent: info.name == _appStore.wallet?.name && info.type == _appStore.wallet?.type,
      isEnabled: availableWalletTypes.contains(info.type),
      isTestnet: info.network?.toLowerCase().contains('testnet') ?? false,
    );
  }
}
