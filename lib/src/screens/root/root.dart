import 'dart:async';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:uni_links/uni_links.dart';

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
    _postFrameCallback = false;

  Stream<bool> get isInactive => _isInactiveController.stream;
  StreamController<bool> _isInactiveController;
  bool _isInactive;
  bool _postFrameCallback;

  StreamSubscription<Uri?>? stream;
  Uri? launchUri;

  @override
  void initState() {
    _isInactiveController = StreamController<bool>.broadcast();
    _isInactive = false;
    _postFrameCallback = false;
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    initUniLinks();
  }

  @override
  void dispose() {
    stream?.cancel();
    super.dispose();
  }

  /// handle app links while the app is already started
  /// whether its in the foreground or in the background.
  Future<void> initUniLinks() async {
    try {
      stream = uriLinkStream.listen((Uri? uri) {
        handleDeepLinking(uri);
      });

      handleDeepLinking(await getInitialUri());
    } catch (e) {
      print(e);
    }
  }

  void handleDeepLinking(Uri? uri) {
    if (uri == null || !mounted) return;

    launchUri = uri;
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
          setState(() => _setInactive(true));
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
        widget.navigatorKey.currentState?.pushNamed(Routes.unlock,
            arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
          if (!isAuthenticatedSuccessfully) {
            return;
          }

          _reset();
          auth.close(
            route: launchUri != null ? Routes.send : null,
            arguments: PaymentRequest.fromUri(launchUri),
          );
          launchUri = null;
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
