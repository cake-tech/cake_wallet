import 'package:cake_wallet/core/wallet_creation_state.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/core/bitcoin_wallet_list_service.dart';
import 'package:cake_wallet/core/monero_wallet_list_service.dart';
import 'package:cake_wallet/core/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

part 'wallet_creation_service.g.dart';

class WalletCreationService = WalletCreationServiceBase
    with _$WalletCreationService;

abstract class WalletCreationServiceBase with Store {
  @observable
  WalletCreationState state;

  WalletType type;

  WalletListService _service;

  void changeWalletType({@required WalletType type}) {
    this.type = type;

    switch (type) {
      case WalletType.monero:
        _service = MoneroWalletListService();
        break;
      case WalletType.bitcoin:
        _service = BitcoinWalletListService();
        break;
      default:
        break;
    }
  }

  Future<void> create(WalletCredentials credentials) async {
    try {
      state = WalletCreating();
      await _service.create(credentials);
      state = WalletCreatedSuccessfully();
    } catch (e) {
      state = WalletCreationFailure(error: e.toString());
    }
  }

  Future<void> restoreFromKeys(WalletCredentials credentials) async {
    try {
      state = WalletCreating();
      await _service.restoreFromKeys(credentials);
      state = WalletCreatedSuccessfully();
    } catch (e) {
      state = WalletCreationFailure(error: e.toString());
    }
  }

  Future<void> restoreFromSeed(WalletCredentials credentials) async {
    try {
      state = WalletCreating();
      await _service.restoreFromSeed(credentials);
      state = WalletCreatedSuccessfully();
    } catch (e) {
      state = WalletCreationFailure(error: e.toString());
    }
  }
}
