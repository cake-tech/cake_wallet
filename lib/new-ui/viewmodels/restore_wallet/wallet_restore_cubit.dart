import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/bitcoin_cash/bitcoin_cash.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/generate_wallet_password.dart";
import "package:cake_wallet/core/wallet_creation_service.dart";
import "package:cake_wallet/decred/decred.dart";
import "package:cake_wallet/dogecoin/dogecoin.dart";
import "package:cake_wallet/entities/hash_wallet_identifier.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/nano/nano.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/seed_settings_cubit.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/utils/feature_flag.dart";
import "package:cake_wallet/view_model/restore/restore_mode.dart";
import "package:cake_wallet/view_model/restore/restore_wallet.dart";
import "package:cake_wallet/wownero/wownero.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cake_wallet/zcash/zcash_network_type.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:polyseed/polyseed.dart";

part "wallet_restore_state.dart";

class WalletRestoreCubit extends Cubit<WalletRestoreState> {
  WalletRestoreCubit(
    this._appStore,
    this._walletCreationService,
    this._seedSettingsCubit, {
    required this.type,
    this.restoredWallet,
    this.hardwareWalletType,
  }) : super(
          WalletRestoreState(
            mode: restoredWallet?.restoreMode ?? WalletRestoreMode.seed,
            isButtonEnabled: restoredWallet != null,
          ),
        ) {
    _walletCreationService.changeWalletType(type: type);
    final restoredWallet = this.restoredWallet;
    if (restoredWallet != null && restoredWallet.restoreMode == WalletRestoreMode.seed) {
      _seedSettingsCubit.setPassphrase(restoredWallet.passphrase);
    }
  }

  static const moneroSeedMnemonicLength = 25;
  static const decredSeedMnemonicLength = 15;

  final AppStore _appStore;
  final WalletCreationService _walletCreationService;
  final SeedSettingsCubit _seedSettingsCubit;
  final WalletType type;
  final RestoredWallet? restoredWallet;
  final HardwareWalletType? hardwareWalletType;

  bool _isRestoring = false;

  List<WalletRestoreMode> get availableModes {
    switch (type) {
      case WalletType.monero:
        return WalletRestoreMode.values;
      case WalletType.bitcoinCash:
      case WalletType.zano:
      case WalletType.dogecoin:
        return [WalletRestoreMode.seed];
      case WalletType.none:
        return [];
      default:
        return [WalletRestoreMode.seed, WalletRestoreMode.keys];
    }
  }

  bool get hasSeedLanguageSelector =>
      [WalletType.monero, WalletType.haven, WalletType.wownero].contains(type);

  bool get hasBlockchainHeightSelector => [
        WalletType.monero,
        WalletType.haven,
        WalletType.wownero,
        WalletType.zcash,
        WalletType.zano,
      ].contains(type);

  bool get hasRestoreFromPrivateKey => [
        WalletType.ethereum,
        WalletType.polygon,
        WalletType.base,
        WalletType.arbitrum,
        WalletType.bsc,
        WalletType.robinhood,
        WalletType.nano,
        WalletType.banano,
        WalletType.solana,
        WalletType.tron,
        WalletType.zcash,
      ].contains(type);

  bool get onlyViewKeyRestore =>
      [if (FeatureFlag.hasBitcoinViewOnly) WalletType.bitcoin, WalletType.decred].contains(type);

  bool get hasWalletPassword => SettingsStoreBase.walletPasswordDirectInput;

  bool isPolyseed(String seed) =>
      [WalletType.monero, WalletType.wownero].contains(type) &&
      (Polyseed.isValidSeed(seed) || (seed.split(" ").length == 14));

  Future<bool> nameExists(String name) => _walletCreationService.exists(name);

  Future<bool> typeExists(WalletType type) => _walletCreationService.typeExists(type);

  DerivationInfo? getCommonRestoreDerivation() {
    final seedSettings = _seedSettingsCubit.state;
    final useElectrum = seedSettings.bitcoinSeedType.type == DerivationType.electrum;
    final useNanoStandard = seedSettings.nanoSeedType.type == DerivationType.nano;
    switch (type) {
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

  DerivationInfo _getDefaultCreateDerivation() {
    final seedSettings = _seedSettingsCubit.state;
    final useBip39ForBitcoin = seedSettings.bitcoinSeedType.type == DerivationType.bip39;
    final useBip39ForNano = seedSettings.nanoSeedType.type == DerivationType.bip39;
    switch (type) {
      case WalletType.nano:
        return DerivationInfo(
          derivationType: useBip39ForNano ? DerivationType.bip39 : DerivationType.nano,
        );
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

  void setMode(WalletRestoreMode mode) {
    if (mode == state.mode) {
      return;
    }
    _emitIfOpen(
      state.copyWith(
        mode: mode,
        isButtonEnabled: false,
        walletPassword: () => null,
        repeatedWalletPassword: () => null,
      ),
    );
  }

  void setHasPassphrase(bool value) => _emitIfOpen(state.copyWith(hasPassphrase: value));

  void setButtonEnabled(bool value) => _emitIfOpen(state.copyWith(isButtonEnabled: value));

  void setWalletPassword(String? value) => _emitIfOpen(state.copyWith(walletPassword: () => value));

  void setRepeatedWalletPassword(String? value) =>
      _emitIfOpen(state.copyWith(repeatedWalletPassword: () => value));

  void toggleUseTestnet(bool? value) =>
      _emitIfOpen(state.copyWith(useTestnet: value ?? !state.useTestnet));

  void setZcashNetwork(int network) => _emitIfOpen(state.copyWith(zcashNetwork: network));

  void startExecuting() {
    if (!state.isExecuting) {
      _emitIfOpen(state.copyWith(executionState: IsExecutingState()));
    }
  }

  void resetExecutionState() =>
      _emitIfOpen(state.copyWith(executionState: InitialExecutionState()));

  Future<void> restore(Map<String, dynamic> options) async {
    if (_isRestoring) {
      printV("restore already in progress");
      return;
    }
    _isRestoring = true;
    try {
      await _restore(options);
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> _restore(Map<String, dynamic> options) async {
    try {
      startExecuting();

      var name = options["name"] as String? ?? "";
      if (name.isEmpty) {
        name = await generateName();
      }

      if (hasWalletPassword && (state.walletPassword?.isEmpty ?? true)) {
        throw WalletCreationException(S.current.wallet_password_is_empty);
      }

      if (hasWalletPassword && state.walletPassword != state.repeatedWalletPassword) {
        throw WalletCreationException(S.current.repeated_password_is_incorrect);
      }

      await _walletCreationService.checkIfExists(name);
      final dirPath = await pathForWalletDir(name: name, type: type);
      final path = await pathForWallet(name: name, type: type);

      final credentials = getCredentials({...options, "name": name});

      final derivation = (credentials.derivationInfo?.derivationPath ?? "").isEmpty
          ? _getDefaultCreateDerivation()
          : credentials.derivationInfo!;

      final derivationId = await derivation.save();
      credentials.derivationInfo = derivation;

      credentials.walletInfo = WalletInfo.external(
        id: WalletBase.idFor(name, type),
        name: name,
        type: type,
        isRecovery: true,
        restoreHeight: credentials.height ?? 0,
        date: DateTime.now(),
        path: path,
        dirPath: dirPath,
        address: "",
        showIntroCakePayCard:
            (!await _walletCreationService.typeExists(type)) && type != WalletType.haven,
        derivationInfoId: derivationId,
        hardwareWalletType: credentials.hardwareWalletType,
      );

      printV("derivationInfo: ${(await credentials.walletInfo!.getDerivationInfo()).toJson()}");

      final wallet = state.mode == WalletRestoreMode.keys
          ? await _walletCreationService.restoreFromKeys(credentials, isTestnet: state.useTestnet)
          : await _walletCreationService.restoreFromSeed(credentials, isTestnet: state.useTestnet);

      credentials.walletInfo!.isNonSeedWallet = wallet.seed == null;
      credentials.walletInfo!.hashedWalletIdentifier = createHashedWalletIdentifier(wallet);
      credentials.walletInfo!.address = wallet.walletAddresses.address;
      await credentials.walletInfo!.save();
      await wallet.save();
      await _appStore.changeCurrentWallet(wallet);
      _appStore.authenticationStore.allowedCreate();

      _emitIfOpen(state.copyWith(executionState: ExecutedSuccessfullyState()));
    } catch (e, s) {
      printV("error: $e");
      printV("stack: $s");
      final message = e is RestoreFromSeedException ? e.message : e.toString();
      _emitIfOpen(state.copyWith(executionState: FailureState(message)));
    }
  }

  WalletCredentials getCredentials(Map<String, dynamic> options) {
    final password = state.walletPassword ?? generateWalletPassword();
    final passphrase = options["passphrase"] as String?;
    final height = options["height"] as int? ?? 0;
    final name = options["name"] as String;
    final derivationInfo = options["derivationInfo"] as DerivationInfo?;

    if (state.mode == WalletRestoreMode.seed) {
      final seed = options["seed"] as String;
      switch (type) {
        case WalletType.monero:
          return monero!.createMoneroRestoreWalletFromSeedCredentials(
            name: name,
            height: height,
            mnemonic: seed,
            password: password,
            passphrase: passphrase ?? "",
          );
        case WalletType.bitcoin:
        case WalletType.litecoin:
          return bitcoin!.createBitcoinRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
            derivationType: derivationInfo!.derivationType!,
            derivationPath: derivationInfo.derivationPath!,
          );
        case WalletType.bitcoinCash:
          return bitcoinCash!.createBitcoinCashRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
          );
        case WalletType.dogecoin:
          return dogecoin!.createDogeCoinRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
          );
        case WalletType.nano:
        case WalletType.banano:
          return nano!.createNanoRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            derivationType: derivationInfo!.derivationType!,
            passphrase: passphrase,
          );
        case WalletType.ethereum:
        case WalletType.polygon:
        case WalletType.base:
        case WalletType.arbitrum:
        case WalletType.bsc:
        case WalletType.robinhood:
          return evm!.createEVMRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
          );
        case WalletType.solana:
          return solana!.createSolanaRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
          );
        case WalletType.tron:
          return tron!.createTronRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
          );
        case WalletType.wownero:
          return wownero!.createWowneroRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase ?? "",
            height: height,
          );
        case WalletType.zano:
          final credentials = zano!.createZanoRestoreWalletFromSeedCredentials(
            name: name,
            password: password,
            height: height,
            passphrase: passphrase ?? "",
            mnemonic: seed,
          );
          credentials.derivationInfo = derivationInfo;
          return credentials;
        case WalletType.decred:
          return decred!.createDecredRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
          );
        case WalletType.zcash:
          return zcash!.createZcashRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
            height: height,
            network: state.zcashNetwork,
          );
        case WalletType.none:
        case WalletType.haven:
          break;
      }
    }

    if (state.mode == WalletRestoreMode.keys) {
      final viewKey = options["viewKey"] as String?;
      final spendKey = options["spendKey"] as String?;
      final scanSecret = options["scanSecret"] as String?;
      final spendPubkey = options["spendPubkey"] as String?;
      final address = options["address"] as String?;

      switch (type) {
        case WalletType.bitcoin:
          return bitcoin!.createBitcoinWalletFromKeys(
            name: name,
            password: password,
            xpub: viewKey!,
            hardwareWalletType: hardwareWalletType,
          );
        case WalletType.litecoin:
          return bitcoin!.createLitecoinWalletFromKeys(
            name: name,
            password: password,
            xpub: viewKey!,
            scanSecret: scanSecret!,
            spendPubkey: spendPubkey!,
            hardwareWalletType: hardwareWalletType,
          );
        case WalletType.monero:
          return monero!.createMoneroRestoreWalletFromKeysCredentials(
            name: name,
            height: height,
            spendKey: spendKey!,
            viewKey: viewKey!,
            address: address!,
            password: password,
            language: "English",
            hardwareWalletType: hardwareWalletType,
          );
        case WalletType.nano:
          return nano!.createNanoRestoreWalletFromKeysCredentials(
            name: name,
            password: password,
            seedKey: options["private_key"] as String,
            derivationType: derivationInfo!.derivationType!,
          );
        case WalletType.ethereum:
        case WalletType.polygon:
        case WalletType.base:
        case WalletType.arbitrum:
        case WalletType.bsc:
        case WalletType.robinhood:
          return evm!.createEVMRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options["private_key"] as String,
          );
        case WalletType.solana:
          return solana!.createSolanaRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options["private_key"] as String,
          );
        case WalletType.tron:
          return tron!.createTronRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options["private_key"] as String,
          );
        case WalletType.wownero:
          return wownero!.createWowneroRestoreWalletFromKeysCredentials(
            name: name,
            height: height,
            spendKey: spendKey!,
            viewKey: viewKey!,
            address: address!,
            password: password,
            language: "English",
          );
        case WalletType.decred:
          return decred!.createDecredRestoreWalletFromPubkeyCredentials(
            name: name,
            password: password,
            pubkey: viewKey!,
          );
        case WalletType.zcash:
          return zcash!.createZcashRestoreWalletFromPrivateKey(
            name: name,
            privateKey: options["private_key"] as String,
            password: password,
            height: height,
          );
        default:
          break;
      }
    }

    throw BadWalletTypeException("Unexpected type: ${type.toString()}", type);
  }

  Future<List<DerivationInfo>> getDerivationInfo(Map<String, dynamic> credentials) async {
    final walletType = credentials["walletType"] as WalletType;

    int? chainId;
    if (isEVMCompatibleChain(walletType)) {
      final currentWallet = _appStore.wallet;
      if (currentWallet != null) {
        chainId = evm!.getSelectedChainId(currentWallet);
      }
      chainId ??= evm!.getChainIdByWalletType(walletType);
    }

    final node = _appStore.settingsStore.getCurrentNode(walletType, chainId: chainId);

    switch (walletType) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
        final mnemonic = credentials["seed"] as String?;
        if (mnemonic == null) {
          break;
        }
        return bitcoin!.getDerivationsFromMnemonic(
          mnemonic: mnemonic,
          node: node,
          passphrase: credentials["passphrase"] as String?,
        );
      case WalletType.nano:
        return nanoUtil!.getDerivationsFromMnemonic(
          mnemonic: credentials["seed"] as String?,
          seedKey: credentials["private_key"] as String?,
          node: node,
        );
      case WalletType.zano:
        final mnemonic = (credentials["seed"] as String?)?.trim() ?? "";
        if (mnemonic.isEmpty) {
          break;
        }
        return [
          DerivationInfo(
            derivationType:
                zano!.isBip39Seed(mnemonic) ? DerivationType.bip39 : DerivationType.unknown,
          ),
        ];
      default:
        break;
    }
    return [];
  }

  void _emitIfOpen(WalletRestoreState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }
}
