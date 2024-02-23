import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/solana/solana.dart';
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
      Box<WalletInfo> walletInfoSource, WalletType type)
      : height = 0,
        viewKey = '',
        spendKey = '',
        wif = '',
        address = '',
        super(appStore, walletInfoSource, walletCreationService,
            type: type, isRecovery: true);

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

  @override
  WalletCredentials getCredentialsFromRestoredWallet(dynamic options, RestoredWallet restoreWallet) {
    final password = generateWalletPassword();

    switch (restoreWallet.restoreMode) {
      case WalletRestoreMode.keys:
        switch (restoreWallet.type) {
          case WalletType.monero:
            return monero!.createMoneroRestoreWalletFromKeysCredentials(
                name: name,
                password: password,
                language: 'English',
                address: restoreWallet.address ?? '',
                viewKey: restoreWallet.viewKey ?? '',
                spendKey: restoreWallet.spendKey ?? '',
                height: restoreWallet.height ?? 0);
          case WalletType.bitcoin:
          case WalletType.litecoin:
            return bitcoin!.createBitcoinRestoreWalletFromWIFCredentials(
                name: name, password: password, wif: wif);
          case WalletType.ethereum:
            return ethereum!.createEthereumRestoreWalletFromPrivateKey(
                name: name, password: password, privateKey: restoreWallet.privateKey!);
          case WalletType.polygon:
            return polygon!.createPolygonRestoreWalletFromPrivateKey(
                name: name, password: password, privateKey: restoreWallet.privateKey!);
          case WalletType.solana:
            return solana!.createSolanaRestoreWalletFromPrivateKey(
                name: name, password: password, privateKey: restoreWallet.privateKey!);
          default:
            throw Exception('Unexpected type: ${restoreWallet.type.toString()}');
        }
      case WalletRestoreMode.seed:
        switch (restoreWallet.type) {
          case WalletType.monero:
            return monero!.createMoneroRestoreWalletFromSeedCredentials(
                name: name,
                height: restoreWallet.height ?? 0,
                mnemonic: restoreWallet.mnemonicSeed ?? '',
                password: password);
          case WalletType.bitcoin:
          case WalletType.litecoin:
            return bitcoin!.createBitcoinRestoreWalletFromSeedCredentials(
                name: name, mnemonic: restoreWallet.mnemonicSeed ?? '', password: password);
          case WalletType.bitcoinCash:
            return bitcoinCash!.createBitcoinCashRestoreWalletFromSeedCredentials(
                name: name, mnemonic: restoreWallet.mnemonicSeed ?? '', password: password);
          case WalletType.ethereum:
            return ethereum!.createEthereumRestoreWalletFromSeedCredentials(
                name: name, mnemonic: restoreWallet.mnemonicSeed ?? '', password: password);
          case WalletType.nano:
            return nano!.createNanoRestoreWalletFromSeedCredentials(
                name: name, mnemonic: restoreWallet.mnemonicSeed ?? '', password: password);
          case WalletType.polygon:
            return polygon!.createPolygonRestoreWalletFromSeedCredentials(
                name: name, mnemonic: restoreWallet.mnemonicSeed ?? '', password: password);
          case WalletType.solana:
            return solana!.createSolanaRestoreWalletFromSeedCredentials(
                name: name, mnemonic: restoreWallet.mnemonicSeed ?? '', password: password);
          default:
            throw Exception('Unexpected type: ${type.toString()}');
        }
      default:
        throw Exception('Unexpected type: ${type.toString()}');
    }
  }

  @override
  Future<WalletBase> processFromRestoredWallet(WalletCredentials credentials, RestoredWallet restoreWallet) async {
    try {
      switch (restoreWallet.restoreMode) {
        case WalletRestoreMode.keys:
          return walletCreationService.restoreFromKeys(credentials);
        case WalletRestoreMode.seed:
          return walletCreationService.restoreFromSeed(credentials);
        default:
          throw Exception('Unexpected restore mode: ${restoreWallet.restoreMode.toString()}');
      }
    } catch (e) {
      throw Exception('Unexpected restore mode: ${e.toString()}');
    }
  }
}
