typedef CloseAuth = Future<void> Function({String? route, dynamic arguments});

class AuthResponse {
  AuthResponse({bool success = false, this.payload, required this.close, String? error})
      : this.success = success,
        this.error = success == false ? error ?? '' : null;

  final bool success;
  final dynamic payload;
  final String? error;
  final CloseAuth close;
}

typedef OnAuthenticationFinished = void Function(AuthResponse);
