import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cw_core/wallet_info.dart';

part 'wallet_restoration_from_seed_vm.g.dart';

class WalletRestorationFromSeedVM = WalletRestorationFromSeedVMBase
    with _$WalletRestorationFromSeedVM;

abstract class WalletRestorationFromSeedVMBase extends WalletCreationVM
    with Store {
  WalletRestorationFromSeedVMBase(AppStore appStore,
      WalletCreationService walletCreationService, Box<WalletInfo> walletInfoSource,
      {@required WalletType type, @required this.language, this.seed})
      : super(appStore, walletInfoSource, walletCreationService, type: type, isRecovery: true);

  @observable
  String seed;

  @observable
  int height;

  bool get hasRestorationHeight => type == WalletType.monero;

  final String language;

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword();

    switch (type) {
      case WalletType.monero:
        return monero.createMoneroRestoreWalletFromSeedCredentials(
            name: name, height: height, mnemonic: seed, password: password);
      case WalletType.bitcoin:
        return bitcoin.createBitcoinRestoreWalletFromSeedCredentials(
            name: name, mnemonic: seed, password: password);
      default:
        return null;
    }
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async =>
      walletCreationService.restoreFromSeed(credentials);
}
