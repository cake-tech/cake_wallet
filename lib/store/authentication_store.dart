import 'package:mobx/mobx.dart';

part 'authentication_store.g.dart';

class AuthenticationStore = AuthenticationStoreBase with _$AuthenticationStore;

enum AuthenticationState { uninitialized, installed, allowed, _reset }

abstract class AuthenticationStoreBase with Store {
  AuthenticationStoreBase() : state = AuthenticationState.uninitialized;

  @observable
  AuthenticationState state;

  @action
  void installed() {
    state = AuthenticationState._reset;
    state = AuthenticationState.installed;
  }

  @action
  void allowed() {
    state = AuthenticationState._reset;
    state = AuthenticationState.allowed;
  }
}
