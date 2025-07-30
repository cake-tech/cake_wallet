import 'dart:async';
import 'dart:io';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/core/trade_monitor.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/view_model/link_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:mobx/mobx.dart';
import 'package:uni_links/uni_links.dart';
import 'package:cake_wallet/src/screens/setup_2fa/setup_2fa_enter_code_page.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cw_core/utils/socket_health_logger.dart';

class Root extends StatefulWidget {
  Root({
    required Key key,
    required this.authenticationStore,
    required this.appStore,
    required this.child,
    required this.navigatorKey,
    required this.authService,
    required this.linkViewModel,
    required this.tradeMonitor,
  }) : super(key: key);

  final AuthenticationStore authenticationStore;
  final AppStore appStore;
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthService authService;
  final Widget child;
  final LinkViewModel linkViewModel;
  final TradeMonitor tradeMonitor;

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
  ReactionDisposer? _walletReactionDisposer;
  ReactionDisposer? _deepLinksReactionDisposer;

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
    _walletReactionDisposer?.call();
    _deepLinksReactionDisposer?.call();
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
      printV(e);
    }
  }

  void handleDeepLinking(Uri? uri) async {
    if (uri == null || !mounted) return;

    widget.linkViewModel.currentLink = uri;

    bool requireAuth = await widget.authService.requireAuth();

    if (!requireAuth && widget.authenticationStore.state == AuthenticationState.allowed) {
      _navigateToDeepLinkScreen();
      return;
    }

    _deepLinksReactionDisposer = reaction(
      (_) => widget.authenticationStore.state,
      (AuthenticationState state) {
        if (state == AuthenticationState.allowed) {
          if (widget.appStore.wallet == null) {
            waitForWalletInstance(context);
          } else {
            _navigateToDeepLinkScreen();
          }
          _deepLinksReactionDisposer?.call();
          _deepLinksReactionDisposer = null;
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (isQrScannerShown) {
          return;
        }

        if (!_isInactive && widget.authenticationStore.state == AuthenticationState.allowed) {
          setState(() => _setInactive(true));
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
            });
          }
        });
        if (widget.appStore.wallet?.type == WalletType.bitcoin &&
            widget.appStore.settingsStore.usePayjoin) {
          bitcoin!.resumePayjoinSessions(widget.appStore.wallet!);
        }

        widget.tradeMonitor.resumeTradeMonitoring();

        // Electrum Wallet socket health check and reconnection flow
        final wallet = widget.appStore.wallet;
        if (wallet != null && isElectrumWallet(wallet.type)) {
          SocketHealthLogger()
              .logHealthCheck(
            walletType: wallet.type,
            walletName: wallet.name,
            isHealthy: true, // We don't know yet, will be updated
            syncStatus: wallet.syncStatus.toString(),
            wasReconnected: false,
            trigger: 'app_resume',
          )
              .then((_) {
            wallet.checkSocketHealth().then(
              (isHealthy) {
                SocketHealthLogger().logHealthCheck(
                  walletType: wallet.type,
                  walletName: wallet.name,
                  isHealthy: isHealthy,
                  syncStatus: wallet.syncStatus.toString(),
                  wasReconnected: true,
                  trigger: 'app_resume_socket_health_check',
                );
              },
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
    if (widget.appStore.themeStore.themeMode == ThemeMode.system) {
      Future.delayed(Duration(milliseconds: Platform.isIOS ? 500 : 0), () {
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
        widget.navigatorKey.currentState?.pushNamed(
          Routes.unlock,
          arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
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
                      (bool isAuthenticatedSuccessfully, TotpAuthCodePageState totpAuth) {
                    if (!isAuthenticatedSuccessfully) {
                      return;
                    }
                    _reset();
                    totpAuth.close(
                      route: widget.linkViewModel.getRouteToGo(),
                      arguments: widget.linkViewModel.getRouteArgs(),
                    );
                    widget.linkViewModel.currentLink = null;
                  },
                  isForSetup: false,
                  isClosable: false,
                ),
              );
            } else {
              _reset();
              auth.close(
                route: widget.linkViewModel.getRouteToGo(),
                arguments: widget.linkViewModel.getRouteArgs(),
              );
              widget.linkViewModel.currentLink = null;
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
  }

  void _setInactive(bool value) {
    _isInactive = value;
    _isInactiveController.add(value);
  }

  void waitForWalletInstance(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _walletReactionDisposer = reaction(
          (_) => widget.appStore.wallet,
          (WalletBase? wallet) {
            if (wallet != null) {
              _navigateToDeepLinkScreen();
              _walletReactionDisposer?.call();
              _walletReactionDisposer = null;
            }
          },
        );
      }
    });
  }

  void _navigateToDeepLinkScreen() {
    widget.linkViewModel.handleLink();
  }
}
