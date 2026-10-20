import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/auth_service.dart';
import "package:cake_wallet/core/links/link_service.dart";
import 'package:cake_wallet/core/node_switching_service.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/core/trade_monitor.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/setup_2fa_enter_code_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/socket_health_logger.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:trezor_connect/trezor_connect.dart';
import 'package:uni_links/uni_links.dart';

class Root extends StatefulWidget {
  Root({
    required Key key,
    required this.authenticationStore,
    required this.appStore,
    required this.child,
    required this.navigatorKey,
    required this.authService,
    required this.linkService,
    required this.tradeMonitor,
    required this.nodeSwitchingService,
    required this.trezorConnect,
    this.initialQuickAction,
    required this.quickActionsStream,
  }) : super(key: key);

  final AuthenticationStore authenticationStore;
  final AppStore appStore;
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthService authService;
  final Widget child;
  final LinkService linkService;
  final TradeMonitor tradeMonitor;
  final NodeSwitchingService nodeSwitchingService;
  final TrezorConnect trezorConnect;
  final String? initialQuickAction;
  final Stream<Uri?> quickActionsStream;

  @override
  RootState createState() => RootState();
}

class RootState extends State<Root> with WidgetsBindingObserver {
  RootState()
      : _isInactiveController = StreamController<bool>.broadcast(),
        _isInactive = false,
        _requestAuth = true,
        _postFrameCallback = false;

  Stream<bool> get isInactive => _isInactiveController.stream;
  StreamController<bool> _isInactiveController;
  bool _isInactive;
  bool _postFrameCallback;
  bool _requestAuth;

  StreamSubscription<Uri?>? stream;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    widget.authService.requireAuth().then((value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _requestAuth = value);
      });
    });
    _isInactiveController = StreamController<bool>.broadcast();
    _isInactive = false;
    _postFrameCallback = false;
    super.initState();
    if (DeviceInfo.instance.isMobile) {
      initUniLinks();
    }
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

      // listen for quick actions
      widget.quickActionsStream.listen((Uri? uri) {
        handleDeepLinking(uri);
      });

      handleDeepLinking(await getInitialUri());

      if (widget.initialQuickAction != null) {
        final uri = Uri.parse("quickaction://${widget.initialQuickAction}");
        handleDeepLinking(uri);
      }
    } catch (e) {
      printV(e);
    }
  }

  void handleDeepLinking(Uri? uri) {
    if (uri == null || !mounted) return;

    if (uri.toString().startsWith(widget.trezorConnect.callbackBackUri)) {
      widget.trezorConnect.handleCallback(uri);
      return;
    }

    widget.linkService.handle(uri);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (isQrScannerShown) {
          return;
        }

        if (!_isInactive &&
            (widget.authenticationStore.state == AuthenticationState.allowed ||
                widget.authenticationStore.state == AuthenticationState.allowedCreate)) {
          setState(() {
            _requestAuth = false;
            _setInactive(true);
          });
        }

        if (widget.appStore.wallet?.type == WalletType.bitcoin) {
          bitcoin!.stopPayjoinSessions(widget.appStore.wallet!);
        }

        widget.tradeMonitor.stopTradeMonitoring();

        break;
      case AppLifecycleState.resumed:
        widget.authService.requireAuth().then((value) {
          if (mounted) {
            setState(() {
              _requestAuth = value;
              if (!value && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
                _setInactive(false);
              }
            });
          }
        });
        if (widget.appStore.wallet?.type == WalletType.bitcoin &&
            widget.appStore.settingsStore.usePayjoin) {
          bitcoin!.resumePayjoinSessions(widget.appStore.wallet!);
        }

        widget.tradeMonitor.resumeTradeMonitoring();

        // Trigger node health check when app resumes
        widget.nodeSwitchingService.performHealthCheck();

        // Electrum Wallet socket health check and reconnection flow
        final wallet = widget.appStore.wallet;
        if (wallet != null && isElectrumWallet(wallet.type)) {
          SocketHealthLogger().logHealthCheck(
            walletType: wallet.type,
            walletName: wallet.name,
            syncStatus: wallet.syncStatus.toString(),
            wasReconnected: false,
            trigger: 'app_resume',
          );

          wallet.checkSocketHealth().then((isHealthy) {
            SocketHealthLogger().logHealthCheck(
              walletType: wallet.type,
              walletName: wallet.name,
              isHealthy: isHealthy,
              syncStatus: wallet.syncStatus.toString(),
              wasReconnected: true,
              trigger: 'app_resume_socket_health_check',
            );
          });
        }

        break;
      default:
        break;
    }
  }

  @override
  void didChangePlatformBrightness() {
    // Only handle theme changes when the app is active (not in background)
    if (_isInactive) return;

    if (widget.appStore.themeStore.themeMode == ThemeMode.system) {
      Future.delayed(Duration(milliseconds: Platform.isIOS ? 500 : 0), () {
        // Double-check that app is still active before applying theme change
        if (_isInactive) return;

        final systemTheme = widget.appStore.themeStore.getThemeFromSystem();
        if (widget.appStore.themeStore.currentTheme != systemTheme) {
          widget.appStore.themeStore.setTheme(systemTheme);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // this only happens when the app has been in the background for some time
    // this does NOT trigger when the app is started from the "closed" state!
    if (_isInactive && !_postFrameCallback && _requestAuth) {
      _postFrameCallback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.linkService.pause();
        widget.navigatorKey.currentState?.pushNamed(
          Routes.unlock,
          arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
            if (!isAuthenticatedSuccessfully) {
              return;
            }
            final useTotp = widget.appStore.settingsStore.useTOTP2FA;
            final shouldUseTotp2FAToAccessWallets =
                widget.appStore.settingsStore.shouldRequireTOTP2FAForAccessingWallet;
            if (useTotp && shouldUseTotp2FAToAccessWallets) {
              _reset();
              auth.close(
                route: Routes.totpAuthCodePage,
                arguments: TotpAuthArgumentsModel(
                  onTotpAuthenticationFinished:
                      (bool isAuthenticatedSuccessfully, TotpAuthCodePageState totpAuth) async {
                    if (!isAuthenticatedSuccessfully) {
                      return;
                    }
                    _reset();
                    await totpAuth.close();
                    await widget.linkService.resume();
                  },
                  isForSetup: false,
                  isClosable: false,
                ),
              );
            } else {
              _reset();
              await auth.close();
              await widget.linkService.resume();
            }
          },
        );
      });
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: widget.child,
    );
  }

  void _reset() {
    setState(() {
      _postFrameCallback = false;
      _setInactive(false);
    });

    // Apply any missed theme changes after successful authentication
    if (widget.appStore.themeStore.themeMode == ThemeMode.system) {
      Future.delayed(Duration(milliseconds: 100), () {
        final systemTheme = widget.appStore.themeStore.getThemeFromSystem();
        if (widget.appStore.themeStore.currentTheme != systemTheme) {
          widget.appStore.themeStore.setTheme(systemTheme);
        }
      });
    }
  }

  void _setInactive(bool value) {
    _isInactive = value;
    _isInactiveController.add(value);
  }
}
