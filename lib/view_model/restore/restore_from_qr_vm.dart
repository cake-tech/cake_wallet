import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cw_core/wallet_info.dart';

part 'restore_from_qr_vm.g.dart';

class WalletRestorationFromQRVM = WalletRestorationFromQRVMBase with _$WalletRestorationFromQRVM;

abstract class WalletRestorationFromQRVMBase extends WalletCreationVM with Store {
  WalletRestorationFromQRVMBase(AppStore appStore, WalletCreationService walletCreationService,
      Box<WalletInfo> walletInfoSource,
      {required this.wallet, required this.language})
      : height = 0,
        viewKey = '',
        spendKey = '',
        wif = '',
        address = '',
        super(appStore, walletInfoSource, walletCreationService,
            type: wallet.type, isRecovery: true);

  @observable
  int height;

  @observable
  String viewKey;

  @observable
  String spendKey;

  @observable
  String wif;

  @observable
  String address;

  bool get hasRestorationHeight => type == WalletType.monero;

  final String language;

  final RestoredWallet wallet;

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword();

    switch (wallet.restoreMode) {
      case WalletRestoreMode.keys:
        return monero!.createMoneroRestoreWalletFromKeysCredentials(
            name: name,
            password: password,
            language: language,
            address: wallet.address,
            viewKey: wallet.viewKey ?? '',
            spendKey: wallet.spendKey ?? '',
            height: wallet.height ?? 0);
      case WalletRestoreMode.seed:
        return monero!.createMoneroRestoreWalletFromSeedCredentials(
            name: name,
            height: wallet.height ?? 0,
            mnemonic: wallet.mnemonicSeed ?? '',
            password: password);
      default:
        throw Exception('Unexpected type: ${type.toString()}');
    }
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {

    try{
      switch (wallet.restoreMode) {
        case WalletRestoreMode.keys:
          return walletCreationService.restoreFromKeys(credentials);
        case WalletRestoreMode.seed:
          return walletCreationService.restoreFromSeed(credentials);
        default:
          throw Exception('Unexpected restore mode: ${wallet.restoreMode.toString()}');
      }
    } catch (e){
      throw Exception('Unexpected restore mode: ${e.toString()}');
    }
  }

  }

