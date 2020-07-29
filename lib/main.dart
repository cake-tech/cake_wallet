import 'package:cake_wallet/reactions/bootstrap.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_service.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:cw_monero/wallet.dart' as monero_wallet;
import 'package:cake_wallet/router.dart';
import 'theme_changer.dart';
import 'themes.dart';
import 'package:cake_wallet/src/domain/common/get_encryption_key.dart';
import 'package:cake_wallet/src/domain/common/contact.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/monero/transaction_description.dart';
import 'package:cake_wallet/src/reactions/set_reactions.dart';
import 'package:cake_wallet/src/stores/login/login_store.dart';
import 'package:cake_wallet/src/stores/balance/balance_store.dart';
import 'package:cake_wallet/src/stores/sync/sync_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/send_template/send_template_store.dart';
import 'package:cake_wallet/src/stores/exchange_template/exchange_template_store.dart';
import 'package:cake_wallet/src/screens/root/root.dart';

//import 'package:cake_wallet/src/stores/authentication/authentication_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/domain/services/user_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/default_settings_migration.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/template.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_template.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/domain/services/fiat_convertation_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/language.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';

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
      secureStorage: secureStorage,
      forKey: 'transactionDescriptionsBoxKey'); // FIXME: Unnamed constant
  final tradesBoxKey = await getEncryptionKey(
      secureStorage: secureStorage,
      forKey: 'tradesBoxKey'); // FIXME: Unnamed constant

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

  final sharedPreferences = await SharedPreferences.getInstance();
  final walletService = WalletService();
  final fiatConvertationService = FiatConvertationService();
  final walletListService = WalletListService(
      secureStorage: secureStorage,
      walletInfoSource: walletInfoSource,
      walletService: walletService,
      sharedPreferences: sharedPreferences);
  final userService = UserService(
      sharedPreferences: sharedPreferences, secureStorage: secureStorage);
  final settingsStore = await SettingsStoreBase.load(
      nodes: nodes,
      sharedPreferences: sharedPreferences,
      initialFiatCurrency: FiatCurrency.usd,
      initialTransactionPriority: TransactionPriority.slow,
      initialBalanceDisplayMode: BalanceDisplayMode.availableBalance);
  final priceStore = PriceStore();
  final walletStore =
      WalletStore(walletService: walletService, settingsStore: settingsStore);
  final syncStore = SyncStore(walletService: walletService);
  final balanceStore = BalanceStore(
      walletService: walletService,
      settingsStore: settingsStore,
      priceStore: priceStore);
  final loginStore = LoginStore(
      sharedPreferences: sharedPreferences, walletsService: walletListService);
  final seedLanguageStore = SeedLanguageStore();
  final sendTemplateStore = SendTemplateStore(templateSource: templates);
  final exchangeTemplateStore =
      ExchangeTemplateStore(templateSource: exchangeTemplates);

  final walletCreationService = WalletCreationService();
  final authService = AuthService();

  await initialSetup(
      sharedPreferences: await SharedPreferences.getInstance(),
      nodes: nodes,
      walletInfoSource: walletInfoSource,
      contactSource: contacts,
      tradesSource: trades,
      fiatConvertationService: fiatConvertationService,
      templates: templates,
      exchangeTemplates: exchangeTemplates,
      initialMigrationVersion: 3);

  setReactions(
      settingsStore: settingsStore,
      priceStore: priceStore,
      syncStore: syncStore,
      walletStore: walletStore,
      walletService: walletService,
//      authenticationStore: authenticationStore,
      loginStore: loginStore);

  runApp(MultiProvider(providers: [
    Provider(create: (_) => sharedPreferences),
    Provider(create: (_) => walletService),
    Provider(create: (_) => walletListService),
    Provider(create: (_) => userService),
    Provider(create: (_) => settingsStore),
    Provider(create: (_) => priceStore),
    Provider(create: (_) => walletStore),
    Provider(create: (_) => syncStore),
    Provider(create: (_) => balanceStore),
//    Provider(create: (_) => authenticationStore),
    Provider(create: (_) => contacts),
    Provider(create: (_) => nodes),
    Provider(create: (_) => transactionDescriptions),
    Provider(create: (_) => trades),
    Provider(create: (_) => seedLanguageStore),
    Provider(create: (_) => sendTemplateStore),
    Provider(create: (_) => exchangeTemplateStore),
//    Provider(create: (_) => appStore),
    Provider(create: (_) => walletCreationService),
    Provider(create: (_) => authService)
  ], child: CakeWalletApp()));
}

Future<void> initialSetup(
    {@required SharedPreferences sharedPreferences,
    @required Box<Node> nodes,
    @required Box<WalletInfo> walletInfoSource,
    @required Box<Contact> contactSource,
    @required  Box<Trade> tradesSource,
    @required FiatConvertationService fiatConvertationService,
    @required Box<Template> templates,
    @required Box<ExchangeTemplate> exchangeTemplates,
      int initialMigrationVersion = 3}) async {
  await defaultSettingsMigration(
      version: initialMigrationVersion,
      sharedPreferences: sharedPreferences,
      nodes: nodes);
  await setup(
      walletInfoSource: walletInfoSource,
      nodeSource: nodes,
      contactSource: contactSource,
      tradesSource: tradesSource,
      templates: templates,
      exchangeTemplates: exchangeTemplates);
  await bootstrap(fiatConvertationService: fiatConvertationService);
  monero_wallet.onStartup();
}

class CakeWalletApp extends StatelessWidget {
  CakeWalletApp() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);

    return ChangeNotifierProvider<ThemeChanger>(
        create: (_) => ThemeChanger(
            settingsStore.isDarkTheme ? Themes.darkTheme : Themes.lightTheme),
        child: ChangeNotifierProvider<Language>(
            create: (_) => Language(settingsStore.languageCode),
            child: MaterialAppWithTheme()));
  }
}

class MaterialAppWithTheme extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sharedPreferences = Provider.of<SharedPreferences>(context);
    final walletService = Provider.of<WalletService>(context);
    final walletListService = Provider.of<WalletListService>(context);
    final userService = Provider.of<UserService>(context);
    final settingsStore = Provider.of<SettingsStore>(context);
    final priceStore = Provider.of<PriceStore>(context);
    final walletStore = Provider.of<WalletStore>(context);
    final syncStore = Provider.of<SyncStore>(context);
    final balanceStore = Provider.of<BalanceStore>(context);
    final theme = Provider.of<ThemeChanger>(context);
    final currentLanguage = Provider.of<Language>(context);
    final contacts = Provider.of<Box<Contact>>(context);
    final nodes = Provider.of<Box<Node>>(context);
    final trades = Provider.of<Box<Trade>>(context);
    final transactionDescriptions =
        Provider.of<Box<TransactionDescription>>(context);

    final statusBarColor =
        settingsStore.isDarkTheme ? Colors.black : Colors.white;
    final statusBarBrightness =
        settingsStore.isDarkTheme ? Brightness.light : Brightness.dark;
    final statusBarIconBrightness =
        settingsStore.isDarkTheme ? Brightness.light : Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarBrightness: statusBarBrightness,
        statusBarIconBrightness: statusBarIconBrightness));

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme.getTheme(),
        localizationsDelegates: [
          S.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: Locale(currentLanguage.getCurrentLanguage()),
        onGenerateRoute: (settings) => Router.generateRoute(
            sharedPreferences: sharedPreferences,
            walletListService: walletListService,
            walletService: walletService,
            userService: userService,
            settings: settings,
            priceStore: priceStore,
            walletStore: walletStore,
            syncStore: syncStore,
            balanceStore: balanceStore,
            settingsStore: settingsStore,
            contacts: contacts,
            nodes: nodes,
            trades: trades,
            transactionDescriptions: transactionDescriptions),
        home: Root(
          authenticationStore: getIt.get<AuthenticationStore>(),
        ));
  }
}