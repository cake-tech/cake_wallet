import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cake_wallet/themes/theme_list.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/di.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
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
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/src/screens/root/root.dart';
import 'package:uni_links/uni_links.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final rootKey = GlobalKey<RootState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (errorDetails) {
      _onError(errorDetails);
    };

    /// A callback that is invoked when an unhandled error occurs in the root
    /// isolate.
    PlatformDispatcher.instance.onError = (error, stack) {
      _onError(FlutterErrorDetails(exception: error, stack: stack));

      return true;
    };

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

    if (!isMoneroOnly && !Hive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
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
    Box<UnspentCoinsInfo>? unspentCoinsInfoSource;
    
    if (!isMoneroOnly) {
      unspentCoinsInfoSource = await Hive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
    }
    
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
        initialMigrationVersion: 19);
    runApp(App());
  }, (error, stackTrace) async {
    _onError(FlutterErrorDetails(exception: error, stack: stackTrace));
  });
}

void _saveException(String? error, StackTrace? stackTrace) async {
  final appDocDir = await getApplicationDocumentsDirectory();

  final file = File('${appDocDir.path}/error.txt');
  final exception = {
    "${DateTime.now()}": {
      "Error": error,
      "StackTrace": stackTrace.toString(),
    }
  };

  const String separator =
      '''\n\n==========================================================
      ==========================================================\n\n''';

  await file.writeAsString(
    jsonEncode(exception) + separator,
    mode: FileMode.append,
  );
}

void _sendExceptionFile() async {
  try {
    final appDocDir = await getApplicationDocumentsDirectory();

    final file = File('${appDocDir.path}/error.txt');

    final MailOptions mailOptions = MailOptions(
      subject: 'Mobile App Issue',
      recipients: ['support@cakewallet.com'],
      attachments: [file.path],
    );

    final result = await FlutterMailer.send(mailOptions);

    // Clear file content if the error was sent or saved.
    // On android we can't know if it was sent or saved
    if (result.name == MailerResponse.sent.name ||
        result.name == MailerResponse.saved.name ||
        result.name == MailerResponse.android.name) {
      file.writeAsString("", mode: FileMode.write);
    }
  } catch (e, s) {
    _saveException(e.toString(), s);
  }
}

void _onError(FlutterErrorDetails errorDetails) {
  _saveException(errorDetails.exception.toString(), errorDetails.stack);

  WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        showPopUp<void>(
          context: navigatorKey.currentContext!,
          builder: (context) {
            return AlertWithTwoActions(
              isDividerExist: true,
              alertTitle: S.of(context).error,
              alertContent: S.of(context).error_dialog_content,
              rightButtonText: S.of(context).send,
              leftButtonText: S.of(context).do_not_send,
              actionRightButton: () {
                Navigator.of(context).pop();
                _sendExceptionFile();
              },
              actionLeftButton: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
    },
  );
}

Future<void> initialSetup(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodes,
    required Box<WalletInfo> walletInfoSource,
    required Box<Contact> contactSource,
    required Box<Trade> tradesSource,
    required Box<Order> ordersSource,
    // required FiatConvertationService fiatConvertationService,
    required Box<Template> templates,
    required Box<ExchangeTemplate> exchangeTemplates,
    required Box<TransactionDescription> transactionDescriptions,
    required FlutterSecureStorage secureStorage,
    Box<UnspentCoinsInfo>? unspentCoinsInfoSource,
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
      unspentCoinsInfoSource: unspentCoinsInfoSource,
      );
  await bootstrap(navigatorKey);
  monero?.onStartup();
}

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> with SingleTickerProviderStateMixin {
  AppState()
    : yatStore = getIt.get<YatStore>() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  YatStore yatStore;
  StreamSubscription? stream;

  @override
  void initState() {
    super.initState();
    //_handleIncomingLinks();
    //_handleInitialUri();
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      print('uri: $uri');
      if (uri == null) {
        return;
      }
      if (!mounted) return;
      //_fetchEmojiFromUri(uri);
    } catch (e) {
      if (!mounted) return;
      print(e.toString());
    }
  }

  void _handleIncomingLinks() {
    if (!kIsWeb) {
      stream = getUriLinksStream().listen((Uri? uri) {
        print('uri: $uri');
        if (!mounted) return;
        //_fetchEmojiFromUri(uri);
      }, onError: (Object error) {
        if (!mounted) return;
        print('Error: $error');
      });
    }
  }

  void _fetchEmojiFromUri(Uri uri) {
    //final queryParameters = uri.queryParameters;
    //if (queryParameters?.isEmpty ?? true) {
    //  return;
    //}
    //final emoji = queryParameters['eid'];
    //final refreshToken = queryParameters['refresh_token'];
    //if ((emoji?.isEmpty ?? true)||(refreshToken?.isEmpty ?? true)) {
    //  return;
    //}
    //yatStore.emoji = emoji;
    //yatStore.refreshToken = refreshToken;
    //yatStore.emojiIncommingSC.add(emoji);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (BuildContext context) {
      final appStore = getIt.get<AppStore>();
      final authService = getIt.get<AuthService>();
      final settingsStore = appStore.settingsStore;
      final statusBarColor = Colors.transparent;
      final authenticationStore = getIt.get<AuthenticationStore>();
      final initialRoute =
      authenticationStore.state == AuthenticationState.uninitialized
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
          key: rootKey,
          appStore: appStore,
          authenticationStore: authenticationStore,
          navigatorKey: navigatorKey,
          authService: authService,
          child: MaterialApp(
            navigatorObservers: [routeObserver],
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
