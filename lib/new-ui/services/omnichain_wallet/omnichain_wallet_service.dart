import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:cake_wallet/new-ui/entries/omnichain_wallet/omnichain_create_group_request.dart';
import 'package:cake_wallet/src/widgets/seed_language_picker.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/zcash/zcash_network_type.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

class OmniChainWalletCreationService {
  OmniChainWalletCreationService({
    required this.walletCreationService,
    required this.walletNewVMBuilder,
    required this.walletManager,
    required this.appStore,
    required this.walletLoadingService,
  });

  final WalletCreationService walletCreationService;
  final WalletNewVM Function(NewWalletArguments) walletNewVMBuilder;
  final WalletManager walletManager;
  final AppStore appStore;
  final WalletLoadingService walletLoadingService;

  static const defaultMoneroOptions = [defaultSeedLanguage, MoneroSeedType.bip39];

  String? _lastGroupPassphrase;

  List<String> getAllCustomGroupNames() => walletManager.walletGroups
        .map((g) => g.groupName)
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .toList();

  Future<List<WalletInfo>> getCurrentWalletGroupWallets() async {
    final currentWalletInfo = appStore.wallet?.walletInfo;
    if (currentWalletInfo == null) return [];

    await walletManager.updateWalletGroups();

    final groupKey = walletManager.resolveGroupKey(currentWalletInfo);

    return walletManager.getWalletsInGroup(groupKey);
  }

  String? getCurrentGroupName() {
    final currentWalletInfo = appStore.wallet?.walletInfo;
    if (currentWalletInfo == null) return null;
    return walletManager.getGroupName(currentWalletInfo);
  }

  bool groupNameExists(String name) {
    final groupName = name.toLowerCase();
    return getAllCustomGroupNames().any(
      (name) => name.toLowerCase() == groupName,
    );
  }

  Future<String> _uniqueNamePerGroup(WalletType type, String groupName) async {
    final typeSuffix = walletTypeToString(type);
    return '${groupName}_${typeSuffix}';
  }

  Future<void> createGroup({required OmniChainCreateGroupRequest request}) async {
    try {
      final primaryType = request.primaryType;
      final types = <WalletType>{primaryType, ...request.selectedTypes}.toSet();
      final groupName = request.groupName;
      final mnemonic = request.mnemonic;

      if (types.isEmpty) throw 'No wallet types provided.';
      if (groupName.isEmpty) throw 'No wallet name provided.';

      dynamic options;

      // default options for monero
      if (primaryType == WalletType.monero) options = defaultMoneroOptions;

      final primaryWalletName = await _uniqueNamePerGroup(primaryType, request.groupName);
      await _createSingleWallet(
        type: primaryType,
        finalName: primaryWalletName,
        isChildWallet: false,
        mnemonic: mnemonic,
        options: options,
        makeCurrent: true,
        isGroupCreationDeferred: true,
        useTestnet: request.useTestnet,
        zcashNetwork: request.zcashNetwork,
        passphrase: request.passphrase,
      );

      final wallet = appStore.wallet;

      if (wallet == null) throw Exception('First wallet was not set as current.');

      final groupKey = walletManager.resolveGroupKey(wallet.walletInfo);

      String? sharedMnemonic = mnemonic;
      sharedMnemonic ??= wallet.seed;
      if (sharedMnemonic == null || sharedMnemonic.isEmpty) {
        throw Exception('Failed to resolve mnemonic (shared) for group.');
      }

      // Remember the passphrase for this session so that activating one of
      // the group's other networks later reuses the same BIP39 passphrase.
      _lastGroupPassphrase = request.passphrase;

      final restTypesRaw = types.where((type) => type != primaryType).toList();

      await _createWalletPlaceholders(
        groupKey: groupKey,
        groupName: groupName,
        restTypes: restTypesRaw,
      );

      await walletManager.updateWalletGroups();
      walletManager.setGroupName(groupKey, groupName);
      final selectedIcon = request.walletIcon;
      if (selectedIcon != null) {
        walletManager.setGroupIcon(groupKey, selectedIcon);
      }
      await walletManager.updateWalletGroups();
    } catch (e) {
      throw Exception('Failed to create wallet group: ${e.toString()}');
    }
  }

  Future<void> activatePlaceholderWallet(WalletInfo walletInfo) async {
    if (walletInfo.isReady) {
      final wallet = await walletLoadingService.load(
        walletInfo.type,
        walletInfo.name,
      );

      await appStore.changeCurrentWallet(wallet);
      await walletManager.updateWalletGroups();
      return;
    }

    final currentWallet = appStore.wallet;

    if (currentWallet == null) {
      throw Exception('Current wallet is null');
    }

    final mnemonic = currentWallet.seed;

    if (mnemonic == null || mnemonic.isEmpty) {
      throw Exception('Failed to resolve shared mnemonic');
    }

    dynamic options;

    if (walletInfo.type == WalletType.monero) {
      options = defaultMoneroOptions;
    }

    await WalletInfo.delete(walletInfo);

    await _createSingleWallet(
      type: walletInfo.type,
      finalName: walletInfo.name,
      isChildWallet: true,
      mnemonic: mnemonic,
      options: options,
      makeCurrent: true,
      isGroupCreationDeferred: true,
      passphrase: _lastGroupPassphrase ?? currentWallet.passphrase,
    );

    await walletManager.updateWalletGroups();
  }

  Future<void> addNetworksToCurrentGroup(Set<WalletType> types) async {
    final currentInfo = appStore.wallet?.walletInfo;
    if (currentInfo == null) throw Exception('No current wallet');

    final groupKey = walletManager.resolveGroupKey(currentInfo);
    final groupName = walletManager.getGroupName(currentInfo) ?? '';

    // existing group types (incl. the current wallet)
    final existing = (await getCurrentWalletGroupWallets()).map((w) => w.type).toSet();
    final newTypes = types.difference(existing).toList();
    if (newTypes.isEmpty) return;

    await _createWalletPlaceholders(
      groupKey: groupKey,
      groupName: groupName,
      restTypes: newTypes,
    );
    await walletManager.updateWalletGroups();
  }

  Future<void> _createSingleWallet({
    required WalletType type,
    required String finalName,
    required bool isChildWallet,
    required String? mnemonic,
    required dynamic options,
    required bool makeCurrent,
    required bool isGroupCreationDeferred,
    bool useTestnet = false,
    int zcashNetwork = ZcashNetworkType.mainnet,
    String? passphrase,
  }) async {
    final newArgs =
        NewWalletArguments(type: type, mnemonic: mnemonic, isChildWallet: isChildWallet);

    final walletNewVM = walletNewVMBuilder(newArgs);
    walletNewVM.name = finalName;
    walletNewVM.toggleUseTestnet(useTestnet);
    walletNewVM.setZcashNetwork(zcashNetwork);
    walletNewVM.seedSettingsViewModel.setPassphrase(passphrase);
    await walletNewVM.create(options: options, makeCurrent: makeCurrent, isGroupCreationDeferred: isGroupCreationDeferred);
  }

  Future<void> _createWalletPlaceholders(
      {required String groupKey,
      required String groupName,
      required List<WalletType> restTypes}) async {
    for (final type in restTypes) {
      final finalName = await _uniqueNamePerGroup(type, groupName);

      // Reserve the future paths but DO NOT create files now
      final dirPath = await pathForWalletDir(name: finalName, type: type);
      final path = await pathForWallet(name: finalName, type: type);

      final info = WalletInfo.external(
        id: WalletBase.idFor(finalName, type),
        name: finalName,
        type: type,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime.now(),
        path: path,
        dirPath: dirPath,
        address: '',
        showIntroCakePayCard: false,
        derivationInfoId: null,
        hardwareWalletType: null,
        hashedWalletIdentifier: groupKey,
        isReady: false,
      );

      await info.save();
    }
  }
}
