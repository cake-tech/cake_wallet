import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';

part 'wallet_restore_view_model.g.dart';

class WalletRestoreViewModel = WalletRestoreViewModelBase with _$WalletRestoreViewModel;

abstract class WalletRestoreViewModelBase extends WalletCreationVM with Store {
  WalletRestoreViewModelBase(AppStore appStore, WalletCreationService walletCreationService,
      Box<WalletInfo> walletInfoSource,
      {required WalletType type})
      : hasSeedLanguageSelector = type == WalletType.monero || type == WalletType.haven,
        hasBlockchainHeightLanguageSelector = type == WalletType.monero || type == WalletType.haven,
        hasRestoreFromPrivateKey = type == WalletType.ethereum ||
            type == WalletType.polygon ||
            type == WalletType.nano ||
            type == WalletType.banano ||
            type == WalletType.solana,
        isButtonEnabled = false,
        mode = WalletRestoreMode.seed,
        super(appStore, walletInfoSource, walletCreationService, type: type, isRecovery: true) {
    switch (type) {
      case WalletType.monero:
      case WalletType.haven:
      case WalletType.ethereum:
      case WalletType.polygon:
        availableModes = WalletRestoreMode.values;
        break;
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.solana:
        availableModes = [WalletRestoreMode.seed, WalletRestoreMode.keys];
        break;
      default:
        availableModes = [WalletRestoreMode.seed];
        break;
    }
    isButtonEnabled = !hasSeedLanguageSelector && !hasBlockchainHeightLanguageSelector;
    walletCreationService.changeWalletType(type: type);
  }

  static const moneroSeedMnemonicLength = 25;
  static const electrumSeedMnemonicLength = 24;
  static const electrumShortSeedMnemonicLength = 12;

  late List<WalletRestoreMode> availableModes;
  final bool hasSeedLanguageSelector;
  final bool hasBlockchainHeightLanguageSelector;
  final bool hasRestoreFromPrivateKey;

  @observable
  WalletRestoreMode mode;

  @observable
  bool isButtonEnabled;

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword();
    final height = options['height'] as int? ?? 0;
    name = options['name'] as String;
    DerivationType? derivationType = options["derivationType"] as DerivationType?;
    String? derivationPath = options["derivationPath"] as String?;

    if (mode == WalletRestoreMode.seed) {
      final seed = options['seed'] as String;
      switch (type) {
        case WalletType.monero:
          return monero!.createMoneroRestoreWalletFromSeedCredentials(
              name: name, height: height, mnemonic: seed, password: password);
        case WalletType.bitcoin:
          return bitcoin!.createBitcoinRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
          );
        case WalletType.litecoin:
          return bitcoin!.createBitcoinRestoreWalletFromSeedCredentials(
              name: name, mnemonic: seed, password: password);
        case WalletType.haven:
          return haven!.createHavenRestoreWalletFromSeedCredentials(
              name: name, height: height, mnemonic: seed, password: password);
        case WalletType.ethereum:
          return ethereum!.createEthereumRestoreWalletFromSeedCredentials(
              name: name, mnemonic: seed, password: password);
        case WalletType.bitcoinCash:
          return bitcoinCash!.createBitcoinCashRestoreWalletFromSeedCredentials(
              name: name, mnemonic: seed, password: password);
        case WalletType.nano:
          return nano!.createNanoRestoreWalletFromSeedCredentials(
              name: name, mnemonic: seed, password: password, derivationType: derivationType);
        case WalletType.polygon:
          return polygon!.createPolygonRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
          );
        case WalletType.solana:
          return solana!.createSolanaRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
          );
        default:
          break;
      }
    }

    if (mode == WalletRestoreMode.keys) {
      final viewKey = options['viewKey'] as String?;
      final spendKey = options['spendKey'] as String?;
      final address = options['address'] as String?;

      switch (type) {
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

        case WalletType.haven:
          return haven!.createHavenRestoreWalletFromKeysCredentials(
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
            privateKey: options['private_key'] as String,
            password: password,
          );

        case WalletType.nano:
          return nano!.createNanoRestoreWalletFromKeysCredentials(
              name: name,
              password: password,
              seedKey: options['private_key'] as String,
              derivationType: options["derivationType"] as DerivationType);
        case WalletType.polygon:
          return polygon!.createPolygonRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options['private_key'] as String,
          );
        case WalletType.solana:
          return solana!.createSolanaRestoreWalletFromPrivateKey(
            name: name,
            password: password,
            privateKey: options['private_key'] as String,
          );
        default:
          break;
      }
    }

    throw Exception('Unexpected type: ${type.toString()}');
  }

  Future<List<DerivationType>> getDerivationTypes(dynamic options) async {
    final seedKey = options['private_key'] as String?;
    final mnemonic = options['seed'] as String?;
    WalletType walletType = options['walletType'] as WalletType;
    var appStore = getIt.get<AppStore>();
    var node = appStore.settingsStore.getCurrentNode(walletType);

    switch (type) {
      case WalletType.nano:
        return nanoUtil!
            .compareDerivationMethods(mnemonic: mnemonic, privateKey: seedKey, node: node);
      default:
        break;
    }

    // throw Exception('Unexpected type: ${type.toString()}');
    return [DerivationType.def];
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    if (mode == WalletRestoreMode.keys) {
      return walletCreationService.restoreFromKeys(credentials, isTestnet: useTestnet);
    }

    return walletCreationService.restoreFromSeed(credentials, isTestnet: useTestnet);
  }
}
