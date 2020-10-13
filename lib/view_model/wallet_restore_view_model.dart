import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';

part 'wallet_restore_view_model.g.dart';

enum WalletRestoreMode { seed, keys }

class WalletRestoreViewModel = WalletRestoreViewModelBase
    with _$WalletRestoreViewModel;

abstract class WalletRestoreViewModelBase extends WalletCreationVM with Store {
  WalletRestoreViewModelBase(AppStore appStore, this._walletCreationService,
      Box<WalletInfo> walletInfoSource,
      {@required WalletType type})
      : super(appStore, walletInfoSource, type: type, isRecovery: true) {
    mode = WalletRestoreMode.seed;
  }

  @observable
  WalletRestoreMode mode;

  final WalletCreationService _walletCreationService;

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword(type);

    // switch (type) {
    //   case WalletType.monero:
    //     return MoneroRestoreWalletFromSeedCredentials(
    //         name: name, height: height, mnemonic: seed, password: password);
    //   case WalletType.bitcoin:
    //     return BitcoinRestoreWalletFromSeedCredentials(
    //         name: name, mnemonic: seed, password: password);
    //   default:
    //     return null;
    // }

    return null;
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async =>
      _walletCreationService.restoreFromSeed(credentials);
}
