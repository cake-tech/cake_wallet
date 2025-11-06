import 'package:cake_wallet/arbitrum/arbitrum.dart';
import 'package:cake_wallet/base/base.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/dogecoin/dogecoin.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cake_wallet/view_model/seed_settings_view_model.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'wallet_restore_view_model.g.dart';

class WalletRestoreViewModel = WalletRestoreViewModelBase with _$WalletRestoreViewModel;

abstract class WalletRestoreViewModelBase extends WalletCreationVM with Store {
  WalletRestoreViewModelBase(AppStore appStore, WalletCreationService walletCreationService,
      SeedSettingsViewModel seedSettingsViewModel,
      {required WalletType type, this.restoredWallet, this.hardwareWalletType})
      : isButtonEnabled = restoredWallet != null,
        hasPassphrase = false,
        mode = restoredWallet?.restoreMode ?? WalletRestoreMode.seed,
        super(appStore, walletCreationService, seedSettingsViewModel,
            type: type, isRecovery: true) {
    switch (type) {
      case WalletType.monero:
        availableModes = WalletRestoreMode.values;
        break;
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.wownero:
      case WalletType.haven:
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.decred:
      case WalletType.bitcoin:
        availableModes = [WalletRestoreMode.seed, WalletRestoreMode.keys];
        break;
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.zano:
      case WalletType.none:
      case WalletType.dogecoin:
        availableModes = [WalletRestoreMode.seed];
        break;
    }
    walletCreationService.changeWalletType(type: type);
    if (restoredWallet != null) {
      if(restoredWallet!.restoreMode == WalletRestoreMode.seed) {
        seedSettingsViewModel.setPassphrase(restoredWallet!.passphrase);
      }
    }
  }

  static const moneroSeedMnemonicLength = 25;
  static const decredSeedMnemonicLengths = [12, 15, 24];

  late List<WalletRestoreMode> availableModes;
  late final bool hasSeedLanguageSelector = [
    WalletType.monero,
    WalletType.haven,
    WalletType.wownero
  ].contains(type);

  late final bool hasBlockchainHeightSelector = [
    WalletType.monero,
    WalletType.haven,
    WalletType.wownero
  ].contains(type);
  
  late final bool hasRestoreFromPrivateKey = [
    WalletType.ethereum,
    WalletType.polygon,
    WalletType.base,
    WalletType.arbitrum,
    WalletType.nano,
    WalletType.banano,
    WalletType.solana,
    WalletType.tron
  ].contains(type);

  late final bool onlyViewKeyRestore = [
    if (FeatureFlag.hasBitcoinViewOnly) WalletType.bitcoin,
    WalletType.decred
  ].contains(type);

  final RestoredWallet? restoredWallet;
  final HardwareWalletType? hardwareWalletType;

  @observable
  WalletRestoreMode mode;

  @computed 
  bool get walletHasPassphrase {
    return !(type == WalletType.decred && seedSettingsViewModel.decredSeedType == DecredSeedType.decred) && 
    mode == WalletRestoreMode.seed;
  }

  @observable
  bool hasPassphrase;

  @observable
  bool isButtonEnabled;

  @override
  WalletCredentials getCredentials(Map<String, dynamic>? options) {
    final password = walletPassword ?? generateWalletPassword();
    String? passphrase = options?['passphrase'] as String?;
    final height = options?['height'] as int? ?? 0;
    name = options?['name'] as String;
    DerivationInfo? derivationInfo = options?["derivationInfo"] as DerivationInfo?;

    if (mode == WalletRestoreMode.seed) {
      final seed = options?['seed'] as String;
      switch (type) {
        case WalletType.monero:
          return monero!.createMoneroRestoreWalletFromSeedCredentials(
              name: name, height: height, mnemonic: seed, password: password, passphrase: passphrase??'');
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
        case WalletType.ethereum:
          return ethereum!.createEthereumRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
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
        case WalletType.polygon:
          return polygon!.createPolygonRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
          );
        case WalletType.base:
          return base!.createBaseRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            passphrase: passphrase,
          );
        case WalletType.arbitrum:
          return arbitrum!.createArbitrumRestoreWalletFromSeedCredentials(
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
            passphrase: passphrase??'',
            height: height,
          );
        case WalletType.zano:
          return zano!.createZanoRestoreWalletFromSeedCredentials(
            name: name,
            password: password,
            height: height,
            passphrase: passphrase??'',
            mnemonic: seed,
          );
        case WalletType.decred:
          return decred!.createDecredRestoreWalletFromSeedCredentials(
              name: name,
              mnemonic: seed,
              password: password,
              passphrase: passphrase??'',
          );
        case WalletType.none:
        case WalletType.haven:
          break;
      }
    }

    if (mode == WalletRestoreMode.keys) {
      final viewKey = options?['viewKey'] as String?;
      final spendKey = options?['spendKey'] as String?;
      final address = options?['address'] as String?;

      switch (type) {
        case WalletType.bitcoin:
          return bitcoin!.createBitcoinWalletFromKeys(
            name: name,
            password: password,
            xpub: viewKey!,
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
            language: 'English',
          );

        case WalletType.ethereum:
          return ethereum!.createEthereumRestoreWalletFromPrivateKey(
            name: name,
            privateKey: options?['private_key'] as String,
            password: password,
          );

        case WalletType.nano:
          return nano!.createNanoRestoreWalletFromKeysCredentials(
            name: name,
            password: password,
            seedKey: options?['private_key'] as String,
            derivationType: derivationInfo!.derivationType!,
          );
        case WalletType.polygon:
          return polygon!.createPolygonRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options?['private_key'] as String,
          );
        case WalletType.base:
          return base!.createBaseRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options?['private_key'] as String,
          );
        case WalletType.arbitrum:
          return arbitrum!.createArbitrumRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options?['private_key'] as String,
          );
        case WalletType.solana:
          return solana!.createSolanaRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options?['private_key'] as String,
          );
        case WalletType.tron:
          return tron!.createTronRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options?['private_key'] as String,
          );
        case WalletType.wownero:
          return wownero!.createWowneroRestoreWalletFromKeysCredentials(
            name: name,
            height: height,
            spendKey: spendKey!,
            viewKey: viewKey!,
            address: address!,
            password: password,
            language: 'English',
          );
        case WalletType.decred:
          return decred!.createDecredRestoreWalletFromPubkeyCredentials(
            name: name,
            password: password,
            pubkey: viewKey!,
          );
        default:
          break;
      }
    }

    throw Exception('Unexpected type: ${type.toString()}');
  }

  Future<List<DerivationInfo>> getDerivationInfo(dynamic credentials) async {
    var list = <DerivationInfo>[];
    var walletType = credentials["walletType"] as WalletType;
    var appStore = getIt.get<AppStore>();
    var node = appStore.settingsStore.getCurrentNode(walletType);

    switch (walletType) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
        String? mnemonic = credentials['seed'] as String?;
        String? passphrase = credentials['passphrase'] as String?;
        if (mnemonic == null) break;
        return bitcoin!.getDerivationsFromMnemonic(
          mnemonic: mnemonic,
          node: node,
          passphrase: passphrase,
        );
      case WalletType.nano:
        String? mnemonic = credentials['seed'] as String?;
        String? seedKey = credentials['private_key'] as String?;
        return nanoUtil!.getDerivationsFromMnemonic(
          mnemonic: mnemonic,
          seedKey: seedKey,
          node: node,
        );
      default:
        break;
    }
    return list;
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    if (mode == WalletRestoreMode.keys) {
      return walletCreationService.restoreFromKeys(credentials, isTestnet: useTestnet);
    }
    return walletCreationService.restoreFromSeed(credentials, isTestnet: useTestnet);
  }
}
