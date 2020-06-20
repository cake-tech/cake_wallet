import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/authentication_store.dart';

//import 'package:cake_wallet/src/stores/authentication/authentication_store.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/domain/common/qr_scanner.dart';
import 'package:cake_wallet/src/domain/services/user_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/monero/transaction_description.dart';
import 'package:cake_wallet/src/screens/auth/create_login_page.dart';
import 'package:cake_wallet/src/screens/seed/create_seed_page.dart';
import 'package:cake_wallet/src/screens/dashboard/create_dashboard_page.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/welcome/create_welcome_page.dart';

class Root extends StatefulWidget {
  Root({Key key, this.authenticationStore, this.appStore}) : super(key: key);

  final AuthenticationStore authenticationStore;
  final AppStore appStore;

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

//        if (!_isInactive &&
//                widget.authenticationStore.state ==
//                    AuthenticationState.authenticated ||
//            widget.authenticationStore.state == AuthenticationState.active) {
//          setState(() => _isInactive = true);
//        }

        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
//    _authenticationStore = Provider.of<AuthenticationStore>(context);
//    final sharedPreferences = Provider.of<SharedPreferences>(context);
//    final walletListService = Provider.of<WalletListService>(context);
//    final walletService = Provider.of<WalletService>(context);
//    final userService = Provider.of<UserService>(context);
//    final priceStore = Provider.of<PriceStore>(context);
//    final authenticationStore = Provider.of<AuthenticationStore>(context);
//    final trades = Provider.of<Box<Trade>>(context);
//    final transactionDescriptions =
//        Provider.of<Box<TransactionDescription>>(context);
//    final walletStore = Provider.of<WalletStore>(context);
//    final settingsStore = Provider.of<SettingsStore>(context);

    if (_isInactive && !_postFrameCallback) {
      _postFrameCallback = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed(Routes.unlock,
            arguments: (bool isAuthenticatedSuccessfully, AuthPageState auth) {
          if (!isAuthenticatedSuccessfully) {
            return;
          }

          setState(() {
            _postFrameCallback = false;
            _isInactive = false;
          });
          auth.close();
        });
      });
    }

    return Observer(builder: (_) {
      final state = widget.authenticationStore.state;
      print(state);
      if (state == AuthenticationState.denied) {
        return createWelcomePage();
      }

      if (state == AuthenticationState.installed) {
        return getIt.get<AuthPage>();
      }

      if (state == AuthenticationState.allowed) {
        return getIt.get<DashboardPage>();
      }

//      if (state == AuthenticationState.denied) {
//        return createWelcomePage();
//      }

//      if (state == AuthenticationState.readyToLogin) {
//        return createLoginPage(
//            sharedPreferences: sharedPreferences,
//            userService: userService,
//            walletService: walletService,
//            walletListService: walletListService,
//            authenticationStore: authenticationStore);
//      }

//      if (state == AuthenticationState.authenticated ||
//          state == AuthenticationState.restored) {
//        return createDashboardPage(
//            walletService: walletService,
//            priceStore: priceStore,
//            trades: trades,
//            transactionDescriptions: transactionDescriptions,
//            walletStore: walletStore,
//            settingsStore: settingsStore);
//      }

//      if (state == AuthenticationState.created) {
//        return createSeedPage(
//            settingsStore: settingsStore,
//            walletService: walletService,
//            callback: () =>
//                _authenticationStore.state = AuthenticationState.authenticated);
//      }

      return Container(color: Colors.white);
    });
  }
}
