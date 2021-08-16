import 'package:cake_wallet/bitcoin/bitcoin_wallet_service.dart';
import 'package:cake_wallet/bitcoin/litecoin_wallet_service.dart';
import 'package:cake_wallet/bitcoin/unspent_coins_info.dart';
import 'package:cake_wallet/core/backup_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/reactions/on_authentication_state_change.dart';
import 'package:cake_wallet/src/screens/backup/backup_page.dart';
import 'package:cake_wallet/src/screens/backup/edit_backup_password_page.dart';
import 'package:cake_wallet/src/screens/buy/buy_webview_page.dart';
import 'package:cake_wallet/src/screens/buy/pre_order_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_confirm_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_page.dart';
import 'package:cake_wallet/src/screens/faq/faq_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/new_wallet_type_page.dart';
import 'package:cake_wallet/src/screens/nodes/node_create_or_edit_page.dart';
import 'package:cake_wallet/src/screens/nodes/nodes_list_page.dart';
import 'package:cake_wallet/src/screens/order_details/order_details_page.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/rescan/rescan_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_from_backup_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_options_page.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_page.dart';
import 'package:cake_wallet/src/screens/seed/pre_seed_page.dart';
import 'package:cake_wallet/src/screens/seed/wallet_seed_page.dart';
import 'package:cake_wallet/src/screens/send/send_template_page.dart';
import 'package:cake_wallet/src/screens/settings/change_language.dart';
import 'package:cake_wallet/src/screens/settings/settings.dart';
import 'package:cake_wallet/src/screens/setup_pin_code/setup_pin_code.dart';
import 'package:cake_wallet/src/screens/support/support_page.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_page.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/unspent_coins_details_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/unspent_coins_list_page.dart';
import 'package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_template_page.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/node_list_store.dart';
import 'package:cake_wallet/store/secret_store.dart';
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
import 'package:cake_wallet/view_model/backup_view_model.dart';
import 'package:cake_wallet/view_model/buy/buy_amount_view_model.dart';
import 'package:cake_wallet/view_model/buy/buy_view_model.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cake_wallet/view_model/edit_backup_password_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/order_details_view_model.dart';
import 'package:cake_wallet/view_model/rescan_view_model.dart';
import 'package:cake_wallet/view_model/restore_from_backup_view_model.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:cake_wallet/view_model/setup_pin_code_view_model.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:cake_wallet/view_model/trade_details_view_model.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_details_view_model.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
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
import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
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
import 'package:cake_wallet/.secrets.g.dart' as secrets;

final getIt = GetIt.instance;

var _isSetupFinished = false;
Box<WalletInfo> _walletInfoSource;
Box<Node> _nodeSource;
Box<Contact> _contactSource;
Box<Trade> _tradesSource;
Box<Template> _templates;
Box<ExchangeTemplate> _exchangeTemplates;
Box<TransactionDescription> _transactionDescriptionBox;
Box<Order> _ordersSource;
Box<UnspentCoinsInfo> _unspentCoinsInfoSource;

Future setup(
    {Box<WalletInfo> walletInfoSource,
    Box<Node> nodeSource,
    Box<Contact> contactSource,
    Box<Trade> tradesSource,
    Box<Template> templates,
    Box<ExchangeTemplate> exchangeTemplates,
    Box<TransactionDescription> transactionDescriptionBox,
    Box<Order> ordersSource,
    Box<UnspentCoinsInfo> unspentCoinsInfoSource}) async {
  _walletInfoSource = walletInfoSource;
  _nodeSource = nodeSource;
  _contactSource = contactSource;
  _tradesSource = tradesSource;
  _templates = templates;
  _exchangeTemplates = exchangeTemplates;
  _transactionDescriptionBox = transactionDescriptionBox;
  _ordersSource = ordersSource;
  _unspentCoinsInfoSource = unspentCoinsInfoSource;

  if (!_isSetupFinished) {
    getIt.registerSingletonAsync<SharedPreferences>(
        () => SharedPreferences.getInstance());
  }

  final isBitcoinBuyEnabled = (secrets.wyreSecretKey?.isNotEmpty ?? false) &&
      (secrets.wyreApiKey?.isNotEmpty ?? false) &&
      (secrets.wyreAccountId?.isNotEmpty ?? false);

  final settingsStore = await SettingsStoreBase.load(
      nodeSource: _nodeSource, isBitcoinBuyEnabled: isBitcoinBuyEnabled);

  if (_isSetupFinished) {
    return;
  }

  getIt.registerFactory<Box<Node>>(() => _nodeSource);

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
      tradesSource: _tradesSource, settingsStore: getIt.get<SettingsStore>()));
  getIt.registerSingleton<OrdersStore>(OrdersStore(
      ordersSource: _ordersSource, settingsStore: getIt.get<SettingsStore>()));
  getIt.registerSingleton<TradeFilterStore>(TradeFilterStore());
  getIt.registerSingleton<TransactionFilterStore>(TransactionFilterStore());
  getIt.registerSingleton<FiatConversionStore>(FiatConversionStore());
  getIt.registerSingleton<SendTemplateStore>(
      SendTemplateStore(templateSource: _templates));
  getIt.registerSingleton<ExchangeTemplateStore>(
      ExchangeTemplateStore(templateSource: _exchangeTemplates));

  final secretStore =
      await SecretStoreBase.load(getIt.get<FlutterSecureStorage>());

  getIt.registerSingleton<SecretStore>(secretStore);

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
          getIt.get<WalletCreationService>(param1: type), _walletInfoSource,
          type: type));

  getIt
      .registerFactoryParam<WalletRestorationFromSeedVM, List, void>((args, _) {
    final type = args.first as WalletType;
    final language = args[1] as String;
    final mnemonic = args[2] as String;

    return WalletRestorationFromSeedVM(getIt.get<AppStore>(),
        getIt.get<WalletCreationService>(param1: type), _walletInfoSource,
        type: type, language: language, seed: mnemonic);
  });

  getIt
      .registerFactoryParam<WalletRestorationFromKeysVM, List, void>((args, _) {
    final type = args.first as WalletType;
    final language = args[1] as String;

    return WalletRestorationFromKeysVM(getIt.get<AppStore>(),
        getIt.get<WalletCreationService>(param1: type), _walletInfoSource,
        type: type, language: language);
  });

  getIt.registerFactory<WalletAddressListViewModel>(
      () => WalletAddressListViewModel(appStore: getIt.get<AppStore>()));

  getIt.registerFactory(() => BalanceViewModel(
      appStore: getIt.get<AppStore>(),
      settingsStore: getIt.get<SettingsStore>(),
      fiatConvertationStore: getIt.get<FiatConversionStore>()));

  getIt.registerFactory(() => DashboardViewModel(
      balanceViewModel: getIt.get<BalanceViewModel>(),
      appStore: getIt.get<AppStore>(),
      tradesStore: getIt.get<TradesStore>(),
      tradeFilterStore: getIt.get<TradeFilterStore>(),
      transactionFilterStore: getIt.get<TransactionFilterStore>(),
      settingsStore: settingsStore,
      ordersStore: getIt.get<OrdersStore>()));

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

            if (loginError != null) {
              authPageState
                  .changeProcessText('ERROR: ${loginError.toString()}');
            }

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

  getIt.registerFactory<SendTemplateViewModel>(() => SendTemplateViewModel(
      getIt.get<AppStore>().wallet,
      getIt.get<AppStore>().settingsStore,
      getIt.get<SendTemplateStore>(),
      getIt.get<FiatConversionStore>()
  ));

  getIt.registerFactory<SendViewModel>(() => SendViewModel(
      getIt.get<AppStore>().wallet,
      getIt.get<AppStore>().settingsStore,
      getIt.get<SendTemplateViewModel>(),
      getIt.get<FiatConversionStore>(),
      _transactionDescriptionBox));

  getIt.registerFactory(
      () => SendPage(sendViewModel: getIt.get<SendViewModel>()));

  getIt.registerFactory(
      () => SendTemplatePage(
          sendTemplateViewModel: getIt.get<SendTemplateViewModel>()));

  getIt.registerFactory(() => WalletListViewModel(
      _walletInfoSource,
      getIt.get<AppStore>(),
      getIt.get<KeyService>(),
      getIt.get<WalletNewVM>(param1: WalletType.monero)));

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

  /*getIt.registerFactory(() {
    final wallet = getIt.get<AppStore>().wallet;

    if (wallet is MoneroWallet) {
      return MoneroAccountEditOrCreateViewModel(wallet.accountList);
    }

    // FIXME: throw exception.
    return null;
  });

  getIt.registerFactory(() => MoneroAccountEditOrCreatePage(
      moneroAccountCreationViewModel:
          getIt.get<MoneroAccountEditOrCreateViewModel>()));*/

  getIt.registerFactoryParam<MoneroAccountEditOrCreateViewModel,
          AccountListItem, void>(
      (AccountListItem account, _) => MoneroAccountEditOrCreateViewModel(
          (getIt.get<AppStore>().wallet as MoneroWallet).walletAddresses.accountList,
          wallet: getIt.get<AppStore>().wallet,
          accountListItem: account));

  getIt.registerFactoryParam<MoneroAccountEditOrCreatePage, AccountListItem,
          void>(
      (AccountListItem account, _) => MoneroAccountEditOrCreatePage(
          moneroAccountCreationViewModel:
              getIt.get<MoneroAccountEditOrCreateViewModel>(param1: account)));

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
          ContactViewModel(_contactSource, contact: contact));

  getIt.registerFactory(
      () => ContactListViewModel(_contactSource, _walletInfoSource));

  getIt.registerFactoryParam<ContactListPage, bool, void>(
      (bool isEditable, _) => ContactListPage(getIt.get<ContactListViewModel>(),
          isEditable: isEditable));

  getIt.registerFactoryParam<ContactPage, ContactRecord, void>(
      (ContactRecord contact, _) =>
          ContactPage(getIt.get<ContactViewModel>(param1: contact)));

  getIt.registerFactory(() {
    final appStore = getIt.get<AppStore>();
    return NodeListViewModel(
        _nodeSource, appStore.wallet, appStore.settingsStore);
  });

  getIt.registerFactory(() => NodeListPage(getIt.get<NodeListViewModel>()));

  getIt.registerFactory(() =>
      NodeCreateOrEditViewModel(_nodeSource, getIt.get<AppStore>().wallet));

  getIt.registerFactory(
      () => NodeCreateOrEditPage(getIt.get<NodeCreateOrEditViewModel>()));

  getIt.registerFactory(() => ExchangeViewModel(
      getIt.get<AppStore>().wallet,
      _tradesSource,
      getIt.get<ExchangeTemplateStore>(),
      getIt.get<TradesStore>(),
      getIt.get<AppStore>().settingsStore));

  getIt.registerFactory(() => ExchangeTradeViewModel(
      wallet: getIt.get<AppStore>().wallet,
      trades: _tradesSource,
      tradesStore: getIt.get<TradesStore>(),
      sendViewModel: getIt.get<SendViewModel>()));

  getIt.registerFactory(() => ExchangePage(getIt.get<ExchangeViewModel>()));

  getIt.registerFactory(
      () => ExchangeConfirmPage(tradesStore: getIt.get<TradesStore>()));

  getIt.registerFactory(() => ExchangeTradePage(
      exchangeTradeViewModel: getIt.get<ExchangeTradeViewModel>()));

  getIt.registerFactory(
      () => ExchangeTemplatePage(getIt.get<ExchangeViewModel>()));

  getIt.registerFactory(() => MoneroWalletService(_walletInfoSource));

  getIt.registerFactory(() =>
      BitcoinWalletService(_walletInfoSource, _unspentCoinsInfoSource));

  getIt.registerFactory(() =>
      LitecoinWalletService(_walletInfoSource, _unspentCoinsInfoSource));

  getIt.registerFactoryParam<WalletService, WalletType, void>(
      (WalletType param1, __) {
    switch (param1) {
      case WalletType.monero:
        return getIt.get<MoneroWalletService>();
      case WalletType.bitcoin:
        return getIt.get<BitcoinWalletService>();
      case WalletType.litecoin:
        return getIt.get<LitecoinWalletService>();
      default:
        return null;
    }
  });

  getIt.registerFactory<SetupPinCodeViewModel>(() => SetupPinCodeViewModel(
      getIt.get<AuthService>(), getIt.get<SettingsStore>()));

  getIt.registerFactoryParam<SetupPinCodePage,
          void Function(PinCodeState<PinCodeWidget>, String), void>(
      (onSuccessfulPinSetup, _) => SetupPinCodePage(
          getIt.get<SetupPinCodeViewModel>(),
          onSuccessfulPinSetup: onSuccessfulPinSetup));

  getIt.registerFactory(() => RescanViewModel(getIt.get<AppStore>().wallet));

  getIt.registerFactory(() => RescanPage(getIt.get<RescanViewModel>()));

  getIt.registerFactory(() => FaqPage(getIt.get<SettingsStore>()));

  getIt.registerFactory(() => LanguageListPage(getIt.get<SettingsStore>()));

  getIt.registerFactoryParam<WalletRestoreViewModel, WalletType, void>(
      (type, _) => WalletRestoreViewModel(getIt.get<AppStore>(),
          getIt.get<WalletCreationService>(param1: type), _walletInfoSource,
          type: type));

  getIt.registerFactoryParam<WalletRestorePage, WalletType, void>((type, _) =>
      WalletRestorePage(getIt.get<WalletRestoreViewModel>(param1: type)));

  getIt
      .registerFactoryParam<TransactionDetailsViewModel, TransactionInfo, void>(
          (TransactionInfo transactionInfo, _) {
            final wallet = getIt.get<AppStore>().wallet;
            return TransactionDetailsViewModel(
                transactionInfo: transactionInfo,
                transactionDescriptionBox: _transactionDescriptionBox,
                wallet: wallet,
                settingsStore: getIt.get<SettingsStore>());
          });

  getIt.registerFactoryParam<TransactionDetailsPage, TransactionInfo, void>(
      (TransactionInfo transactionInfo, _) => TransactionDetailsPage(
          transactionDetailsViewModel:
              getIt.get<TransactionDetailsViewModel>(param1: transactionInfo)));

  getIt.registerFactoryParam<NewWalletTypePage,
          void Function(BuildContext, WalletType), bool>(
      (para1, param2) => NewWalletTypePage(getIt.get<WalletNewVM>(),
          onTypeSelected: para1, isNewWallet: param2));

  getIt.registerFactoryParam<PreSeedPage, WalletType, void>(
      (WalletType type, _) => PreSeedPage(type));

  getIt.registerFactoryParam<TradeDetailsViewModel, Trade, void>((trade, _) =>
      TradeDetailsViewModel(tradeForDetails: trade, trades: _tradesSource));

  getIt.registerFactory(() => BackupService(
      getIt.get<FlutterSecureStorage>(),
      _walletInfoSource,
      getIt.get<KeyService>(),
      getIt.get<SharedPreferences>()));

  getIt.registerFactory(() => BackupViewModel(getIt.get<FlutterSecureStorage>(),
      getIt.get<SecretStore>(), getIt.get<BackupService>()));

  getIt.registerFactory(() => BackupPage(getIt.get<BackupViewModel>()));

  getIt.registerFactory(() => EditBackupPasswordViewModel(
      getIt.get<FlutterSecureStorage>(), getIt.get<SecretStore>())
    ..init());

  getIt.registerFactory(
      () => EditBackupPasswordPage(getIt.get<EditBackupPasswordViewModel>()));

  getIt.registerFactory(() => RestoreOptionsPage());

  getIt.registerFactory(
      () => RestoreFromBackupViewModel(getIt.get<BackupService>()));

  getIt.registerFactory(
      () => RestoreFromBackupPage(getIt.get<RestoreFromBackupViewModel>()));

  getIt.registerFactoryParam<TradeDetailsPage, Trade, void>((Trade trade, _) =>
      TradeDetailsPage(getIt.get<TradeDetailsViewModel>(param1: trade)));

  getIt.registerFactory(() => BuyAmountViewModel());

  getIt.registerFactory(() {
    final wallet = getIt.get<AppStore>().wallet;

    return BuyViewModel(_ordersSource, getIt.get<OrdersStore>(),
        getIt.get<SettingsStore>(), getIt.get<BuyAmountViewModel>(),
        wallet: wallet);
  });

  getIt.registerFactory(() {
    return PreOrderPage(buyViewModel: getIt.get<BuyViewModel>());
  });

  getIt.registerFactoryParam<BuyWebViewPage, List, void>(
          (List args, _) {
            final url = args.first as String;
            final buyViewModel = args[1] as BuyViewModel;

            return BuyWebViewPage(buyViewModel: buyViewModel,
                ordersStore: getIt.get<OrdersStore>(), url: url);
          });

  getIt.registerFactoryParam<OrderDetailsViewModel, Order, void>(
          (order, _) {
            final wallet = getIt.get<AppStore>().wallet;

            return OrderDetailsViewModel(
                wallet: wallet,
                orderForDetails: order);
          });

  getIt.registerFactoryParam<OrderDetailsPage, Order, void>((Order order, _) =>
      OrderDetailsPage(getIt.get<OrderDetailsViewModel>(param1: order)));

  getIt.registerFactory(() => SupportViewModel());

  getIt.registerFactory(() => SupportPage(getIt.get<SupportViewModel>()));

  getIt.registerFactory(() {
    final wallet = getIt.get<AppStore>().wallet;

    return UnspentCoinsListViewModel(
        wallet: wallet,
        unspentCoinsInfo: _unspentCoinsInfoSource);
  });

  getIt.registerFactory(() => UnspentCoinsListPage(
    unspentCoinsListViewModel: getIt.get<UnspentCoinsListViewModel>()
  ));

  getIt.registerFactoryParam<UnspentCoinsDetailsViewModel,
      UnspentCoinsItem, UnspentCoinsListViewModel>((item, model) =>
      UnspentCoinsDetailsViewModel(
          unspentCoinsItem: item,
          unspentCoinsListViewModel: model));

  getIt.registerFactoryParam<UnspentCoinsDetailsPage, List, void>(
        (List args, _) {
        final item = args.first as UnspentCoinsItem;
        final unspentCoinsListViewModel = args[1] as UnspentCoinsListViewModel;

        return UnspentCoinsDetailsPage(
            unspentCoinsDetailsViewModel:
              getIt.get<UnspentCoinsDetailsViewModel>(
                  param1: item,
                  param2: unspentCoinsListViewModel));
  });

  _isSetupFinished = true;
}
