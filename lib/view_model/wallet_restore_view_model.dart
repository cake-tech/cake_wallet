import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';

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
    _walletCreationService.changeWalletType(type: WalletType.monero);
  }

  @observable
  WalletRestoreMode mode;

  final WalletCreationService _walletCreationService;

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword(type);
    final height = options['height'] as int;
    name = Uuid().v4().substring(0, 10);

    if (mode == WalletRestoreMode.seed) {
      final seed = options['seed'] as String;

      return MoneroRestoreWalletFromSeedCredentials(
          name: name, height: height, mnemonic: seed, password: password);
    }

    if (mode == WalletRestoreMode.keys) {
      final viewKey = options['viewKey'] as String;
      final spendKey = options['spendKey'] as String;
      final address = options['address'] as String;

      return MoneroRestoreWalletFromKeysCredentials(
          name: name,
          height: height,
          spendKey: spendKey,
          viewKey: viewKey,
          address: address,
          password: password);
    }

    return null;
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    if (mode == WalletRestoreMode.keys) {
      return _walletCreationService.restoreFromKeys(credentials);
    }

    return _walletCreationService.restoreFromSeed(credentials);
  }
}
