import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/src/domain/services/user_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/stores/auth/auth_store.dart';
import 'package:cake_wallet/src/stores/authentication/authentication_store.dart';

Widget createLoginPage(
        {@required SharedPreferences sharedPreferences,
        @required UserService userService,
        @required WalletService walletService,
        @required WalletListService walletListService,
        @required AuthenticationStore authenticationStore}) =>
    null;
//    Provider(
//        create: (_) => AuthStore(
//            sharedPreferences: sharedPreferences,
//            userService: userService,
//            walletService: walletService),
//        child: AuthPage(
//            onAuthenticationFinished: (isAuthenticated, state) {
//              if (isAuthenticated) {
//                authenticationStore.loggedIn();
//              }
//            },
//            closable: false));
