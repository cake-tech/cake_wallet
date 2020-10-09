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
import 'package:cake_wallet/router.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);
  Hive.registerAdapter(ContactAdapter());
  Hive.registerAdapter(NodeAdapter());
  Hive.registerAdapter(TransactionDescriptionAdapter());
  Hive.registerAdapter(TradeAdapter());
  Hive.registerAdapter(WalletInfoAdapter());
  Hive.registerAdapter(WalletTypeAdapter());
  Hive.registerAdapter(TemplateAdapter());
  Hive.registerAdapter(ExchangeTemplateAdapter());

  final secureStorage = FlutterSecureStorage();
  final transactionDescriptionsBoxKey = await getEncryptionKey(
      secureStorage: secureStorage, forKey: TransactionDescription.boxKey);
  final tradesBoxKey = await getEncryptionKey(
      secureStorage: secureStorage, forKey: Trade.boxKey);
  final contacts = await Hive.openBox<Contact>(Contact.boxName);
  final nodes = await Hive.openBox<Node>(Node.boxName);
  final transactionDescriptions = await Hive.openBox<TransactionDescription>(
      TransactionDescription.boxName,
      encryptionKey: transactionDescriptionsBoxKey);
  final trades =
      await Hive.openBox<Trade>(Trade.boxName, encryptionKey: tradesBoxKey);
  final walletInfoSource = await Hive.openBox<WalletInfo>(WalletInfo.boxName);
  final templates = await Hive.openBox<Template>(Template.boxName);
  final exchangeTemplates =
      await Hive.openBox<ExchangeTemplate>(ExchangeTemplate.boxName);
  await initialSetup(
      sharedPreferences: await SharedPreferences.getInstance(),
      nodes: nodes,
      walletInfoSource: walletInfoSource,
      contactSource: contacts,
      tradesSource: trades,
      // fiatConvertationService: fiatConvertationService,
      templates: templates,
      exchangeTemplates: exchangeTemplates,
      initialMigrationVersion: 4);
  runApp(App());
}

Future<void> initialSetup(
    {@required SharedPreferences sharedPreferences,
    @required Box<Node> nodes,
    @required Box<WalletInfo> walletInfoSource,
    @required Box<Contact> contactSource,
    @required Box<Trade> tradesSource,
    // @required FiatConvertationService fiatConvertationService,
    @required Box<Template> templates,
    @required Box<ExchangeTemplate> exchangeTemplates,
    int initialMigrationVersion = 5}) async {
  await defaultSettingsMigration(
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
      exchangeTemplates: exchangeTemplates);
  bootstrap(navigatorKey);
  monero_wallet.onStartup();
}

class App extends StatelessWidget {
  App() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt.get<AppStore>().settingsStore;

    if (settingsStore.theme == null) {
      settingsStore.isDarkTheme = false;
    }

    final statusBarColor = Colors.transparent;
    final statusBarBrightness =
        settingsStore.isDarkTheme ? Brightness.light : Brightness.dark;
    final statusBarIconBrightness =
        settingsStore.isDarkTheme ? Brightness.light : Brightness.dark;
    final authenticationStore = getIt.get<AuthenticationStore>();
    final initialRoute = authenticationStore.state == AuthenticationState.denied
        ? Routes.welcome
        : Routes.login;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarBrightness: statusBarBrightness,
        statusBarIconBrightness: statusBarIconBrightness));

    return Observer(builder: (BuildContext context) {
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
            onGenerateRoute: (settings) => Router.generateRoute(settings),
            initialRoute: initialRoute,
          ));
    });
  }
}
