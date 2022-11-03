abstract class AuthState {}

class AuthenticationStateInitial extends AuthState {}

class AuthenticationInProgress extends AuthState {}

class AuthenticatedSuccessfully extends AuthState {}

class AuthenticationFailure extends AuthState {
  AuthenticationFailure({required this.error});

  final String error;
}

class AuthenticationBanned extends AuthState {
  AuthenticationBanned({required this.error});

  final String error;
}

