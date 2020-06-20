abstract class AuthState {}

class AuthenticationStateInitial extends AuthState {}

class AuthenticationInProgress extends AuthState {}

class AuthenticatedSuccessfully extends AuthState {}

class AuthenticationFailure extends AuthState {
  AuthenticationFailure({this.error});

  final String error;
}

class AuthenticationBanned extends AuthState {
  AuthenticationBanned({this.error});

  final String error;
}

