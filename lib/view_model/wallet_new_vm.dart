import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'advanced_privacy_settings_view_model.dart';

import '../polygon/polygon.dart';

part 'wallet_new_vm.g.dart';

class WalletNewVM = WalletNewVMBase with _$WalletNewVM;

abstract class WalletNewVMBase extends WalletCreationVM with Store {
  WalletNewVMBase(AppStore appStore, WalletCreationService walletCreationService,
      Box<WalletInfo> walletInfoSource, this.advancedPrivacySettingsViewModel,
      {required WalletType type})
      : selectedMnemonicLanguage = '',
        super(appStore, walletInfoSource, walletCreationService, type: type, isRecovery: false);

  final AdvancedPrivacySettingsViewModel advancedPrivacySettingsViewModel;

  @observable
  String selectedMnemonicLanguage;

  bool get hasLanguageSelector => type == WalletType.monero || type == WalletType.haven;

  int get seedPhraseWordsLength {
    switch (type) {
      case WalletType.monero:
        if (advancedPrivacySettingsViewModel.isPolySeed) {
          return 16;
        }
        return 25;
      case WalletType.solana:
      case WalletType.polygon:
      case WalletType.ethereum:
      case WalletType.bitcoinCash:
        return advancedPrivacySettingsViewModel.seedPhraseLength.value;
      default:
        return 24;
    }
  }

  bool get hasSeedType => type == WalletType.monero;

  @override
  WalletCredentials getCredentials(dynamic _options) {
    final options = _options as List<dynamic>?;
    switch (type) {
      case WalletType.monero:
        return monero!.createMoneroNewWalletCredentials(
            name: name, language: options!.first as String, isPolyseed: options.last as bool);
      case WalletType.bitcoin:
        return bitcoin!.createBitcoinNewWalletCredentials(name: name);
      case WalletType.litecoin:
        return bitcoin!.createBitcoinNewWalletCredentials(name: name);
      case WalletType.haven:
        return haven!
            .createHavenNewWalletCredentials(name: name, language: options!.first as String);
      case WalletType.ethereum:
        return ethereum!.createEthereumNewWalletCredentials(name: name);
      case WalletType.bitcoinCash:
        return bitcoinCash!.createBitcoinCashNewWalletCredentials(name: name);
      case WalletType.nano:
        return nano!.createNanoNewWalletCredentials(name: name);
      case WalletType.polygon:
        return polygon!.createPolygonNewWalletCredentials(name: name);
      case WalletType.solana:
        return solana!.createSolanaNewWalletCredentials(name: name);
      default:
        throw Exception('Unexpected type: ${type.toString()}');
    }
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    walletCreationService.changeWalletType(type: type);
    return walletCreationService.create(credentials, isTestnet: useTestnet);
  }
}
