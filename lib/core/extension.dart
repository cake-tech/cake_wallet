import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:flutter/material.dart';

const List<String> _alwaysAuthenticateRoutes = [
  Routes.showKeys,
  Routes.backup,
  Routes.setupPin,
];

final _authService = getIt.get<AuthService>();

extension AuthenticateRoute on BuildContext {
  void navigateToAuthenticatedRoute(
      {Function(bool)? onAuthSuccess, String route = '', Object? arguments}) {
    if (!_authService.requireAuth() && !_alwaysAuthenticateRoutes.contains(route)) {
      if (onAuthSuccess != null) {
        onAuthSuccess(true);
      } else {
        Navigator.of(this).pushNamed(
          route,
          arguments: arguments,
        );
      }
      return;
    }
    Navigator.of(this).pushNamed(Routes.auth,
        arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
      if (!isAuthenticatedSuccessfully) {
        onAuthSuccess?.call(false);
        return;
      }
      if (onAuthSuccess != null) {
        auth.close();
        onAuthSuccess.call(true);
      } else {
        auth.close(route: route, arguments: arguments);
      }
    });
  }
}
