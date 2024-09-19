import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/bip39_wallet_utils.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'pre_existing_seeds_view_model.g.dart';

class WalletGroupsDisplayViewModel = WalletGroupsDisplayViewModelBase with _$WalletGroupsDisplayViewModel;

abstract class WalletGroupsDisplayViewModelBase with Store {
  WalletGroupsDisplayViewModelBase(
    this._appStore,
    this._walletLoadingService,
    this._walletManager, {
    required this.type,
  })  : useNewSeed = false,
        isFetchingMnemonic = false,
        wallets = ObservableList<WalletGroup>(),
        groupNames = ObservableList<String>() {
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
  ObservableList<String> groupNames;

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
        selectedWalletGroup!.wallets.first.type,
        selectedWalletGroup!.wallets.first.name,
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

    // Initialize a counter for default group names
    int defaultGroupCounter = 1;

    // Iterate through the wallet groups to filter and categorize wallets
    for (var group in walletGroups) {
      // Handle group wallet filtering
      bool shouldExcludeGroup = group.wallets.any((wallet) {
        // Check for non-BIP39 wallet types
        bool isNonBIP39Wallet = !isBIP39Wallet(wallet.type);

        // Check for nano derivation type
        bool isNanoDerivationType = wallet.type == WalletType.nano &&
            wallet.derivationInfo?.derivationType == DerivationType.nano;

        // Check for electrum derivation type
        bool isElectrumDerivationType =
            (wallet.type == WalletType.bitcoin || wallet.type == WalletType.litecoin) &&
                wallet.derivationInfo?.derivationType == DerivationType.electrum;

        // Check that selected wallet type is not present already in group
        bool isSameTypeAsSelectedWallet = wallet.type == type;

        // Exclude if any of these conditions are true
        return isNonBIP39Wallet ||
            isNanoDerivationType ||
            isElectrumDerivationType ||
            isSameTypeAsSelectedWallet;
      });

      if (shouldExcludeGroup) continue;

      // Handle group name display
      if (group.groupName != null && group.groupName!.isNotEmpty) {
        groupNames.add(group.groupName!);
      } else {
        groupNames.add('${S.current.wallet_group} ${defaultGroupCounter}');
        defaultGroupCounter++;
      }

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
