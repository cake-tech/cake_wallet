import "package:cake_wallet/core/new_wallet_arguments.dart";
import "package:cake_wallet/core/wallet_creation_service.dart";
import 'package:cake_wallet/core/wallet_loading_service.dart';
import "package:cake_wallet/entities/seed_type.dart";
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:cake_wallet/new-ui/entries/omnichain_wallet/omnichain_create_group_request.dart';
import 'package:cake_wallet/src/widgets/seed_language_picker.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/zcash/zcash_network_type.dart';
import 'package:cw_core/pathForWallet.dart';
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:uuid/uuid.dart";

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

      final groupId = const Uuid().v4();

      await _createSingleWallet(
        type: primaryType,
        groupId: groupId,
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
        groupId: groupId,
        restTypes: restTypesRaw,
      );

      await walletManager.updateWalletGroups();
      await walletManager.setGroupName(groupId, groupName);
      final selectedIcon = request.walletIcon;
      if (selectedIcon != null) {
        await walletManager.setGroupIcon(groupId, selectedIcon);
      }
      await walletManager.updateWalletGroups();
    } catch (e) {
      throw Exception('Failed to create wallet group: ${e.toString()}');
    }
  }

  Future<void> activatePlaceholderWallet(WalletInfo walletInfo) async {
    if (walletInfo.isReady) {
      final wallet = await walletLoadingService.load(walletInfo);

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

    // No groupId passed here on purpose — this placeholder already has its
    // real group id baked in from _createWalletPlaceholders, and _create()'s
    // placeholder-reuse branch (walletInfoIdOverride) must preserve that,
    // not overwrite it with something new.
    await _createSingleWallet(
      type: walletInfo.type,
      isChildWallet: true,
      mnemonic: mnemonic,
      options: options,
      makeCurrent: true,
      isGroupCreationDeferred: true,
      passphrase: _lastGroupPassphrase ?? currentWallet.passphrase,
      walletInfoIdOverride: walletInfo.internalId,
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
      groupId: groupKey,
      restTypes: newTypes,
    );
    await walletManager.updateWalletGroups();
  }

  Future<void> _createSingleWallet({
    required WalletType type,
    String? groupId,
    required bool isChildWallet,
    required String? mnemonic,
    required dynamic options,
    required bool makeCurrent,
    required bool isGroupCreationDeferred,
    bool useTestnet = false,
    int zcashNetwork = ZcashNetworkType.mainnet,
    String? passphrase,
    int? walletInfoIdOverride,
  }) async {
    final newArgs = NewWalletArguments(type: type, mnemonic: mnemonic, isChildWallet: isChildWallet);

    final walletNewVM = walletNewVMBuilder(newArgs);
    walletNewVM.name = walletTypeToDisplayName(type);
    walletNewVM.toggleUseTestnet(useTestnet);
    walletNewVM.setZcashNetwork(zcashNetwork);
    walletNewVM.seedSettingsViewModel.setPassphrase(passphrase);
    await walletNewVM.create(
      options: options,
      makeCurrent: makeCurrent,
      isGroupCreationDeferred: isGroupCreationDeferred,
      walletInfoIdOverride: walletInfoIdOverride,
      groupId: groupId,
    );
  }

  Future<void> _createWalletPlaceholders({
    required String groupId,
    required List<WalletType> restTypes,
  }) async {
    for (final type in restTypes) {
      final id = const Uuid().v4();

      // Reserve the id + directory now; activating this placeholder later
      // reuses this exact id/path rather than generating a new one.
      final dirPath = await pathForWalletDir(id: id, type: type);
      final path = await pathForWallet(id: id, type: type);

      final info = WalletInfo.external(
        id: id,
        name: walletTypeToDisplayName(type),
        type: type,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime.now(),
        path: path,
        dirPath: dirPath,
        address: "",
        showIntroCakePayCard: false,
        derivationInfoId: null,
        hardwareWalletType: null,
        hashedWalletIdentifier: groupId,
        isReady: false,
      );

      await info.save();
    }
  }
}