import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';

part 'wallet_restoration_from_keys_vm.g.dart';

class WalletRestorationFromKeysVM = WalletRestorationFromKeysVMBase
    with _$WalletRestorationFromKeysVM;

abstract class WalletRestorationFromKeysVMBase extends WalletCreationVM
    with Store {
  WalletRestorationFromKeysVMBase(this._walletCreationService, Box<WalletInfo> walletInfoSource,
      {@required WalletType type, @required this.language})
      : super(walletInfoSource, type: type, isRecovery: true);

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
  final WalletCreationService _walletCreationService;

  @override
  WalletCredentials getCredentials(dynamic options) {
    final password = generateWalletPassword(type);

    switch (type) {
      case WalletType.monero:
        return MoneroRestoreWalletFromKeysCredentials(
          name: name, password: password, language: language, address: address,
            viewKey: viewKey, spendKey: spendKey, height: height);
      case WalletType.bitcoin:
        return BitcoinRestoreWalletFromWIFCredentials(
          name: name, password: password, wif: wif);
      default:
        return null;
    }
  }

  @override
  Future<void> process(WalletCredentials credentials) async =>
      _walletCreationService.restoreFromKeys(credentials);
}
