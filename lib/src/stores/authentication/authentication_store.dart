import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/services/user_service.dart';

part 'authentication_store.g.dart';

class AuthenticationStore = AuthenticationStoreBase with _$AuthenticationStore;

enum AuthenticationState {
  uninitialized,
  allowed,
  denied,
  authenticated,
  unauthenticated,
  active,
  loading,
  created,
  restored,
  readyToLogin
}

abstract class AuthenticationStoreBase with Store {
  AuthenticationStoreBase({@required this.userService}) {
    state = AuthenticationState.uninitialized;
  }

  final UserService userService;

  @observable
  AuthenticationState state;

  @observable
  String errorMessage;

  Future started() async {
    final canAuth = await userService.canAuthenticate();
    state = canAuth ? AuthenticationState.allowed : AuthenticationState.denied;
  }

  @action
  void created() {
    state = AuthenticationState.created;
  }

  @action
  void restored() {
    state = AuthenticationState.restored;
  }

  @action
  void loggedIn() {
    state = AuthenticationState.authenticated;
  }

  @action
  void inactive() {
    state = AuthenticationState.unauthenticated;
  }

  @action
  void active() {
    state = AuthenticationState.active;
  }

  @action
  void loggedOut() {
    state = AuthenticationState.uninitialized;
  }
}
