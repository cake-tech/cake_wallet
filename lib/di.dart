import 'package:cake_wallet/core/contact_service.dart';
import 'package:cake_wallet/src/domain/common/contact.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_page.dart';
import 'package:cake_wallet/src/screens/nodes/node_create_or_edit_page.dart';
import 'package:cake_wallet/src/screens/nodes/nodes_list_page.dart';
import 'package:cake_wallet/src/screens/seed/wallet_seed_page.dart';
import 'package:cake_wallet/src/screens/send/send_template_page.dart';
import 'package:cake_wallet/src/screens/settings/settings.dart';
import 'package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_template_page.dart';
import 'package:cake_wallet/store/contact_list_store.dart';
import 'package:cake_wallet/store/node_list_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';
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
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/auth_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cake_wallet/view_model/send_view_model.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:cake_wallet/view_model/wallet_keys_view_model.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/view_model/wallet_seed_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/view_model/wallet_restoration_from_seed_vm.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_convertation_store.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/src/domain/common/template.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_template.dart';

final getIt = GetIt.instance;

// FIXME: Move me.

Stream<BoxEvent> _onNodesSourceChange;
NodeListStore _nodeListStore;

NodeListStore setupNodeListStore(Box<Node> nodeSource) {
  if (_nodeListStore != null) {
    return _nodeListStore;
  }

  _nodeListStore = NodeListStore();
  _nodeListStore.replaceValues(nodeSource.values);
  _onNodesSourceChange = nodeSource.watch();
  _onNodesSourceChange
      .listen((_) => _nodeListStore.replaceValues(nodeSource.values));

  return _nodeListStore;
}

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

  getIt.registerSingleton<FlutterSecureStorage>(FlutterSecureStorage());
  getIt.registerSingleton(AuthenticationStore());
  getIt.registerSingleton<WalletListStore>(WalletListStore());
  getIt.registerSingleton(ContactListStore());
  getIt.registerSingleton(setupNodeListStore(nodeSource));
  getIt.registerSingleton<SettingsStore>(settingsStore);
  getIt.registerSingleton<AppStore>(AppStore(
      authenticationStore: getIt.get<AuthenticationStore>(),
      walletList: getIt.get<WalletListStore>(),
      settingsStore: getIt.get<SettingsStore>(),
      contactListStore: getIt.get<ContactListStore>(),
      nodeListStore: getIt.get<NodeListStore>()));
  getIt.registerSingleton<ContactService>(
      ContactService(contactSource, getIt.get<AppStore>().contactListStore));
  getIt.registerSingleton<TradesStore>(TradesStore(
      tradesSource: tradesSource,
      settingsStore: getIt.get<SettingsStore>()));
  getIt.registerSingleton<TradeFilterStore>(
      TradeFilterStore(wallet: getIt.get<AppStore>().wallet));
  getIt.registerSingleton<TransactionFilterStore>(TransactionFilterStore());
  getIt.registerSingleton<FiatConvertationStore>(FiatConvertationStore());
  getIt.registerSingleton<SendTemplateStore>(
      SendTemplateStore(templateSource: templates));
  getIt.registerSingleton<ExchangeTemplateStore>(
      ExchangeTemplateStore(templateSource: exchangeTemplates));

  getIt.registerFactory<KeyService>(
      () => KeyService(getIt.get<FlutterSecureStorage>()));

  getIt.registerFactoryParam<WalletCreationService, WalletType, void>(
      (type, _) => WalletCreationService(
          initialType: type,
          appStore: getIt.get<AppStore>(),
          keyService: getIt.get<KeyService>(),
          secureStorage: getIt.get<FlutterSecureStorage>(),
          sharedPreferences: getIt.get<SharedPreferences>()));

  getIt.registerFactoryParam<WalletNewVM, WalletType, void>((type, _) =>
      WalletNewVM(
          getIt.get<WalletCreationService>(param1: type), walletInfoSource,
          type: type));

  getIt
      .registerFactoryParam<WalletRestorationFromSeedVM, List, void>((args, _) {
    final type = args.first as WalletType;
    final language = args[1] as String;
    final mnemonic = args[2] as String;

    return WalletRestorationFromSeedVM(
        getIt.get<WalletCreationService>(param1: type), walletInfoSource,
        type: type, language: language, seed: mnemonic);
  });

  getIt.registerFactory<WalletAddressListViewModel>(
      () => WalletAddressListViewModel(wallet: getIt.get<AppStore>().wallet));

  getIt.registerFactory(
      () => BalanceViewModel(
            wallet: getIt.get<AppStore>().wallet,
            settingsStore: getIt.get<SettingsStore>(),
            fiatConvertationStore: getIt.get<FiatConvertationStore>()));

  getIt.registerFactory(
      () => DashboardViewModel(
          balanceViewModel: getIt.get<BalanceViewModel>(),
          appStore: getIt.get<AppStore>(),
          tradesStore: getIt.get<TradesStore>(),
          tradeFilterStore: getIt.get<TradeFilterStore>(),
          transactionFilterStore: getIt.get<TransactionFilterStore>()
      ));

  getIt.registerFactory<AuthService>(() => AuthService(
      secureStorage: getIt.get<FlutterSecureStorage>(),
      sharedPreferences: getIt.get<SharedPreferences>()));

  getIt.registerFactory<AuthViewModel>(() => AuthViewModel(
      authService: getIt.get<AuthService>(),
      sharedPreferences: getIt.get<SharedPreferences>()));

  getIt.registerFactory<AuthPage>(
      () => AuthPage(
          authViewModel: getIt.get<AuthViewModel>(),
          onAuthenticationFinished: (isAuthenticated, __) {
            if (isAuthenticated) {
              getIt.get<AuthenticationStore>().allowed();
            }
          },
          closable: false),
      instanceName: 'login');

  getIt
      .registerFactoryParam<AuthPage, void Function(bool, AuthPageState), void>(
          (onAuthFinished, _) => AuthPage(
              authViewModel: getIt.get<AuthViewModel>(),
              onAuthenticationFinished: onAuthFinished,
              closable: false));

  getIt.registerFactory<DashboardPage>(
      () => DashboardPage(
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

  getIt.registerFactory<SendViewModel>(() => SendViewModel(
      getIt.get<AppStore>().wallet,
      getIt.get<AppStore>().settingsStore,
      getIt.get<FiatConvertationStore>(),
      getIt.get<SendTemplateStore>()));

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

  getIt.registerFactory(
      () => SettingsViewModel(getIt.get<AppStore>().settingsStore));

  getIt.registerFactory(() => SettingsPage(getIt.get<SettingsViewModel>()));

  getIt
      .registerFactory(() => WalletSeedViewModel(getIt.get<AppStore>().wallet));

  getIt.registerFactoryParam<WalletSeedPage, VoidCallback, void>(
      (VoidCallback callback, _) => WalletSeedPage(
          getIt.get<WalletSeedViewModel>(),
          onCloseCallback: callback));

  getIt
      .registerFactory(() => WalletKeysViewModel(getIt.get<AppStore>().wallet));

  getIt.registerFactory(() => WalletKeysPage(getIt.get<WalletKeysViewModel>()));

  getIt.registerFactoryParam<ContactViewModel, Contact, void>(
      (Contact contact, _) => ContactViewModel(
          getIt.get<ContactService>(), getIt.get<AppStore>().wallet,
          contact: contact));

  getIt.registerFactory(() => ContactListViewModel(
      getIt.get<AppStore>().contactListStore, getIt.get<ContactService>()));

  getIt.registerFactory(
      () => ContactListPage(getIt.get<ContactListViewModel>()));

  getIt.registerFactoryParam<ContactPage, Contact, void>((Contact contact, _) =>
      ContactPage(getIt.get<ContactViewModel>(param1: contact)));

  getIt.registerFactory(() => NodeListViewModel(
      getIt.get<AppStore>().nodeListStore,
      nodeSource,
      getIt.get<AppStore>().wallet));

  getIt.registerFactory(() => NodeListPage(getIt.get<NodeListViewModel>()));

  getIt.registerFactory(() =>
      NodeCreateOrEditViewModel(nodeSource, getIt.get<AppStore>().wallet));

  getIt.registerFactory(
      () => NodeCreateOrEditPage(getIt.get<NodeCreateOrEditViewModel>()));

  getIt.registerFactory(() =>
      ExchangeViewModel(
        wallet: getIt.get<AppStore>().wallet,
        exchangeTemplateStore: getIt.get<ExchangeTemplateStore>(),
        trades: tradesSource
      ));

  getIt.registerFactory(() =>
      ExchangePage(getIt.get<ExchangeViewModel>()));

  getIt.registerFactory(() =>
      ExchangeTemplatePage(getIt.get<ExchangeViewModel>()));
}
