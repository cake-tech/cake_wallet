import 'package:flutter/foundation.dart';
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
import 'package:cake_wallet/bitcoin/bitcoin.dart';

part 'wallet_restoration_from_keys_vm.g.dart';

class WalletRestorationFromKeysVM = WalletRestorationFromKeysVMBase
    with _$WalletRestorationFromKeysVM;

abstract class WalletRestorationFromKeysVMBase extends WalletCreationVM
    with Store {
  WalletRestorationFromKeysVMBase(AppStore appStore,
      WalletCreationService walletCreationService, Box<WalletInfo> walletInfoSource,
      {@required WalletType type, @required this.language})
      : super(appStore, walletInfoSource, walletCreationService, type: type, isRecovery: true);

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

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword();

    switch (type) {
      case WalletType.monero:
        return monero.createMoneroRestoreWalletFromKeysCredentials(
            name: name,
            password: password,
            language: language,
            address: address,
            viewKey: viewKey,
            spendKey: spendKey,
            height: height);
      case WalletType.bitcoin:
        return bitcoin.createBitcoinRestoreWalletFromWIFCredentials(
            name: name, password: password, wif: wif);
      default:
        return null;
    }
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async =>
      walletCreationService.restoreFromKeys(credentials);
}
