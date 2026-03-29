import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/dogecoin/dogecoin.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cw_core/generate_name.dart';
import 'package:cake_wallet/entities/hash_wallet_identifier.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cake_wallet/view_model/seed_settings_view_model.dart';
import 'package:cw_core/exceptions.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:polyseed/polyseed.dart';

part 'wallet_creation_vm.g.dart';

class WalletCreationVM = WalletCreationVMBase with _$WalletCreationVM;

abstract class WalletCreationVMBase with Store {
  WalletCreationVMBase(this._appStore, this.walletCreationService,
      this.seedSettingsViewModel,
      {required this.type, required this.isRecovery})
      : state = InitialExecutionState(),
        name = '';

  @observable
  bool _useTestnet = false;

  @computed
  bool get useTestnet => _useTestnet;

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

  bool isPolyseed(String seed) =>
      [WalletType.monero, WalletType.wownero].contains(type) &&
      (Polyseed.isValidSeed(seed) || (seed.split(" ").length == 14));

  Future<bool> nameExists(String name) => walletCreationService.exists(name);

  Future<bool> typeExists(WalletType type) => walletCreationService.typeExists(type);

  bool _isCreating = false;
  Future<void> create({dynamic options}) async {
    try {
      if (_isCreating) {
        printV("not creating because we don't feel like doing so");
        return;
      }
      _isCreating = true;
      await _create(options: options);
    } finally {
      _isCreating = false;
    }
  }

  Future<void> _create({dynamic options}) async {
    final type = this.type;
    try {

      state = IsExecutingState();
      if (name.isEmpty) {
        name = await generateName();
      }

      if (hasWalletPassword && (walletPassword?.isEmpty ?? true)) {
        throw Exception(S.current.wallet_password_is_empty);
      }

      if (hasWalletPassword && walletPassword != repeatedWalletPassword) {
        throw Exception(S.current.repeated_password_is_incorrect);
      }

      await walletCreationService.checkIfExists(name);
      final dirPath = await pathForWalletDir(name: name, type: type);
      final path = await pathForWallet(name: name, type: type);

      final credentials = getCredentials(options);

      final di = ((credentials.derivationInfo?.derivationPath??"") == "") 
        ? getDefaultCreateDerivation()
        : credentials.derivationInfo;

      final diId = await di!.save();
      credentials.derivationInfo = di;

      credentials.walletInfo = WalletInfo.external(
        id: WalletBase.idFor(name, type),
        name: name,
        type: type,
        isRecovery: isRecovery,
        restoreHeight: credentials.height ?? 0,
        date: DateTime.now(),
        path: path,
        dirPath: dirPath,
        address: '',
        showIntroCakePayCard: (!await walletCreationService.typeExists(type)) && type != WalletType.haven,
        derivationInfoId: diId,
        hardwareWalletType: credentials.hardwareWalletType,
      );

      printV("derivationInfo: ${(await credentials.walletInfo!.getDerivationInfo()).toJson()}");
      final wallet = await process(credentials);

      final isNonSeedWallet = isRecovery ? wallet.seed == null : false;
      credentials.walletInfo!.isNonSeedWallet = isNonSeedWallet;
      credentials.walletInfo!.hashedWalletIdentifier = createHashedWalletIdentifier(wallet);
      credentials.walletInfo!.address = wallet.walletAddresses.address;
      await credentials.walletInfo!.save();
      await wallet.save();
      await _appStore.changeCurrentWallet(wallet);
      _appStore.authenticationStore.allowedCreate();
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

  WalletCredentials getCredentials(dynamic _options) {
    final options = _options as List<dynamic>?;
    final passphrase = seedSettingsViewModel.passphrase;
    seedSettingsViewModel.setPassphrase(null);

    switch (type) {
      case WalletType.monero:
        return monero!.createMoneroNewWalletCredentials(
          name: name,
          language: options!.first as String,
          password: walletPassword,
          passphrase: passphrase,
          seedType: MoneroSeedType.polyseed.raw,
        );
      case WalletType.bitcoin:
      case WalletType.litecoin:
        return bitcoin!.createBitcoinNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        return evm!.createEVMNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.bitcoinCash:
        return bitcoinCash!.createBitcoinCashNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.dogecoin:
        return dogecoin!.createDogeCoinNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.nano:
      case WalletType.banano:
        return nano!.createNanoNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );

      case WalletType.solana:
        return solana!.createSolanaNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.tron:
        return tron!.createTronNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.wownero:
      case WalletType.zano:
        return zano!.createZanoNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.zcash:
        return zcash!.createZcashNewWalletCredentials(
          name: name,
          password: walletPassword,
          passphrase: passphrase,
        );
      case WalletType.decred:
        return decred!.createDecredNewWalletCredentials(name: name);
      case WalletType.none:
      case WalletType.haven:
        throw Exception('Unexpected type: ${type.toString()}');
    }
  }

  Future<WalletBase> process(WalletCredentials credentials) async {
    walletCreationService.changeWalletType(type: type);
    return walletCreationService.create(credentials, isTestnet: useTestnet);
  }

  @action
  void toggleUseTestnet(bool? value) {
    _useTestnet = value ?? !_useTestnet;
  }
}
