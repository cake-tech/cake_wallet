import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cw_bitcoin/bitcoin_wallet_service.dart';
import 'package:cw_nano/nano_wallet.dart';
import 'package:cw_nano/nano_wallet_service.dart';
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
      : availableModes = (type == WalletType.monero || type == WalletType.haven)
            ? [WalletRestoreMode.seed, WalletRestoreMode.keys, WalletRestoreMode.txids]
            : (type == WalletType.nano || type == WalletType.banano)
                ? [WalletRestoreMode.seed, WalletRestoreMode.keys]
                : [WalletRestoreMode.seed],
        hasSeedLanguageSelector = type == WalletType.monero || type == WalletType.haven,
        hasBlockchainHeightLanguageSelector = type == WalletType.monero || type == WalletType.haven,
        hasMultipleKeys = type != WalletType.nano || type == WalletType.banano,
        isButtonEnabled = false,
        mode = WalletRestoreMode.seed,
        super(appStore, walletInfoSource, walletCreationService, type: type, isRecovery: true) {
    isButtonEnabled = !hasSeedLanguageSelector && !hasBlockchainHeightLanguageSelector;
    walletCreationService.changeWalletType(type: type);
  }

  static const moneroSeedMnemonicLength = 25;
  static const electrumSeedMnemonicLength = 24;
  static const electrumShortSeedMnemonicLength = 12;

  final List<WalletRestoreMode> availableModes;
  final bool hasSeedLanguageSelector;
  final bool hasBlockchainHeightLanguageSelector;
  final bool hasMultipleKeys;

  @observable
  WalletRestoreMode mode;

  @observable
  bool isButtonEnabled;

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword();
    final height = options['height'] as int? ?? 0;
    name = options['name'] as String;

    if (mode == WalletRestoreMode.seed) {
      final seed = options['seed'] as String;
      switch (type) {
        case WalletType.monero:
          return monero!.createMoneroRestoreWalletFromSeedCredentials(
              name: name, height: height, mnemonic: seed, password: password);
        case WalletType.bitcoin:
          return bitcoin!.createBitcoinRestoreWalletFromSeedCredentials(
              name: name, mnemonic: seed, password: password);
        case WalletType.litecoin:
          return bitcoin!.createBitcoinRestoreWalletFromSeedCredentials(
              name: name, mnemonic: seed, password: password);
        case WalletType.haven:
          return haven!.createHavenRestoreWalletFromSeedCredentials(
              name: name, height: height, mnemonic: seed, password: password);
        case WalletType.ethereum:
          return ethereum!.createEthereumRestoreWalletFromSeedCredentials(
              name: name, mnemonic: seed, password: password);
        case WalletType.nano:
          return nano!.createNanoRestoreWalletFromSeedCredentials(
            name: name,
            mnemonic: seed,
            password: password,
            derivationType: options["derivationType"] as DerivationType,
          );
        default:
          break;
      }
    }

    if (mode == WalletRestoreMode.keys) {
      if (hasMultipleKeys) {
        final viewKey = options['viewKey'] as String;
        final spendKey = options['spendKey'] as String;
        final address = options['address'] as String;

        if (type == WalletType.monero) {
          return monero!.createMoneroRestoreWalletFromKeysCredentials(
              name: name,
              height: height,
              spendKey: spendKey,
              viewKey: viewKey,
              address: address,
              password: password,
              language: 'English');
        }

        if (type == WalletType.haven) {
          return haven!.createHavenRestoreWalletFromKeysCredentials(
              name: name,
              height: height,
              spendKey: spendKey,
              viewKey: viewKey,
              address: address,
              password: password,
              language: 'English');
        }
      } else {
        if (type == WalletType.nano) {
          return nano!.createNanoRestoreWalletFromKeysCredentials(
            name: name,
            password: password,
            seedKey: options['seedKey'] as String,
            derivationType: options["derivationType"] as DerivationType,
          );
        }
      }
    }

    throw Exception('Unexpected type: ${type.toString()}');
  }

  @override
  Future<List<DerivationType>> getDerivationType(dynamic options) async {
    final seedKey = options['seedKey'] as String?;
    final mnemonic = options['seed'] as String?;
    WalletType walletType = options['walletType'] as WalletType;
    var appStore = getIt.get<AppStore>();
    var node = appStore.settingsStore.getCurrentNode(walletType);
    
    switch (type) {
      case WalletType.bitcoin:
        return BitcoinWalletService.compareDerivationMethods(mnemonic: mnemonic, node: node);
      // case WalletType.litecoin:
      //   return bitcoin!.createBitcoinRestoreWalletFromSeedCredentials(
      //       name: name, mnemonic: seed, password: password);
      case WalletType.nano:
        return await NanoWalletService.compareDerivationMethods(
          mnemonic: mnemonic,
          seedKey: seedKey,
          node: node,
        );
      default:
        break;
    }

    // throw Exception('Unexpected type: ${type.toString()}');
    return [DerivationType.def];
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    if (mode == WalletRestoreMode.keys) {
      return walletCreationService.restoreFromKeys(credentials);
    }

    return walletCreationService.restoreFromSeed(credentials);
  }
}
