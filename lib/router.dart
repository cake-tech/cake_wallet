import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';

// MARK: Import domains

import 'package:cake_wallet/src/domain/common/contact.dart';
import 'package:cake_wallet/src/domain/services/user_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/changenow/changenow_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/monero/transaction_description.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/monero/account.dart';
import 'package:cake_wallet/src/domain/common/mnemotic_item.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/domain/monero/subaddress.dart';

// MARK: Import stores

import 'package:cake_wallet/src/stores/authentication/authentication_store.dart';
import 'package:cake_wallet/src/stores/node_list/node_list_store.dart';
import 'package:cake_wallet/src/stores/auth/auth_store.dart';
import 'package:cake_wallet/src/stores/balance/balance_store.dart';
import 'package:cake_wallet/src/stores/send/send_store.dart';
import 'package:cake_wallet/src/stores/subaddress_creation/subaddress_creation_store.dart';
import 'package:cake_wallet/src/stores/subaddress_list/subaddress_list_store.dart';
import 'package:cake_wallet/src/stores/sync/sync_store.dart';
import 'package:cake_wallet/src/stores/user/user_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/wallet_creation/wallet_creation_store.dart';
import 'package:cake_wallet/src/stores/wallet_list/wallet_list_store.dart';
import 'package:cake_wallet/src/stores/wallet_restoration/wallet_restoration_store.dart';
import 'package:cake_wallet/src/stores/account_list/account_list_store.dart';
import 'package:cake_wallet/src/stores/address_book/address_book_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_keys_store.dart';
import 'package:cake_wallet/src/stores/exchange_trade/exchange_trade_store.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_store.dart';
import 'package:cake_wallet/src/stores/rescan/rescan_wallet_store.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';

// MARK: Import screens

import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/nodes/new_node_page.dart';
import 'package:cake_wallet/src/screens/nodes/nodes_list_page.dart';
import 'package:cake_wallet/src/screens/receive/receive_page.dart';
import 'package:cake_wallet/src/screens/subaddress/new_subaddress_page.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/new_wallet_page.dart';
import 'package:cake_wallet/src/screens/setup_pin_code/setup_pin_code.dart';
import 'package:cake_wallet/src/screens/restore/restore_options_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_wallet_options_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_wallet_from_seed_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_wallet_from_keys_page.dart';
import 'package:cake_wallet/src/screens/send/send_page.dart';
import 'package:cake_wallet/src/screens/disclaimer/disclaimer_page.dart';
import 'package:cake_wallet/src/screens/seed_alert/seed_alert.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_page.dart';
import 'package:cake_wallet/src/screens/accounts/account_page.dart';
import 'package:cake_wallet/src/screens/accounts/account_list_page.dart';
import 'package:cake_wallet/src/screens/address_book/address_book_page.dart';
import 'package:cake_wallet/src/screens/address_book/contact_page.dart';
import 'package:cake_wallet/src/screens/show_keys/show_keys_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_confirm_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_page.dart';
import 'package:cake_wallet/src/screens/subaddress/subaddress_list_page.dart';
import 'package:cake_wallet/src/screens/settings/change_language.dart';
import 'package:cake_wallet/src/screens/restore/restore_wallet_from_seed_details.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/settings/settings.dart';
import 'package:cake_wallet/src/screens/rescan/rescan_page.dart';
import 'package:cake_wallet/src/screens/faq/faq_page.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_page.dart';
import 'package:cake_wallet/src/screens/auth/create_unlock_page.dart';
import 'package:cake_wallet/src/screens/auth/create_login_page.dart';
import 'package:cake_wallet/src/screens/seed/create_seed_page.dart';
import 'package:cake_wallet/src/screens/dashboard/create_dashboard_page.dart';
import 'package:cake_wallet/src/screens/welcome/create_welcome_page.dart';

class Router {
  static Route<dynamic> generateRoute(
      {SharedPreferences sharedPreferences,
      WalletListService walletListService,
      WalletService walletService,
      UserService userService,
      RouteSettings settings,
      PriceStore priceStore,
      WalletStore walletStore,
      SyncStore syncStore,
      BalanceStore balanceStore,
      SettingsStore settingsStore,
      Box<Contact> contacts,
      Box<Node> nodes,
      Box<TransactionDescription> transactionDescriptions,
      Box<Trade> trades}) {
    switch (settings.name) {
      case Routes.welcome:
        return MaterialPageRoute<void>(builder: (_) => createWelcomePage());

      case Routes.newWalletFromWelcome:
        return CupertinoPageRoute<void>(
            builder: (_) => Provider(
                create: (_) => UserStore(
                    accountService: UserService(
                        secureStorage: FlutterSecureStorage(),
                        sharedPreferences: sharedPreferences)),
                child: SetupPinCodePage(
                    onPinCodeSetup: (context, _) =>
                        Navigator.pushNamed(context, Routes.newWallet))));

      case Routes.newWallet:
        return CupertinoPageRoute<void>(
            builder:
                (_) =>
                    ProxyProvider<AuthenticationStore, WalletCreationStore>(
                        update: (_, authStore, __) => WalletCreationStore(
                            authStore: authStore,
                            sharedPreferences: sharedPreferences,
                            walletListService: walletListService),
                        child: NewWalletPage(
                            walletsService: walletListService,
                            walletService: walletService,
                            sharedPreferences: sharedPreferences)));

      case Routes.setupPin:
        Function(BuildContext, String) callback;

        if (settings.arguments is Function(BuildContext, String)) {
          callback = settings.arguments as Function(BuildContext, String);
        }

        return CupertinoPageRoute<void>(
            builder: (_) => Provider(
                create: (_) => UserStore(
                    accountService: UserService(
                        secureStorage: FlutterSecureStorage(),
                        sharedPreferences: sharedPreferences)),
                child: SetupPinCodePage(
                    onPinCodeSetup: (context, pin) =>
                        callback == null ? null : callback(context, pin))),
            fullscreenDialog: true);

      case Routes.restoreOptions:
        return CupertinoPageRoute<void>(builder: (_) => RestoreOptionsPage());

      case Routes.restoreWalletOptions:
        return CupertinoPageRoute<void>(
            builder: (_) => RestoreWalletOptionsPage());

      case Routes.restoreWalletOptionsFromWelcome:
        return CupertinoPageRoute<void>(
            builder: (_) => Provider(
                create: (_) => UserStore(
                    accountService: UserService(
                        secureStorage: FlutterSecureStorage(),
                        sharedPreferences: sharedPreferences)),
                child: SetupPinCodePage(
                    onPinCodeSetup: (context, _) => Navigator.pushNamed(
                        context, Routes.restoreWalletOptions))));

      case Routes.seed:
        return MaterialPageRoute<void>(
            builder: (_) => createSeedPage(
                settingsStore: settingsStore,
                walletService: walletService,
                callback: settings.arguments as void Function()));

      case Routes.restoreWalletFromSeed:
        return CupertinoPageRoute<void>(
            builder: (_) =>
                ProxyProvider<AuthenticationStore, WalletRestorationStore>(
                    update: (_, authStore, __) => WalletRestorationStore(
                        authStore: authStore,
                        sharedPreferences: sharedPreferences,
                        walletListService: walletListService),
                    child: RestoreWalletFromSeedPage(
                        walletsService: walletListService,
                        walletService: walletService,
                        sharedPreferences: sharedPreferences)));

      case Routes.restoreWalletFromKeys:
        return CupertinoPageRoute<void>(
            builder: (_) =>
                ProxyProvider<AuthenticationStore, WalletRestorationStore>(
                    update: (_, authStore, __) => WalletRestorationStore(
                        authStore: authStore,
                        sharedPreferences: sharedPreferences,
                        walletListService: walletListService),
                    child: RestoreWalletFromKeysPage(
                        walletsService: walletListService,
                        walletService: walletService,
                        sharedPreferences: sharedPreferences)));

      case Routes.dashboard:
        return CupertinoPageRoute<void>(
            builder: (_) => createDashboardPage(
                walletService: walletService,
                priceStore: priceStore,
                settingsStore: settingsStore,
                trades: trades,
                transactionDescriptions: transactionDescriptions,
                walletStore: walletStore));

      case Routes.send:
        return CupertinoPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => MultiProvider(providers: [
                  ProxyProvider<SettingsStore, BalanceStore>(
                    update: (_, settingsStore, __) => BalanceStore(
                        walletService: walletService,
                        settingsStore: settingsStore,
                        priceStore: priceStore),
                  ),
                  Provider(
                    create: (_) => SyncStore(walletService: walletService),
                  ),
                  Provider(
                      create: (_) => SendStore(
                          walletService: walletService,
                          priceStore: priceStore,
                          transactionDescriptions: transactionDescriptions)),
                ], child: SendPage()));

      case Routes.receive:
        return CupertinoPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => MultiProvider(providers: [
                  Provider(
                      create: (_) =>
                          SubaddressListStore(walletService: walletService))
                ], child: ReceivePage()));

      case Routes.transactionDetails:
        return CupertinoPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => TransactionDetailsPage(
                transactionInfo: settings.arguments as TransactionInfo));

      case Routes.newSubaddress:
        return CupertinoPageRoute<void>(
            builder: (_) => Provider(
                create: (_) =>
                    SubadrressCreationStore(walletService: walletService),
                child: NewSubaddressPage()));

      case Routes.disclaimer:
        return CupertinoPageRoute<void>(builder: (_) => DisclaimerPage());

      case Routes.readDisclaimer:
        return CupertinoPageRoute<void>(
            builder: (_) => DisclaimerPage(isReadOnly: true));

      case Routes.seedAlert:
        return CupertinoPageRoute<void>(builder: (_) => SeedAlert());

      case Routes.walletList:
        return MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => Provider(
                create: (_) => WalletListStore(
                    walletListService: walletListService,
                    walletService: walletService),
                child: WalletListPage()));

      case Routes.auth:
        return MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => Provider(
                  create: (_) => AuthStore(
                      sharedPreferences: sharedPreferences,
                      userService: userService,
                      walletService: walletService),
                  child: AuthPage(
                      onAuthenticationFinished:
                          settings.arguments as OnAuthenticationFinished),
                ));

      case Routes.unlock:
        return MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => createUnlockPage(
                sharedPreferences: sharedPreferences,
                userService: userService,
                walletService: walletService,
                onAuthenticationFinished:
                    settings.arguments as OnAuthenticationFinished));

      case Routes.nodeList:
        return CupertinoPageRoute<void>(builder: (context) {
          return Provider(
              create: (_) => NodeListStore(nodesSource: nodes),
              child: NodeListPage());
        });

      case Routes.newNode:
        return CupertinoPageRoute<void>(
            builder: (_) => Provider<NodeListStore>(
                create: (_) => NodeListStore(nodesSource: nodes),
                child: NewNodePage()));

      case Routes.login:
        return CupertinoPageRoute<void>(builder: (context) {
          final authenticationStore = Provider.of<AuthenticationStore>(context);

          return createLoginPage(
              sharedPreferences: sharedPreferences,
              userService: userService,
              walletService: walletService,
              walletListService: walletListService,
              authenticationStore: authenticationStore);
        });

      case Routes.accountList:
        return MaterialPageRoute<void>(
            builder: (context) {
              return MultiProvider(providers: [
                Provider(
                    create: (_) =>
                        AccountListStore(walletService: walletService)),
              ], child: AccountListPage());
            },
            fullscreenDialog: true);

      case Routes.accountCreation:
        return CupertinoPageRoute<String>(builder: (context) {
          return Provider(
              create: (_) => AccountListStore(walletService: walletService),
              child: AccountPage(account: settings.arguments as Account));
        });

      case Routes.addressBook:
        return MaterialPageRoute<void>(builder: (context) {
          return MultiProvider(
            providers: [
              Provider(
                  create: (_) =>
                      AccountListStore(walletService: walletService)),
              Provider(create: (_) => AddressBookStore(contacts: contacts))
            ],
            child: AddressBookPage(),
          );
        });

      case Routes.pickerAddressBook:
        return MaterialPageRoute<void>(builder: (context) {
          return MultiProvider(
            providers: [
              Provider(
                  create: (_) =>
                      AccountListStore(walletService: walletService)),
              Provider(create: (_) => AddressBookStore(contacts: contacts))
            ],
            child: AddressBookPage(isEditable: false),
          );
        });

      case Routes.addressBookAddContact:
        return CupertinoPageRoute<void>(builder: (context) {
          return MultiProvider(
            providers: [
              Provider(
                  create: (_) =>
                      AccountListStore(walletService: walletService)),
              Provider(create: (_) => AddressBookStore(contacts: contacts))
            ],
            child: ContactPage(contact: settings.arguments as Contact),
          );
        });

      case Routes.showKeys:
        return MaterialPageRoute<void>(
            builder: (context) {
              return Provider(
                create: (_) => WalletKeysStore(walletService: walletService),
                child: ShowKeysPage(),
              );
            },
            fullscreenDialog: true);

      case Routes.exchangeTrade:
        return CupertinoPageRoute<void>(
            builder: (_) => MultiProvider(
                  providers: [
                    ProxyProvider<SettingsStore, ExchangeTradeStore>(
                      update: (_, settingsStore, __) => ExchangeTradeStore(
                          trade: settings.arguments as Trade,
                          walletStore: walletStore,
                          trades: trades),
                    ),
                    ProxyProvider<SettingsStore, SendStore>(
                        update: (_, settingsStore, __) => SendStore(
                            transactionDescriptions: transactionDescriptions,
                            walletService: walletService,
                            settingsStore: settingsStore,
                            priceStore: priceStore)),
                  ],
                  child: ExchangeTradePage(),
                ));

      case Routes.exchangeConfirm:
        return MaterialPageRoute<void>(
            builder: (_) =>
                ExchangeConfirmPage(trade: settings.arguments as Trade));

      case Routes.tradeDetails:
        return MaterialPageRoute<void>(builder: (context) {
          return MultiProvider(providers: [
            ProxyProvider<SettingsStore, ExchangeTradeStore>(
              update: (_, settingsStore, __) => ExchangeTradeStore(
                  trade: settings.arguments as Trade,
                  walletStore: walletStore,
                  trades: trades),
            )
          ], child: TradeDetailsPage());
        });

      case Routes.subaddressList:
        return MaterialPageRoute<Subaddress>(
            builder: (_) => MultiProvider(providers: [
                  Provider(
                      create: (_) =>
                          SubaddressListStore(walletService: walletService))
                ], child: SubaddressListPage()));

      case Routes.restoreWalletFromSeedDetails:
        return CupertinoPageRoute<void>(
            builder: (_) =>
                ProxyProvider<AuthenticationStore, WalletRestorationStore>(
                    update: (_, authStore, __) => WalletRestorationStore(
                        authStore: authStore,
                        sharedPreferences: sharedPreferences,
                        walletListService: walletListService,
                        seed: settings.arguments as List<MnemoticItem>),
                    child: RestoreWalletFromSeedDetailsPage()));

      case Routes.exchange:
        return MaterialPageRoute<void>(
            builder: (_) => MultiProvider(providers: [
                  Provider(create: (_) {
                    final xmrtoprovider = XMRTOExchangeProvider();

                    return ExchangeStore(
                        initialProvider: xmrtoprovider,
                        initialDepositCurrency: CryptoCurrency.xmr,
                        initialReceiveCurrency: CryptoCurrency.btc,
                        trades: trades,
                        providerList: [
                          xmrtoprovider,
                          ChangeNowExchangeProvider(),
                          MorphTokenExchangeProvider(trades: trades)
                        ],
                        walletStore: walletStore);
                  }),
                ], child: ExchangePage()));

      case Routes.settings:
        return MaterialPageRoute<void>(
            builder: (_) => Provider(
                create: (_) => NodeListStore(nodesSource: nodes),
                child: SettingsPage()));

      case Routes.rescan:
        return MaterialPageRoute<void>(
            builder: (_) => Provider(
                create: (_) => RescanWalletStore(walletService: walletService),
                child: RescanPage()));

      case Routes.faq:
        return MaterialPageRoute<void>(builder: (_) => FaqPage());

      case Routes.changeLanguage:
        return MaterialPageRoute<void>(builder: (_) => ChangeLanguage());

      default:
        return MaterialPageRoute<void>(
            builder: (_) => Scaffold(
                  body: Center(
                      child: Text(S.current.router_no_route(settings.name))),
                ));
    }
  }
}
