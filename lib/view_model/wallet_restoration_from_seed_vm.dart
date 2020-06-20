import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';

part 'wallet_restoration_from_seed_vm.g.dart';

class WalletRestorationFromSeedVM = WalletRestorationFromSeedVMBase
    with _$WalletRestorationFromSeedVM;

abstract class WalletRestorationFromSeedVMBase extends WalletCreationVM
    with Store {
  WalletRestorationFromSeedVMBase(this._walletCreationService,
      {@required WalletType type, @required this.language, this.seed})
      : super(type: type);

  @observable
  String seed;

  @observable
  int height;

  bool get hasRestorationHeight => type == WalletType.monero;

  final String language;
  final WalletCreationService _walletCreationService;

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword(type);

    switch (type) {
      case WalletType.monero:
        return MoneroRestoreWalletFromSeedCredentials(
            name: name, height: height, mnemonic: seed, password: password);
      case WalletType.bitcoin:
        return BitcoinRestoreWalletFromSeedCredentials(
            name: name, mnemonic: seed, password: password);
      default:
        return null;
    }
  }

  @override
  Future<void> process(WalletCredentials credentials) async =>
      _walletCreationService.restoreFromSeed(credentials);
}
