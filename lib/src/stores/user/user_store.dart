import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/services/user_service.dart';
import 'package:cake_wallet/src/stores/user/user_store_state.dart';

part 'user_store.g.dart';

class UserStore = UserStoreBase with _$UserStore;

abstract class UserStoreBase with Store {
  UserService accountService;

  @observable
  UserStoreState state;

  @observable
  String errorMessage;

  UserStoreBase({@required this.accountService});

  @action
  Future set({String password}) async {
    state = UserStoreStateInitial();

    try {
        await accountService.setPassword(password);
        state = PinCodeSetSuccesfully();
      } catch(e) {
        state = PinCodeSetFailed(error: e.toString());
      }
  }
}
