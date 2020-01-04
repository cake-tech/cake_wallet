abstract class AuthState {}

class AuthenticationStateInitial extends AuthState {}

class AuthenticationInProgress extends AuthState {}

class AuthenticatedSuccessfully extends AuthState {}

class AuthenticationFailure extends AuthState {
  final String error;

  AuthenticationFailure({this.error});
}

class AuthenticationBanned extends AuthState {
  final String error;

  AuthenticationBanned({this.error});
}

