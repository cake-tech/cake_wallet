import 'package:cake_wallet/bitcoin/bitcoin_wallet_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/exchange/trade.dart';

import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_confirm_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_page.dart';
import 'package:cake_wallet/src/screens/faq/faq_page.dart';
import 'package:cake_wallet/src/screens/nodes/node_create_or_edit_page.dart';
import 'package:cake_wallet/src/screens/nodes/nodes_list_page.dart';
import 'package:cake_wallet/src/screens/rescan/rescan_page.dart';
import 'package:cake_wallet/src/screens/seed/wallet_seed_page.dart';
import 'package:cake_wallet/src/screens/send/send_template_page.dart';
import 'package:cake_wallet/src/screens/settings/change_language.dart';
import 'package:cake_wallet/src/screens/settings/settings.dart';
import 'package:cake_wallet/src/screens/setup_pin_code/setup_pin_code.dart';
import 'package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_template_page.dart';
import 'package:cake_wallet/store/node_list_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cake_wallet/src/screens/receive/receive_page.dart';
import 'package:cake_wallet/src/screens/send/send_page.dart';
import 'package:cake_wallet/src/screens/subaddress/address_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:cake_wallet/store/wallet_list_store.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/rescan_view_model.dart';
import 'package:cake_wallet/view_model/setup_pin_code_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/auth_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:cake_wallet/view_model/wallet_keys_view_model.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/view_model/wallet_seed_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/view_model/wallet_restoration_from_seed_vm.dart';
import 'package:cake_wallet/view_model/wallet_restoration_from_keys_vm.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';

final getIt = GetIt.instance;

Future setup(
    {Box<WalletInfo> walletInfoSource,
    Box<Node> nodeSource,
    Box<Contact> contactSource,
    Box<Trade> tradesSource,
    Box<Template> templates,
    Box<ExchangeTemplate> exchangeTemplates}) async {
  getIt.registerSingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance());

  final settingsStore = await SettingsStoreBase.load(nodeSource: nodeSource);

  getIt.registerSingleton<Box<Node>>(nodeSource);

  getIt.registerSingleton<FlutterSecureStorage>(FlutterSecureStorage());
  getIt.registerSingleton(AuthenticationStore());
  getIt.registerSingleton<WalletListStore>(WalletListStore());
  getIt.registerSingleton(NodeListStoreBase.instance);
  getIt.registerSingleton<SettingsStore>(settingsStore);
  getIt.registerSingleton<AppStore>(AppStore(
      authenticationStore: getIt.get<AuthenticationStore>(),
      walletList: getIt.get<WalletListStore>(),
      settingsStore: getIt.get<SettingsStore>(),
      nodeListStore: getIt.get<NodeListStore>()));
  getIt.registerSingleton<TradesStore>(TradesStore(
      tradesSource: tradesSource, settingsStore: getIt.get<SettingsStore>()));
  getIt.registerSingleton<TradeFilterStore>(TradeFilterStore());
  getIt.registerSingleton<TransactionFilterStore>(TransactionFilterStore());
  getIt.registerSingleton<FiatConversionStore>(FiatConversionStore());
  getIt.registerSingleton<SendTemplateStore>(
      SendTemplateStore(templateSource: templates));
  getIt.registerSingleton<ExchangeTemplateStore>(
      ExchangeTemplateStore(templateSource: exchangeTemplates));

  getIt.registerFactory<KeyService>(
      () => KeyService(getIt.get<FlutterSecureStorage>()));

  getIt.registerFactoryParam<WalletCreationService, WalletType, void>(
      (type, _) => WalletCreationService(
          initialType: type,
          keyService: getIt.get<KeyService>(),
          secureStorage: getIt.get<FlutterSecureStorage>(),
          sharedPreferences: getIt.get<SharedPreferences>()));

  getIt.registerFactoryParam<WalletNewVM, WalletType, void>((type, _) =>
      WalletNewVM(getIt.get<AppStore>(),
          getIt.get<WalletCreationService>(param1: type), walletInfoSource,
          type: type));

  getIt
      .registerFactoryParam<WalletRestorationFromSeedVM, List, void>((args, _) {
    final type = args.first as WalletType;
    final language = args[1] as String;
    final mnemonic = args[2] as String;

    return WalletRestorationFromSeedVM(getIt.get<AppStore>(),
        getIt.get<WalletCreationService>(param1: type), walletInfoSource,
        type: type, language: language, seed: mnemonic);
  });

  getIt
      .registerFactoryParam<WalletRestorationFromKeysVM, List, void>((args, _) {
    final type = args.first as WalletType;
    final language = args[1] as String;

    return WalletRestorationFromKeysVM(getIt.get<AppStore>(),
        getIt.get<WalletCreationService>(param1: type), walletInfoSource,
        type: type, language: language);
  });

  getIt.registerFactory<WalletAddressListViewModel>(
      () => WalletAddressListViewModel(wallet: getIt.get<AppStore>().wallet));

  getIt.registerFactory(() => BalanceViewModel(
      appStore: getIt.get<AppStore>(),
      settingsStore: getIt.get<SettingsStore>(),
      fiatConvertationStore: getIt.get<FiatConversionStore>()));

  getIt.registerFactory(() => DashboardViewModel(
      balanceViewModel: getIt.get<BalanceViewModel>(),
      appStore: getIt.get<AppStore>(),
      tradesStore: getIt.get<TradesStore>(),
      tradeFilterStore: getIt.get<TradeFilterStore>(),
      transactionFilterStore: getIt.get<TransactionFilterStore>()));

  getIt.registerFactory<AuthService>(() => AuthService(
      secureStorage: getIt.get<FlutterSecureStorage>(),
      sharedPreferences: getIt.get<SharedPreferences>()));

  getIt.registerFactory<AuthViewModel>(() => AuthViewModel(
      getIt.get<AuthService>(),
      getIt.get<SharedPreferences>(),
      getIt.get<SettingsStore>(),
      BiometricAuth()));

  getIt.registerFactory<AuthPage>(
      () => AuthPage(getIt.get<AuthViewModel>(), onAuthenticationFinished:
              (isAuthenticated, AuthPageState authPageState) {
            if (!isAuthenticated) {
              return;
            }
            final authStore = getIt.get<AuthenticationStore>();
            final appStore = getIt.get<AppStore>();

            if (appStore.wallet != null) {
              authStore.allowed();
              return;
            }

            authPageState.changeProcessText('Loading the wallet');
            ReactionDisposer _reaction;
            _reaction = reaction((_) => appStore.wallet, (Object _) {
              _reaction?.reaction?.dispose();
              authStore.allowed();
            });
          }, closable: false),
      instanceName: 'login');

  getIt
      .registerFactoryParam<AuthPage, void Function(bool, AuthPageState), bool>(
          (onAuthFinished, closable) => AuthPage(getIt.get<AuthViewModel>(),
              onAuthenticationFinished: onAuthFinished,
              closable: closable ?? false));

  getIt.registerFactory<DashboardPage>(() => DashboardPage(
      walletViewModel: getIt.get<DashboardViewModel>(),
      addressListViewModel: getIt.get<WalletAddressListViewModel>()));

  getIt.registerFactory<ReceivePage>(() => ReceivePage(
      addressListViewModel: getIt.get<WalletAddressListViewModel>()));

  getIt.registerFactoryParam<WalletAddressEditOrCreateViewModel, dynamic, void>(
      (dynamic item, _) => WalletAddressEditOrCreateViewModel(
          wallet: getIt.get<AppStore>().wallet, item: item));

  getIt.registerFactoryParam<AddressEditOrCreatePage, dynamic, void>(
      (dynamic item, _) => AddressEditOrCreatePage(
          addressEditOrCreateViewModel:
              getIt.get<WalletAddressEditOrCreateViewModel>(param1: item)));

  // getIt.get<SendTemplateStore>()
  getIt.registerFactory<SendViewModel>(() => SendViewModel(
      getIt.get<AppStore>().wallet,
      getIt.get<AppStore>().settingsStore,
      getIt.get<FiatConversionStore>()));

  getIt.registerFactory(
      () => SendPage(sendViewModel: getIt.get<SendViewModel>()));

  getIt.registerFactory(
      () => SendTemplatePage(sendViewModel: getIt.get<SendViewModel>()));

  getIt.registerFactory(() => WalletListViewModel(
      walletInfoSource, getIt.get<AppStore>(), getIt.get<KeyService>()));

  getIt.registerFactory(() =>
      WalletListPage(walletListViewModel: getIt.get<WalletListViewModel>()));

  getIt.registerFactory(() {
    final wallet = getIt.get<AppStore>().wallet;

    if (wallet is MoneroWallet) {
      return MoneroAccountListViewModel(wallet);
    }

    // FIXME: throw exception.
    return null;
  });

  getIt.registerFactory(() => MoneroAccountListPage(
      accountListViewModel: getIt.get<MoneroAccountListViewModel>()));

  getIt.registerFactory(() {
    final wallet = getIt.get<AppStore>().wallet;

    if (wallet is MoneroWallet) {
      return MoneroAccountEditOrCreateViewModel(wallet.accountList);
    }

    // FIXME: throw exception.
    return null;
  });

  getIt.registerFactory(() => MoneroAccountEditOrCreatePage(
      moneroAccountCreationViewModel:
          getIt.get<MoneroAccountEditOrCreateViewModel>()));

  getIt.registerFactory(() {
    final appStore = getIt.get<AppStore>();
    return SettingsViewModel(appStore.settingsStore, appStore.wallet);
  });

  getIt.registerFactory(() => SettingsPage(getIt.get<SettingsViewModel>()));

  getIt
      .registerFactory(() => WalletSeedViewModel(getIt.get<AppStore>().wallet));

  getIt.registerFactoryParam<WalletSeedPage, bool, void>(
      (bool isWalletCreated, _) => WalletSeedPage(
          getIt.get<WalletSeedViewModel>(),
          isNewWalletCreated: isWalletCreated));

  getIt
      .registerFactory(() => WalletKeysViewModel(getIt.get<AppStore>().wallet));

  getIt.registerFactory(() => WalletKeysPage(getIt.get<WalletKeysViewModel>()));

  getIt.registerFactoryParam<ContactViewModel, ContactRecord, void>(
      (ContactRecord contact, _) =>
          ContactViewModel(contactSource, contact: contact));

  getIt.registerFactory(() => ContactListViewModel(contactSource));

  getIt.registerFactoryParam<ContactListPage, bool, void>(
      (bool isEditable, _) => ContactListPage(getIt.get<ContactListViewModel>(),
          isEditable: isEditable));

  getIt.registerFactoryParam<ContactPage, ContactRecord, void>(
      (ContactRecord contact, _) =>
          ContactPage(getIt.get<ContactViewModel>(param1: contact)));

  getIt.registerFactory(() {
    final appStore = getIt.get<AppStore>();
    return NodeListViewModel(
        nodeSource, appStore.wallet, appStore.settingsStore);
  });

  getIt.registerFactory(() => NodeListPage(getIt.get<NodeListViewModel>()));

  getIt.registerFactory(() =>
      NodeCreateOrEditViewModel(nodeSource, getIt.get<AppStore>().wallet));

  getIt.registerFactory(
      () => NodeCreateOrEditPage(getIt.get<NodeCreateOrEditViewModel>()));

  getIt.registerFactory(() => ExchangeViewModel(
      wallet: getIt.get<AppStore>().wallet,
      exchangeTemplateStore: getIt.get<ExchangeTemplateStore>(),
      trades: tradesSource,
      tradesStore: getIt.get<TradesStore>()));

  getIt.registerFactory(() => ExchangeTradeViewModel(
      wallet: getIt.get<AppStore>().wallet,
      trades: tradesSource,
      tradesStore: getIt.get<TradesStore>()));

  getIt.registerFactory(() => ExchangePage(getIt.get<ExchangeViewModel>()));

  getIt.registerFactory(
      () => ExchangeConfirmPage(tradesStore: getIt.get<TradesStore>()));

  getIt.registerFactory(() => ExchangeTradePage(
      exchangeTradeViewModel: getIt.get<ExchangeTradeViewModel>()));

  getIt.registerFactory(
      () => ExchangeTemplatePage(getIt.get<ExchangeViewModel>()));

  getIt.registerFactory(() => MoneroWalletService(walletInfoSource));

  getIt.registerFactory(() => BitcoinWalletService());

  getIt.registerFactoryParam<WalletService, WalletType, void>(
      (WalletType param1, __) {
    switch (param1) {
      case WalletType.monero:
        return getIt.get<MoneroWalletService>();
      case WalletType.bitcoin:
        return getIt.get<BitcoinWalletService>();
      default:
        return null;
    }
  });

  getIt.registerFactory<SetupPinCodeViewModel>(() => SetupPinCodeViewModel(
      getIt.get<AuthService>(), getIt.get<SettingsStore>()));

  getIt.registerFactoryParam<SetupPinCodePage,
          void Function(BuildContext, String), void>(
      (onSuccessfulPinSetup, _) => SetupPinCodePage(
          getIt.get<SetupPinCodeViewModel>(),
          onSuccessfulPinSetup: onSuccessfulPinSetup));

  getIt.registerFactory(() => RescanViewModel(getIt.get<AppStore>().wallet));

  getIt.registerFactory(() => RescanPage(getIt.get<RescanViewModel>()));

  getIt.registerFactory(() => FaqPage(getIt.get<SettingsStore>()));

  getIt.registerFactory(() => LanguageListPage(getIt.get<SettingsStore>()));
}
