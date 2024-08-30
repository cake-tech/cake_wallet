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
        wallets = ObservableMap<WalletListItem, List<WalletListItem>>() {
    reaction((_) => _appStore.wallet, (_) => updateWalletInfoSourceList());
    updateWalletInfoSourceList();
  }

  final WalletType type;
  final AppStore _appStore;
  final Box<WalletInfo> _walletInfoSource;
  final WalletLoadingService _walletLoadingService;

  @observable
  ObservableMap<WalletListItem, List<WalletListItem>> wallets;

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

    // Separate lists for parent and child wallets
    List<WalletInfo> parentWallets = [];
    List<WalletInfo> childWallets = [];

    // Get a list of all wallet info objects
    final walletInfos = _walletInfoSource.values.toList();

    // Categorize wallets as parent or child based on criteria
    for (var walletInfo in walletInfos) {
      if (isBIP39Wallet(walletInfo.type) && walletInfo.parentAddress == null) {
        parentWallets.add(walletInfo);
      } else {
        childWallets.add(walletInfo);
      }
    }

    // Filter out parent wallets that don't meet the additional criteria
    parentWallets = parentWallets.where((parentWallet) {
      // Condition 1: The parent wallet should not be of the same type as the selected wallet type
      bool isSameTypeAsSelectedWallet = parentWallet.type == type;

      // Condition 2: The parent wallet should not have been used to create the selected type before
      bool isUsedSeed = _walletInfoSource.values.any(
        (info) =>  info.type == type && info.parentAddress == parentWallet.address,
      );

      // Exclude wallets that meet either condition
      return !isSameTypeAsSelectedWallet && !isUsedSeed;
    }).toList();

    // // Handle deletion of a parent wallet: promote its child to parent if no other parent wallet exists for that child
    // for (var parentWallet in parentWallets) {
    //   // Get the children of this specific parent wallet
    //   final childrenOfParent =
    //       childWallets.where((child) => child.parentAddress == parentWallet.address).toList();

    //   // If there are no parent wallets left for this child wallet's parent address, promote the child
    //   if (childrenOfParent.isNotEmpty) {
    //     for (var childWallet in childrenOfParent) {
    //       final parentExists =
    //           parentWallets.any((parent) => parent.address == childWallet.parentAddress);

    //       // If no parent exists for this child, promote it to a parent wallet
    //       if (!parentExists) {
    //         // Promote the child wallet by making its parentAddress null
    //         final promotedChild = childWallet.copyWith(parentAddress: null);
    //         parentWallets.add(promotedChild);

    //         // Update _walletInfoSource to reflect the promotion
    //         _walletInfoSource[promotedChild.key] = promotedChild;

    //         // Remove the promoted wallet from the childWallets list
    //         childWallets.remove(childWallet);
    //       }
    //     }
    //   }
    // }

    // Map to link parent wallets to their respective child wallets
    Map<WalletListItem, List<WalletListItem>> parentToChildWalletMap = {};

    for (var parentWallet in parentWallets) {
      final parent = WalletListItem(
        name: parentWallet.name,
        type: parentWallet.type,
        key: parentWallet.key,
        isCurrent: parentWallet.name == _appStore.wallet?.name &&
            parentWallet.type == _appStore.wallet?.type,
        isEnabled: availableWalletTypes.contains(parentWallet.type),
      );

      // Find child wallets associated with the current parent wallet
      final associatedChildWallets = childWallets
          .where((childWallet) => childWallet.parentAddress == parentWallet.address)
          .map((childWalletInfo) => WalletListItem(
                name: childWalletInfo.name,
                type: childWalletInfo.type,
                key: childWalletInfo.key,
                isCurrent: childWalletInfo.name == _appStore.wallet?.name &&
                    childWalletInfo.type == _appStore.wallet?.type,
                isEnabled: availableWalletTypes.contains(childWalletInfo.type),
              ))
          .toList();

      // Add the parent-child wallet relationship to the map
      parentToChildWalletMap[parent] = associatedChildWallets;
    }

    // Add all the mapped wallets to the main map
    wallets.addAll(parentToChildWalletMap);
  }
}
