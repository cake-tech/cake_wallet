import 'package:mobx/mobx.dart';

part 'authentication_store.g.dart';

class AuthenticationStore = AuthenticationStoreBase with _$AuthenticationStore;

enum AuthenticationState { uninitialized, installed, allowed, denied }

abstract class AuthenticationStoreBase with Store {
  AuthenticationStoreBase() : state = AuthenticationState.uninitialized;

  @observable
  AuthenticationState state;

  @action
  void installed() => state = AuthenticationState.installed;

  @action
  void allowed() => state = AuthenticationState.allowed;

  @action
  void denied() => state = AuthenticationState.denied;
}
