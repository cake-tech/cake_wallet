import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/stores/wallet_creation/wallet_creation_state.dart';
import 'package:cake_wallet/src/stores/authentication/authentication_store.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'wallet_creation_store.g.dart';

class WalletCreationStore = WalletCreationStoreBase with _$WalletCreationStore;

abstract class WalletCreationStoreBase with Store {
  WalletCreationStoreBase(
      {@required this.authStore,
      @required this.walletListService,
      @required this.sharedPreferences}) {
    state = WalletCreationStateInitial();
  }

  final AuthenticationStore authStore;
  final WalletListService walletListService;
  final SharedPreferences sharedPreferences;

  @observable
  WalletCreationState state;

  @observable
  String errorMessage;

  @observable
  bool isValid;

  @action
  Future create({String name}) async {
    state = WalletCreationStateInitial();

    try {
      state = WalletIsCreating();
      await walletListService.create(name);
      authStore.created();
      state = WalletCreatedSuccessfully();
    } catch (e) {
      state = WalletCreationFailure(error: e.toString());
    }
  }

  void validateWalletName(String value) {
    const pattern = '^[a-zA-Z0-9_]{1,15}\$';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);
    errorMessage = isValid ? null : S.current.error_text_wallet_name;
  }
}
