import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_state.dart';

part 'wallet_creation_vm.g.dart';

class WalletCreationVM = WalletCreationVMBase with _$WalletCreationVM;

abstract class WalletCreationVMBase with Store {
  WalletCreationVMBase({@required this.type}) {
    state = InitialWalletCreationState();
    name = '';
  }

  @observable
  String name;

  @observable
  WalletCreationState state;

  WalletType type;

  Future<void> create({dynamic options}) async {
    try {
      state = WalletCreating();
      await process(getCredentials(options));
      state = WalletCreatedSuccessfully();
    } catch (e) {
      state = WalletCreationFailure(error: e.toString());
    }
  }

  WalletCredentials getCredentials(dynamic options) =>
      throw UnimplementedError();

  Future<void> process(WalletCredentials credentials) =>
      throw UnimplementedError();
}
