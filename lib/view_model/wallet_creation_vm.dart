import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/wallet_creation_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/wallet_group_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/nano/nano.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/restore/restore_wallet.dart";
import "package:cake_wallet/view_model/seed_settings_view_model.dart";
import "package:cake_wallet/zcash/zcash_network_type.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart";
import "package:polyseed/polyseed.dart";
import "package:uuid/uuid.dart";

part "wallet_creation_vm.g.dart";

class WalletCreationVM = WalletCreationVMBase with _$WalletCreationVM;

abstract class WalletCreationVMBase with Store {
  WalletCreationVMBase(this._appStore, this.walletCreationService, this.seedSettingsViewModel,
      {required this.type, required this.isRecovery})
      : state = InitialExecutionState(),
        name = "";

  @observable
  bool _useTestnet = false;

  int _zcashNetwork = ZcashNetworkType.mainnet;

  @computed
  bool get useTestnet => _useTestnet;

  int get zcashNetwork => _zcashNetwork;

  /// Name typed by the user. Since wallets are now named after their network,
  /// this is the *group* name, not the wallet name.
  @observable
  String name;

  @observable
  ExecutionState state;

  @observable
  String? walletPassword;

  @observable
  String? repeatedWalletPassword;

  bool get hasWalletPassword => SettingsStoreBase.walletPasswordDirectInput;

  WalletType type;
  final bool isRecovery;
  final WalletCreationService walletCreationService;
  final AppStore _appStore;
  final SeedSettingsViewModel seedSettingsViewModel;

  WalletGroupService get _walletGroupService => getIt.get<WalletGroupService>();

  bool isPolyseed(String seed) =>
      [WalletType.monero, WalletType.wownero].contains(type) &&
          (Polyseed.isValidSeed(seed) || (seed.split(" ").length == 14));

  Future<bool> nameExists(String name) => _walletGroupService.isGroupNameTaken(name);

  Future<bool> typeExists(WalletType type) => walletCreationService.typeExists(type);

  bool _isCreating = false;

  Future<void> create({
    dynamic options,
    bool makeCurrent = true,
    bool isGroupCreationDeferred = false,
    String? groupId,
    int? walletInfoIdOverride,
  }) async {
    try {
      if (_isCreating) {
        printV("not creating because we don't feel like doing so");
        return;
      }
      _isCreating = true;
      await _create(
          options: options,
          makeCurrent: makeCurrent,
          isGroupCreationDeferred: isGroupCreationDeferred,
          walletInfoIdOverride: walletInfoIdOverride,
          groupId: groupId);
    } finally {
      _isCreating = false;
    }
  }

  Future<void> _create({
    dynamic options,
    bool makeCurrent = true,
    bool isGroupCreationDeferred = false,
    String? groupId,
    int? walletInfoIdOverride,
  }) async {
    final type = this.type;
    try {
      state = IsExecutingState();

      if (hasWalletPassword && (walletPassword?.isEmpty ?? true)) {
        throw WalletCreationException(S.current.wallet_password_is_empty);
      }

      if (hasWalletPassword && walletPassword != repeatedWalletPassword) {
        throw WalletCreationException(S.current.repeated_password_is_incorrect);
      }

      WalletInfo? placeholder;
      int? keepSortOrder;
      String? placeholderRealGroupId;
      String? reservedId;

      if (walletInfoIdOverride != null) {
        final rows = await WalletInfo.selectList('walletInfoId = ?', [walletInfoIdOverride]);
        if (rows.isEmpty) {
          throw Exception('Placeholder WalletInfo not found (id=$walletInfoIdOverride)');
        }
        placeholder = rows.first;

        name = placeholder.name;
        if (type != placeholder.type) {
          throw Exception('Type mismatch: placeholder is ${placeholder.type}, requested $type');
        }

        keepSortOrder = placeholder.sortOrder;
        placeholderRealGroupId = placeholder.groupId;
        reservedId = placeholder.id;

        await WalletInfoAddressInfo.deleteByWalletInfoId(placeholder.internalId);
        await WalletInfoAddressMap.deleteByWalletInfoId(placeholder.internalId);
        for (final t in WalletInfoAddressType.values) {
          await WalletInfoAddress.deleteByType(placeholder.internalId, t);
        }
        await WalletInfo.delete(placeholder);
      }

      final existingGroupId = (placeholderRealGroupId?.isNotEmpty ?? false)
          ? placeholderRealGroupId
          : ((groupId?.isNotEmpty ?? false) ? groupId : null);
      final shouldCreateGroup = !isGroupCreationDeferred && existingGroupId == null;
      final groupName = name.trim().isNotEmpty ? name.trim() : walletTypeToDisplayName(type);

      if (shouldCreateGroup && await _walletGroupService.isGroupNameTaken(groupName)) {
        throw Exception(S.current.wallet_name_exists);
      }

      final walletId = reservedId ?? const Uuid().v4();

      final credentials = getCredentials(options);

      final di = ((credentials.derivationInfo?.derivationPath ?? "") == "")
          ? getDefaultCreateDerivation()
          : credentials.derivationInfo;

      final diId = await di!.save();
      credentials.derivationInfo = di;

      final walletInfo = WalletInfo.external(
        id: walletId,
        name: walletTypeToDisplayName(type),
        type: type,
        isRecovery: isRecovery,
        restoreHeight: credentials.height ?? 0,
        date: DateTime.now(),
        path: "",
        dirPath: "",
        address: "",
        showIntroCakePayCard:
        (!await walletCreationService.typeExists(type)) && type != WalletType.haven,
        derivationInfoId: diId,
        hardwareWalletType: credentials.hardwareWalletType,
      );

      walletInfo
        ..dirPath = await pathForWalletDirOf(walletInfo)
        ..path = await pathForWalletOf(walletInfo);
      credentials.walletInfo = walletInfo;

      printV("derivationInfo: ${(await walletInfo.getDerivationInfo()).toJson()}");
      final wallet = await process(credentials);

      walletInfo.isNonSeedWallet = isRecovery ? wallet.seed == null : false;

      if (existingGroupId != null) {
        walletInfo.groupId = existingGroupId;
      }

      if (keepSortOrder != null) {
        walletInfo.sortOrder = keepSortOrder;
      }
      walletInfo.address = wallet.walletAddresses.address;
      await walletInfo.save();

      if (shouldCreateGroup) {
        final newGroupId = const Uuid().v4();
        await _walletGroupService.createWalletGroup(
          newGroupId,
          name: groupName,
          icon: WalletIcon(
            type: WalletIconType.crypto,
            value: type.name,
            colorIndex: 0,
            backgroundEnabled: false,
          ),
        );
        await _walletGroupService.setGroupIdForWalletInfo(walletInfo, newGroupId);
      }

      await wallet.save();
      await _walletGroupService.updateWalletGroups();

      if (makeCurrent) {
        await _appStore.changeCurrentWallet(wallet);
      }

      if (!isGroupCreationDeferred) {
        _appStore.authenticationStore.allowedCreate();
      }

      state = ExecutedSuccessfullyState();
    } catch (e, s) {
      printV("error: $e");
      printV("stack: $s");
      String message = e.toString();
      if (e is RestoreFromSeedException) {
        message = e.message;
      }
      state = FailureState(message);
    }
  }

  DerivationInfo getDefaultCreateDerivation() {
    final useBip39ForBitcoin = seedSettingsViewModel.bitcoinSeedType.type == DerivationType.bip39;
    final useBip39ForNano = seedSettingsViewModel.nanoSeedType.type == DerivationType.bip39;
    switch (type) {
      case WalletType.nano:
        if (useBip39ForNano) {
          return DerivationInfo(derivationType: DerivationType.bip39);
        }
        return DerivationInfo(derivationType: DerivationType.nano);
      case WalletType.bitcoin:
        if (useBip39ForBitcoin) {
          return DerivationInfo(
            derivationType: DerivationType.bip39,
            derivationPath: "m/84'/0'/0'",
            description: "Standard BIP84 native segwit",
            scriptType: "p2wpkh",
          );
        }
        return bitcoin!.getElectrumDerivations()[DerivationType.electrum]!.first;
      case WalletType.litecoin:
        if (useBip39ForBitcoin) {
          return DerivationInfo(
            derivationType: DerivationType.bip39,
            derivationPath: "m/84'/2'/0'",
            description: "Default Litecoin",
            scriptType: "p2wpkh",
          );
        }
        return bitcoin!.getElectrumDerivations()[DerivationType.electrum]!.first;
      case WalletType.decred:
        return DerivationInfo(derivationType: DerivationType.bip39);
      default:
        return DerivationInfo(derivationType: DerivationType.unknown);
    }
  }

  DerivationInfo? getCommonRestoreDerivation() {
    final useElectrum = seedSettingsViewModel.bitcoinSeedType.type == DerivationType.electrum;
    final useNanoStandard = seedSettingsViewModel.nanoSeedType.type == DerivationType.nano;
    switch (this.type) {
      case WalletType.nano:
        if (useNanoStandard) {
          return DerivationInfo(derivationType: DerivationType.nano);
        }
        return DerivationInfo(derivationType: DerivationType.bip39);
      case WalletType.bitcoin:
        if (useElectrum) {
          return bitcoin!.getElectrumDerivations()[DerivationType.electrum]!.first;
        }
        return DerivationInfo(
          derivationType: DerivationType.bip39,
          derivationPath: "m/84'/0'/0'/0",
          description: "Standard BIP84 native segwit",
          scriptType: "p2wpkh",
        );
      case WalletType.litecoin:
        if (useElectrum) {
          return bitcoin!.getElectrumDerivations()[DerivationType.electrum]!.first;
        }
        return DerivationInfo(
          derivationType: DerivationType.bip39,
          derivationPath: "m/84'/2'/0'/0",
          description: "Standard BIP84 native segwit (litecoin)",
          scriptType: "p2wpkh",
        );
      default:
        return null;
    }
  }

  Future<List<DerivationInfo>> getDerivationInfoFromQRCredentials(
      RestoredWallet restoreWallet) async {
    var list = <DerivationInfo>[];
    final walletType = restoreWallet.type;
    var appStore = getIt.get<AppStore>();
    var node = appStore.settingsStore.getCurrentNode(walletType);

    switch (walletType) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
        final derivationList = await bitcoin!.getDerivationsFromMnemonic(
          mnemonic: restoreWallet.mnemonicSeed!,
          node: node,
          passphrase: restoreWallet.passphrase,
        );

        if (derivationList.firstOrNull?.transactionsCount == 0 && derivationList.length > 1)
          return [];
        return derivationList;

      case WalletType.nano:
        return nanoUtil!.getDerivationsFromMnemonic(
          mnemonic: restoreWallet.mnemonicSeed!,
          node: node,
        );
      default:
        break;
    }
    return list;
  }

  WalletCredentials getCredentials(dynamic options) => throw UnimplementedError();

  Future<WalletBase> process(WalletCredentials credentials) => throw UnimplementedError();

  @action
  void toggleUseTestnet(bool? value) {
    _useTestnet = value ?? !_useTestnet;
  }

  void setZcashNetwork(int network) {
    _zcashNetwork = network;
  }
}