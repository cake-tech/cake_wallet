import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';

class Root extends StatefulWidget {
  Root({Key key, this.authenticationStore, this.appStore, this.child})
      : super(key: key);

  final AuthenticationStore authenticationStore;
  final AppStore appStore;
  final Widget child;

  @override
  RootState createState() => RootState();
}

class RootState extends State<Root> with WidgetsBindingObserver {
  bool _isInactive;
  bool _postFrameCallback;

  @override
  void initState() {
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

        if (!_isInactive &&
            widget.authenticationStore.state == AuthenticationState.allowed) {
          setState(() => _isInactive = true);
        }

        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInactive && !_postFrameCallback) {
      _postFrameCallback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed(Routes.unlock,
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
      _isInactive = false;
    });
  }
}
