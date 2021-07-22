import 'package:cake_wallet/bitcoin/unspent_coins_info.dart';
import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/di.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cw_monero/wallet.dart' as monero_wallet;
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/router.dart' as Router;
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/bootstrap.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/entities/get_encryption_key.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/src/screens/root/root.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final appDir = await getApplicationDocumentsDirectory();
    await Hive.close();
    Hive.init(appDir.path);

    if (!Hive.isAdapterRegistered(Contact.typeId)) {
      Hive.registerAdapter(ContactAdapter());
    }

    if (!Hive.isAdapterRegistered(Node.typeId)) {
      Hive.registerAdapter(NodeAdapter());
    }

    if (!Hive.isAdapterRegistered(TransactionDescription.typeId)) {
      Hive.registerAdapter(TransactionDescriptionAdapter());
    }

    if (!Hive.isAdapterRegistered(Trade.typeId)) {
      Hive.registerAdapter(TradeAdapter());
    }

    if (!Hive.isAdapterRegistered(WalletInfo.typeId)) {
      Hive.registerAdapter(WalletInfoAdapter());
    }

    if (!Hive.isAdapterRegistered(walletTypeTypeId)) {
      Hive.registerAdapter(WalletTypeAdapter());
    }

    if (!Hive.isAdapterRegistered(Template.typeId)) {
      Hive.registerAdapter(TemplateAdapter());
    }

    if (!Hive.isAdapterRegistered(ExchangeTemplate.typeId)) {
      Hive.registerAdapter(ExchangeTemplateAdapter());
    }

    if (!Hive.isAdapterRegistered(Order.typeId)) {
      Hive.registerAdapter(OrderAdapter());
    }

    if (!Hive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      Hive.registerAdapter(UnspentCoinsInfoAdapter());
    }

    final secureStorage = FlutterSecureStorage();
    final transactionDescriptionsBoxKey = await getEncryptionKey(
        secureStorage: secureStorage, forKey: TransactionDescription.boxKey);
    final tradesBoxKey = await getEncryptionKey(
        secureStorage: secureStorage, forKey: Trade.boxKey);
    final ordersBoxKey = await getEncryptionKey(
        secureStorage: secureStorage, forKey: Order.boxKey);
    final contacts = await Hive.openBox<Contact>(Contact.boxName);
    final nodes = await Hive.openBox<Node>(Node.boxName);
    final transactionDescriptions = await Hive.openBox<TransactionDescription>(
        TransactionDescription.boxName,
        encryptionKey: transactionDescriptionsBoxKey);
    final trades =
        await Hive.openBox<Trade>(Trade.boxName, encryptionKey: tradesBoxKey);
    final orders =
        await Hive.openBox<Order>(Order.boxName, encryptionKey: ordersBoxKey);
    final walletInfoSource = await Hive.openBox<WalletInfo>(WalletInfo.boxName);
    final templates = await Hive.openBox<Template>(Template.boxName);
    final exchangeTemplates =
        await Hive.openBox<ExchangeTemplate>(ExchangeTemplate.boxName);
    final unspentCoinsInfoSource =
      await Hive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
    await initialSetup(
        sharedPreferences: await SharedPreferences.getInstance(),
        nodes: nodes,
        walletInfoSource: walletInfoSource,
        contactSource: contacts,
        tradesSource: trades,
        ordersSource: orders,
        unspentCoinsInfoSource: unspentCoinsInfoSource,
        // fiatConvertationService: fiatConvertationService,
        templates: templates,
        exchangeTemplates: exchangeTemplates,
        transactionDescriptions: transactionDescriptions,
        secureStorage: secureStorage,
        initialMigrationVersion: 15);
    runApp(App());
  } catch (e) {
    runApp(MaterialApp(
        debugShowCheckedModeBanner: true,
        home: Scaffold(
            body: Container(
                margin:
                    EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                child: Text(
                  'Error:\n${e.toString()}',
                  style: TextStyle(fontSize: 22),
                )))));
  }
}

Future<void> initialSetup(
    {@required SharedPreferences sharedPreferences,
    @required Box<Node> nodes,
    @required Box<WalletInfo> walletInfoSource,
    @required Box<Contact> contactSource,
    @required Box<Trade> tradesSource,
    @required Box<Order> ordersSource,
    // @required FiatConvertationService fiatConvertationService,
    @required Box<Template> templates,
    @required Box<ExchangeTemplate> exchangeTemplates,
    @required Box<TransactionDescription> transactionDescriptions,
    @required Box<UnspentCoinsInfo> unspentCoinsInfoSource,
    FlutterSecureStorage secureStorage,
    int initialMigrationVersion = 15}) async {
  LanguageService.loadLocaleList();
  await defaultSettingsMigration(
      secureStorage: secureStorage,
      version: initialMigrationVersion,
      sharedPreferences: sharedPreferences,
      walletInfoSource: walletInfoSource,
      contactSource: contactSource,
      tradeSource: tradesSource,
      nodes: nodes);
  await setup(
      walletInfoSource: walletInfoSource,
      nodeSource: nodes,
      contactSource: contactSource,
      tradesSource: tradesSource,
      templates: templates,
      exchangeTemplates: exchangeTemplates,
      transactionDescriptionBox: transactionDescriptions,
      ordersSource: ordersSource,
      unspentCoinsInfoSource: unspentCoinsInfoSource);
  await bootstrap(navigatorKey);
  monero_wallet.onStartup();
}

class App extends StatelessWidget {
  App() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (BuildContext context) {
      final settingsStore = getIt.get<AppStore>().settingsStore;
      final statusBarColor = Colors.transparent;
      final authenticationStore = getIt.get<AuthenticationStore>();
      final initialRoute =
          authenticationStore.state == AuthenticationState.denied
              ? Routes.disclaimer
              : Routes.login;
      final currentTheme = settingsStore.currentTheme;
      final statusBarBrightness = currentTheme.type == ThemeType.dark
          ? Brightness.light
          : Brightness.dark;
      final statusBarIconBrightness = currentTheme.type == ThemeType.dark
          ? Brightness.light
          : Brightness.dark;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: statusBarColor,
          statusBarBrightness: statusBarBrightness,
          statusBarIconBrightness: statusBarIconBrightness));

      return Root(
          authenticationStore: authenticationStore,
          navigatorKey: navigatorKey,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: settingsStore.theme,
            localizationsDelegates: [
              S.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: Locale(settingsStore.languageCode),
            onGenerateRoute: (settings) => Router.createRoute(settings),
            initialRoute: initialRoute,
          ));
    });
  }
}
