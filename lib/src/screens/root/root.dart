import 'dart:async';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';

class Root extends StatefulWidget {
  Root(
      {required Key key,
      required this.authenticationStore,
      required this.appStore,
      required this.child,
      required this.navigatorKey})
      : super(key: key);

  final AuthenticationStore authenticationStore;
  final AppStore appStore;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  RootState createState() => RootState();
}

class RootState extends State<Root> with WidgetsBindingObserver {
  RootState()
    : _isInactiveController = StreamController<bool>.broadcast(),
    _isInactive = false,
   _requestAuth = getIt.get<AuthService>().requireAuth(),
    _postFrameCallback = false;

  Stream<bool> get isInactive => _isInactiveController.stream;
  StreamController<bool> _isInactiveController;
  bool _isInactive;
  bool _postFrameCallback;
  bool _requestAuth;

  @override
  void initState() {

    _isInactiveController = StreamController<bool>.broadcast();
    _isInactive = false;
    _postFrameCallback = false;
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (isQrScannerShown) {
          return;
        }

        setState(() {
          _requestAuth = getIt.get<AuthService>().requireAuth();
        });

        if (!_isInactive &&
            widget.authenticationStore.state == AuthenticationState.allowed) {
          setState(() => _setInactive(true));
        }

        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInactive && !_postFrameCallback && _requestAuth) {
      _postFrameCallback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigatorKey.currentState?.pushNamed(Routes.unlock,
            arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
          if (!isAuthenticatedSuccessfully) {
            return;
          }

          _reset();
          auth.close();
        });
      });
    }

    return WillPopScope(onWillPop: () async => false, child: widget.child);
  }

  void _reset() {
    setState(() {
      _postFrameCallback = false;
      _setInactive(false);
    });
  }

  void _setInactive(bool value) {
    _isInactive = value;
    _isInactiveController.add(value);
  }
}
