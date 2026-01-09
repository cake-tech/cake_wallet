import 'dart:async' show Timer;

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/anonpay/anonpay_api.dart';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/anypay/anypay_api.dart';
import 'package:cake_wallet/arbitrum/arbitrum.dart';
import 'package:cake_wallet/base/base.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/buy/dfx/dfx_buy_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_provider.dart';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/core/backup_service_v3.dart';
import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/new_wallet_type_arguments.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/core/selectable_option.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/core/yat_service.dart';
import 'package:cake_wallet/core/node_switching_service.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/hardware_wallet/require_hardware_wallet_connection.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/haven/cw_haven.dart';
import 'package:cake_wallet/src/screens/dev/monero_background_sync.dart';
import 'package:cake_wallet/src/screens/dev/moneroc_cache_debug.dart';
import 'package:cake_wallet/src/screens/dev/moneroc_call_profiler.dart';
import 'package:cake_wallet/src/screens/dev/network_requests.dart';
import 'package:cake_wallet/src/screens/dev/qr_tools_page.dart';
import 'package:cake_wallet/src/screens/dev/exchange_provider_logs_page.dart';
import 'package:cake_wallet/src/screens/dev/secure_preferences_page.dart';
import 'package:cake_wallet/src/screens/dev/shared_preferences_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/savings_page.dart';
import 'package:cake_wallet/src/screens/settings/background_sync_page.dart';
import 'package:cake_wallet/src/screens/start_tor/start_tor_page.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/swap_confirmation_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/swap_details_bottom_sheet.dart';

import 'package:cake_wallet/store/dashboard/order_filter_store.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/view_model/dev/monero_background_sync.dart';
import 'package:cake_wallet/view_model/dev/secure_preferences.dart';
import 'package:cake_wallet/view_model/dev/shared_preferences.dart';
import 'package:cake_wallet/view_model/hardware_wallet/bitbox_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/trezor_view_model.dart';
import 'package:cake_wallet/view_model/integrations/deuro_view_model.dart';
import 'package:cake_wallet/view_model/link_view_model.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/src/screens/transaction_details/rbf_details_page.dart';
import 'package:cake_wallet/view_model/start_tor_view_model.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cake_wallet/entities/wallet_edit_page_arguments.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:cake_wallet/src/screens/buy/buy_sell_options_page.dart';
import 'package:cake_wallet/src/screens/buy/payment_method_options_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_external_send_page.dart';
import 'package:cake_wallet/src/screens/payjoin_details/payjoin_details_page.dart';
import 'package:cake_wallet/src/screens/receive/address_list_page.dart';
import 'package:cake_wallet/src/screens/seed/seed_verification/seed_verification_page.dart';
import 'package:cake_wallet/src/screens/send/transaction_success_info_page.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:cake_wallet/src/screens/settings/mweb_logs_page.dart';
import 'package:cake_wallet/src/screens/settings/mweb_node_page.dart';
import 'package:cake_wallet/src/screens/welcome/welcome_page.dart';
import 'package:cake_wallet/store/dashboard/payjoin_transactions_store.dart';
import 'package:cake_wallet/view_model/dashboard/sign_view_model.dart';
import 'package:cake_wallet/view_model/payjoin_details_view_model.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/qr_view_data.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/reactions/on_authentication_state_change.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/src/screens/anonpay_details/anonpay_details_page.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/backup/backup_page.dart';
import 'package:cake_wallet/src/screens/backup/edit_backup_password_page.dart';
import 'package:cake_wallet/src/screens/buy/buy_webview_page.dart';
import 'package:cake_wallet/src/screens/buy/webview_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_page.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_dashboard_page.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar_wrapper.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_wallet_selection_dropdown.dart';
import 'package:cake_wallet/src/screens/dashboard/edit_token_page.dart';
import 'package:cake_wallet/src/screens/dashboard/home_settings_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/address_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/balance/balance_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/transactions_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_template_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_confirm_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_page.dart';
import 'package:cake_wallet/src/screens/faq/faq_page.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/src/screens/nano/nano_change_rep_page.dart';
import 'package:cake_wallet/src/screens/nano_accounts/nano_account_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/nano_accounts/nano_account_list_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/new_wallet_type_page.dart';
import 'package:cake_wallet/src/screens/nodes/node_create_or_edit_page.dart';
import 'package:cake_wallet/src/screens/nodes/pow_node_create_or_edit_page.dart';
import 'package:cake_wallet/src/screens/order_details/order_details_page.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_invoice_page.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_receive_page.dart';
import 'package:cake_wallet/src/screens/receive/fullscreen_qr_page.dart';
import 'package:cake_wallet/src/screens/receive/receive_page.dart';
import 'package:cake_wallet/src/screens/rescan/rescan_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_from_backup_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_options_page.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_choose_derivation.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_page.dart';
import 'package:cake_wallet/src/screens/seed/pre_seed_page.dart';
import 'package:cake_wallet/src/screens/seed/wallet_seed_page.dart';
import 'package:cake_wallet/src/screens/send/send_page.dart';
import 'package:cake_wallet/src/screens/send/send_template_page.dart';
import 'package:cake_wallet/src/screens/settings/connection_sync_page.dart';
import 'package:cake_wallet/src/screens/settings/desktop_settings/desktop_settings_page.dart';
import 'package:cake_wallet/src/screens/settings/display_settings_page.dart';
import 'package:cake_wallet/src/screens/settings/domain_lookups_page.dart';
import 'package:cake_wallet/src/screens/settings/manage_nodes_page.dart';
import 'package:cake_wallet/src/screens/settings/mweb_settings.dart';
import 'package:cake_wallet/src/screens/settings/other_settings_page.dart';
import 'package:cake_wallet/src/screens/settings/privacy_page.dart';
import 'package:cake_wallet/src/screens/settings/security_backup_page.dart';
import 'package:cake_wallet/src/screens/settings/silent_payments_settings.dart';
import 'package:cake_wallet/src/screens/settings/silent_payments_logs_page.dart';
import 'package:cake_wallet/src/screens/settings/trocador_providers_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/modify_2fa_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/setup_2fa.dart';
import 'package:cake_wallet/src/screens/setup_2fa/setup_2fa_enter_code_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/setup_2fa_info_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/setup_2fa_qr_page.dart';
import 'package:cake_wallet/src/screens/setup_pin_code/setup_pin_code.dart';
import 'package:cake_wallet/src/screens/subaddress/address_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/support/support_page.dart';
import 'package:cake_wallet/src/screens/support_chat/support_chat_page.dart';
import 'package:cake_wallet/src/screens/support_other_links/support_other_links_page.dart';
import 'package:cake_wallet/src/screens/ur/animated_ur_page.dart';
import 'package:cake_wallet/src/screens/wallet/wallet_edit_page.dart';
import 'package:cake_wallet/src/screens/wallet_connect/wc_connections_listing_view.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_page.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/store/anonpay/anonpay_transactions_store.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:cake_wallet/view_model/animated_ur_model.dart';
import 'package:cake_wallet/view_model/dashboard/desktop_sidebar_view_model.dart';
import 'package:cake_wallet/view_model/anon_invoice_page_view_model.dart';
import 'package:cake_wallet/view_model/anonpay_details_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/home_settings_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_auth_view_model.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_api.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_vendor.dart';
import 'package:cake_wallet/cake_pay/cake_pay.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_account_view_model.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_cards_list_view_model.dart';
import 'package:cake_wallet/view_model/nano_account_list/nano_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/nano_account_list/nano_account_list_view_model.dart';
import 'package:cake_wallet/view_model/new_wallet_type_view_model.dart';
import 'package:cake_wallet/view_model/node_list/pow_node_list_view_model.dart';
import 'package:cake_wallet/view_model/wallet_groups_display_view_model.dart';
import 'package:cake_wallet/view_model/seed_settings_view_model.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:cake_wallet/view_model/settings/display_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/mweb_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/other_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/privacy_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/security_settings_view_model.dart';
import 'package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/trocador_providers_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_edit_view_model.dart';
import 'package:cake_wallet/view_model/wallet_restore_choose_derivation_view_model.dart';
import 'package:cw_core/nano_account.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_page.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/unspent_coins_details_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/unspent_coins_list_page.dart';
import 'package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/store/node_list_store.dart';
import 'package:cake_wallet/store/seed_settings_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
import 'package:cake_wallet/store/wallet_list_store.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cake_wallet/view_model/auth_view_model.dart';
import 'package:cake_wallet/view_model/backup_view_model.dart';
import 'package:cake_wallet/view_model/buy/buy_amount_view_model.dart';
import 'package:cake_wallet/view_model/buy/buy_view_model.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/cake_features_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/edit_backup_password_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cake_wallet/view_model/order_details_view_model.dart';
import 'package:cake_wallet/view_model/rescan_view_model.dart';
import 'package:cake_wallet/view_model/restore_from_backup_view_model.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/settings/silent_payments_settings_view_model.dart';
import 'package:cake_wallet/view_model/setup_pin_code_view_model.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:cake_wallet/view_model/trade_details_view_model.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_details_view_model.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/view_model/wallet_hardware_restore_view_model.dart';
import 'package:cake_wallet/view_model/wallet_keys_view_model.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
import 'package:cake_wallet/view_model/wallet_seed_view_model.dart';
import 'package:cake_wallet/view_model/wallet_unlock_loadable_view_model.dart';
import 'package:cake_wallet/view_model/wallet_unlock_verifiable_view_model.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trezor_connect/trezor_connect.dart';
import 'buy/kryptonim/kryptonim.dart';
import 'buy/meld/meld_buy_provider.dart';
import 'dogecoin/dogecoin.dart';
import 'src/screens/buy/buy_sell_page.dart';
import 'package:cake_wallet/view_model/dev/background_sync_logs_view_model.dart';
import 'package:cake_wallet/src/screens/dev/background_sync_logs_page.dart';
import 'package:cake_wallet/core/trade_monitor.dart';
import 'package:cake_wallet/core/reset_service.dart';
import 'package:cake_wallet/view_model/dev/socket_health_logs_view_model.dart';
import 'package:cake_wallet/src/screens/dev/socket_health_logs_page.dart';
import 'package:cake_wallet/view_model/dev/exchange_provider_logs_view_model.dart';
import 'package:cake_wallet/view_model/payment/payment_view_model.dart';
import 'package:cake_wallet/view_model/wallet_switcher_view_model.dart';

final getIt = GetIt.instance;

var _isSetupFinished = false;
// late Box<Node> _nodeSource;
// late Box<Node> _powNodeSource;
late Box<Contact> _contactSource;
late Box<Trade> _tradesSource;
late Box<Template> _templates;
late Box<ExchangeTemplate> _exchangeTemplates;
late Box<TransactionDescription> _transactionDescriptionBox;
late Box<Order> _ordersSource;
late Box<UnspentCoinsInfo> _unspentCoinsInfoSource;
late Box<PayjoinSession> _payjoinSessionSource;
late Box<AnonpayInvoiceInfo> _anonpayInvoiceInfoSource;

Future<void> setup({
  required Box<Contact> contactSource,
  required Box<Trade> tradesSource,
  required Box<Template> templates,
  required Box<ExchangeTemplate> exchangeTemplates,
  required Box<TransactionDescription> transactionDescriptionBox,
  required Box<Order> ordersSource,
  required Box<UnspentCoinsInfo> unspentCoinsInfoSource,
  required Box<PayjoinSession> payjoinSessionSource,
  required Box<AnonpayInvoiceInfo> anonpayInvoiceInfoSource,
  required SecureStorage secureStorage,
  required GlobalKey<NavigatorState> navigatorKey,
}) async {
  _contactSource = contactSource;
  _tradesSource = tradesSource;
  _templates = templates;
  _exchangeTemplates = exchangeTemplates;
  _transactionDescriptionBox = transactionDescriptionBox;
  _ordersSource = ordersSource;
  _unspentCoinsInfoSource = unspentCoinsInfoSource;
  _payjoinSessionSource = payjoinSessionSource;
  _anonpayInvoiceInfoSource = anonpayInvoiceInfoSource;

  if (!_isSetupFinished) {
    getIt.registerSingletonAsync<SharedPreferences>(() => SharedPreferences.getInstance());
    getIt.registerSingleton<SecureStorage>(secureStorage);
    getIt.registerSingletonAsync<ThemeStore>(() async {
      final store = ThemeStore();
      await store.loadThemePreferences();
      return store;
    });
  }

  final isBitcoinBuyEnabled = (secrets.wyreSecretKey.isNotEmpty) &&
      (secrets.wyreApiKey.isNotEmpty) &&
      (secrets.wyreAccountId.isNotEmpty);

  final settingsStore = await SettingsStoreBase.load(
    isBitcoinBuyEnabled: isBitcoinBuyEnabled,
  );

  if (_isSetupFinished) {
    return;
  }


  getIt.registerSingleton(AuthenticationStore());
  getIt.registerSingleton<WalletListStore>(WalletListStore());
  // getIt.registerSingleton(NodeListStoreBase.instance);
  getIt.registerSingleton<SettingsStore>(settingsStore);
  getIt.registerSingleton<AppStore>(AppStore(
      authenticationStore: getIt.get<AuthenticationStore>(),
      walletList: getIt.get<WalletListStore>(),
      settingsStore: getIt.get<SettingsStore>(),
      // nodeListStore: getIt.get<NodeListStore>(),
      themeStore: getIt.get<ThemeStore>()));
  getIt.registerSingleton<TradesStore>(
      TradesStore(tradesSource: _tradesSource, settingsStore: getIt.get<SettingsStore>()));
  getIt.registerSingleton<OrdersStore>(
      OrdersStore(ordersSource: _ordersSource, settingsStore: getIt.get<SettingsStore>()));
  getIt.registerFactory(() =>
      PayjoinTransactionsStore(payjoinSessionSource: _payjoinSessionSource));
  getIt.registerSingleton<TradeFilterStore>(TradeFilterStore());
  getIt.registerSingleton<OrderFilterStore>(OrderFilterStore());
  getIt.registerSingleton<TransactionFilterStore>(TransactionFilterStore(getIt.get<AppStore>()));
  getIt.registerSingleton<FiatConversionStore>(FiatConversionStore());
  getIt.registerSingleton<SendTemplateStore>(SendTemplateStore(templateSource: _templates));
  getIt.registerSingleton<ExchangeTemplateStore>(
      ExchangeTemplateStore(templateSource: _exchangeTemplates));
  getIt.registerSingleton<YatStore>(
      YatStore(appStore: getIt.get<AppStore>(), secureStorage: getIt.get<SecureStorage>())..init());
  getIt.registerSingleton<AnonpayTransactionsStore>(
      AnonpayTransactionsStore(anonpayInvoiceInfoSource: _anonpayInvoiceInfoSource));
  getIt.registerSingleton<SeedSettingsStore>(SeedSettingsStore());

  getIt.registerFactoryParam<HardwareWalletViewModel, HardwareWalletType, void>((type, _) {
    switch(type) {
      case HardwareWalletType.bitbox: return getIt<BitboxViewModel>();
      case HardwareWalletType.ledger: return getIt<LedgerViewModel>();
      case HardwareWalletType.trezor: return getIt<TrezorViewModel>();
      case HardwareWalletType.cupcake:
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
        throw Exception("This should not have happened, because airgapped Wallets don't need View Models");
    }
  });

  getIt.registerLazySingleton(() => LedgerViewModel());

  getIt.registerLazySingleton(() => BitboxViewModel());

  getIt.registerLazySingleton(() => TrezorConnect("cakewallet://trezor_connect",
      appName: "Cake Wallet"));
  getIt.registerLazySingleton(() => TrezorViewModel(getIt<TrezorConnect>()));


  getIt.registerFactory<KeyService>(() => KeyService(getIt.get<SecureStorage>()));

  getIt.registerFactoryParam<WalletCreationService, WalletType, void>((type, _) =>
      WalletCreationService(
          initialType: type,
          keyService: getIt.get<KeyService>(),
          sharedPreferences: getIt.get<SharedPreferences>(),
          settingsStore: getIt.get<SettingsStore>(),
        ));

  getIt.registerFactoryParam<AdvancedPrivacySettingsViewModel, WalletType, void>(
      (type, _) => AdvancedPrivacySettingsViewModel(type, getIt.get<SettingsStore>()));

  getIt.registerFactory<WalletLoadingService>(() => WalletLoadingService(
      getIt.get<SharedPreferences>(),
      getIt.get<KeyService>(),
      (WalletType type) => getIt.get<WalletService>(param1: type)));

  getIt.registerFactoryParam<WalletNewVM, NewWalletArguments, void>(
    (newWalletArgs, _) => WalletNewVM(
      getIt.get<AppStore>(),
      getIt.get<WalletCreationService>(param1:newWalletArgs.type),
      getIt.get<AdvancedPrivacySettingsViewModel>(param1: newWalletArgs.type),
      getIt.get<SeedSettingsViewModel>(),
      newWalletArguments: newWalletArgs,
    ));


  final walletList = await WalletInfo.getAll();
  getIt.registerFactory<NewWalletTypeViewModel>(() => NewWalletTypeViewModel(walletList.isNotEmpty));

  getIt.registerFactory<WalletManager>(
    () => WalletManager(
      getIt.get<SharedPreferences>(),
    ),
  );

  getIt.registerFactoryParam<WalletGroupsDisplayViewModel, WalletType, void>(
    (type, _) => WalletGroupsDisplayViewModel(
      getIt.get<AppStore>(),
      getIt.get<WalletLoadingService>(),
      getIt.get<WalletManager>(),
      getIt.get<WalletListViewModel>(),
      type: type,
    ),
  );

  getIt.registerFactoryParam<WalletUnlockPage, WalletUnlockArguments, bool>((args, closable) {
    return WalletUnlockPage(
      getIt.get<WalletUnlockLoadableViewModel>(param1: args),
      args.callback,
      args.authPasswordHandler,
      closable: closable);
  }, instanceName: 'wallet_unlock_loadable');

  getIt.registerFactory<WalletUnlockPage>(
    () => getIt.get<WalletUnlockPage>(
      param1: WalletUnlockArguments(
        callback: (bool successful, _) {
          if (successful) {
            final authStore = getIt.get<AuthenticationStore>();
            authStore.allowed();
          }}),
      param2: false,
      instanceName: 'wallet_unlock_loadable'),
    instanceName: 'wallet_password_login');

  getIt.registerFactoryParam<WalletUnlockPage, WalletUnlockArguments, bool>((args, closable) {
    return WalletUnlockPage(
      getIt.get<WalletUnlockVerifiableViewModel>(param1: args),
      args.callback,
      args.authPasswordHandler,
      closable: closable);
  }, instanceName: 'wallet_unlock_verifiable');

  getIt.registerFactoryParam<WalletUnlockLoadableViewModel, WalletUnlockArguments, void>((args, _) {
    final currentWalletName = getIt
      .get<SharedPreferences>()
      .getString(PreferencesKey.currentWalletName) ?? '';
    final currentWalletTypeRaw =
      getIt.get<SharedPreferences>()
        .getInt(PreferencesKey.currentWalletType) ?? 0;
    final currentWalletType = deserializeFromInt(currentWalletTypeRaw);

    return WalletUnlockLoadableViewModel(
      getIt.get<AppStore>(),
      getIt.get<WalletLoadingService>(),
      walletName: args.walletName ?? currentWalletName,
      walletType: args.walletType ?? currentWalletType);
  });

  getIt.registerFactoryParam<WalletUnlockVerifiableViewModel, WalletUnlockArguments, void>((args, _) {
    final currentWalletName = getIt
      .get<SharedPreferences>()
      .getString(PreferencesKey.currentWalletName) ?? '';
    final currentWalletTypeRaw =
      getIt.get<SharedPreferences>()
        .getInt(PreferencesKey.currentWalletType) ?? 0;
    final currentWalletType = deserializeFromInt(currentWalletTypeRaw);

    return WalletUnlockVerifiableViewModel(
      getIt.get<AppStore>(),
      walletName: args.walletName ?? currentWalletName,
      walletType: args.walletType ?? currentWalletType);
  });

  getIt.registerFactoryParam<WalletHardwareRestoreViewModel, WalletType, HardwareWalletViewModel>(
      (type, hardwareWalletVM) => WalletHardwareRestoreViewModel(
          hardwareWalletVM,
          getIt.get<AppStore>(),
          getIt.get<WalletCreationService>(param1: type),
          getIt.get<SeedSettingsViewModel>(),
          type: type));

  getIt.registerFactory<WalletAddressListViewModel>(() => WalletAddressListViewModel(
      appStore: getIt.get<AppStore>(),
      yatStore: getIt.get<YatStore>(),
      fiatConversionStore: getIt.get<FiatConversionStore>()));

  getIt.registerFactory(() => BalanceViewModel(
      appStore: getIt.get<AppStore>(),
      settingsStore: getIt.get<SettingsStore>(),
      fiatConvertationStore: getIt.get<FiatConversionStore>()));

  getIt.registerFactory(
    () => ExchangeViewModel(
      getIt.get<AppStore>(),
      _tradesSource,
      getIt.get<ExchangeTemplateStore>(),
      getIt.get<TradesStore>(),
      getIt.get<AppStore>().settingsStore,
      getIt.get<SharedPreferences>(),
      getIt.get<ContactListViewModel>(),
      getIt.get<UnspentCoinsListViewModel>(),
      getIt.get<FeesViewModel>(),
      getIt.get<FiatConversionStore>(),
    ),
  );

  getIt.registerSingleton(
    TradeMonitor(
      tradesStore: getIt.get<TradesStore>(),
      trades: _tradesSource,
      appStore: getIt.get<AppStore>(),
      preferences: getIt.get<SharedPreferences>(),
    ),
  );

  getIt.registerFactory(() => DashboardViewModel(
    tradeMonitor: getIt.get<TradeMonitor>(),
    balanceViewModel: getIt.get<BalanceViewModel>(),
    appStore: getIt.get<AppStore>(),
    tradesStore: getIt.get<TradesStore>(),
    ordersStore: getIt.get<OrdersStore>(),
    tradeFilterStore: getIt.get<TradeFilterStore>(),
    orderFilterStore: getIt.get<OrderFilterStore>(),
    transactionFilterStore: getIt.get<TransactionFilterStore>(),
    settingsStore: settingsStore,
    yatStore: getIt.get<YatStore>(),
    anonpayTransactionsStore: getIt.get<AnonpayTransactionsStore>(),
    payjoinTransactionsStore: getIt.get<PayjoinTransactionsStore>(),
    sharedPreferences: getIt.get<SharedPreferences>(),
    keyService: getIt.get<KeyService>()));

  getIt.registerFactory<AuthService>(
        () => AuthService(
        secureStorage: getIt.get<SecureStorage>(),
        sharedPreferences: getIt.get<SharedPreferences>(),
        settingsStore: getIt.get<SettingsStore>(),
        authenticationStore: getIt.get<AuthenticationStore>(),
        appStore: getIt.get<AppStore>(),
        resetService: getIt.get<ResetService>(),
        walletList: walletList),
  );

  getIt.registerFactory<ResetService>(
    () => ResetService(
      secureStorage: getIt.get<SecureStorage>(),
      authenticationStore: getIt.get<AuthenticationStore>(),
      settingsStore: getIt.get<SettingsStore>(),
    ),
  );

  getIt.registerFactory<AuthViewModel>(() => AuthViewModel(getIt.get<AuthService>(),
      getIt.get<SharedPreferences>(), getIt.get<SettingsStore>(), BiometricAuth()));

  getIt.registerFactoryParam<AuthPage, void Function(bool, AuthPageState), bool>(
      (onAuthFinished, closable) => AuthPage(getIt.get<AuthViewModel>(),
          onAuthenticationFinished: onAuthFinished, closable: closable));

  getIt.registerLazySingleton<Setup2FAViewModel>(
    () => Setup2FAViewModel(
      getIt.get<SettingsStore>(),
      getIt.get<SharedPreferences>(),
      getIt.get<AuthService>(),
    ),
  );

  getIt.registerFactoryParam<TotpAuthCodePage, TotpAuthArgumentsModel, void>(
    (totpAuthPageArguments, _) => TotpAuthCodePage(
      getIt.get<Setup2FAViewModel>(),
      totpArguments: totpAuthPageArguments,
    ),
  );

  getIt.registerLazySingleton<LinkViewModel>(() {
    return LinkViewModel(
      appStore: getIt.get<AppStore>(),
      settingsStore: getIt.get<SettingsStore>(),
      authenticationStore: getIt.get<AuthenticationStore>(),
      navigatorKey: navigatorKey,
    );
  });

  getIt.registerFactory<AuthPage>(instanceName: 'login', () {
    return AuthPage(getIt.get<AuthViewModel>(), closable: false,
        onAuthenticationFinished: (isAuthenticated, AuthPageState authPageState) async {
      if (!isAuthenticated) {
        return;
      }
      final authStore = getIt.get<AuthenticationStore>();
      final appStore = getIt.get<AppStore>();
      final useTotp = appStore.settingsStore.useTOTP2FA;
      final shouldUseTotp2FAToAccessWallets =
          appStore.settingsStore.shouldRequireTOTP2FAForAccessingWallet;
      if (useTotp && shouldUseTotp2FAToAccessWallets) {
        authPageState.close(
          route: Routes.totpAuthCodePage,
          arguments: TotpAuthArgumentsModel(
            isForSetup: false,
            isClosable: false,
            onTotpAuthenticationFinished:
                (bool isAuthenticatedSuccessfully, TotpAuthCodePageState totpAuthPageState) async {
              if (!isAuthenticatedSuccessfully) {
                return;
              }
              if (appStore.wallet != null) {
                authStore.allowed();
                return;
              }

              totpAuthPageState.changeProcessText('Loading the wallet');

              if (loginError != null) {
                totpAuthPageState.changeProcessText('ERROR: ${loginError.toString()}'.trim());
              }

              ReactionDisposer? _reaction;
              _reaction = reaction((_) => appStore.wallet, (Object? _) {
                _reaction?.reaction.dispose();
                authStore.allowed();
              });
            },
          ),
        );
      } else {
        // wallet is already loaded:
        if (appStore.wallet != null || await requireHardwareWalletConnection()) {
          // goes to the dashboard:
          authStore.allowed();
          // trigger any deep links:
          final linkViewModel = getIt.get<LinkViewModel>();
          if (linkViewModel.currentLink != null) {
            linkViewModel.handleLink();
          }
          return;
        }

        // load the wallet:

        authPageState.changeProcessText('Loading the wallet');

        if (loginError != null) {
          authPageState.changeProcessText('ERROR: ${loginError.toString()}'.trim());
          loginError = null;
        }

        ReactionDisposer? _reaction;
        _reaction = reaction((_) => appStore.wallet, (Object? _) {
          _reaction?.reaction.dispose();
          authStore.allowed();
          final linkViewModel = getIt.get<LinkViewModel>();
          if (linkViewModel.currentLink != null) {
            linkViewModel.handleLink();
          }
        });

        Timer.periodic(Duration(seconds: 1), (timer) {
          if (timer.tick > 30) {
            timer.cancel();
          }

          if (loginError != null) {
            authPageState.changeProcessText('ERROR: ${loginError.toString()}'.trim());
            timer.cancel();
          }
        });
      }
    });
  });

  getIt.registerSingleton<BottomSheetService>(BottomSheetServiceImpl());

  final appStore = getIt.get<AppStore>();

  getIt.registerLazySingleton<WalletConnectKeyService>(() => KeyServiceImpl());

  getIt.registerLazySingleton<WalletKitService>(() {
    final WalletKitService walletKitService = WalletKitService(
      getIt.get<BottomSheetService>(),
      getIt.get<WalletConnectKeyService>(),
      appStore,
      getIt.get<SharedPreferences>(),
    );
    walletKitService.create();
    return walletKitService;
  });

  getIt.registerFactory(() => BalancePage(
      nftViewModel: getIt.get<NFTViewModel>(),
      dashboardViewModel: getIt.get<DashboardViewModel>(),
      settingsStore: getIt.get<SettingsStore>()));

  getIt.registerFactory<DashboardPage>(() => DashboardPage(
        bottomSheetService: getIt.get<BottomSheetService>(),
        balancePage: getIt.get<BalancePage>(),
        dashboardViewModel: getIt.get<DashboardViewModel>(),
        addressListViewModel: getIt.get<WalletAddressListViewModel>(),
      ));

  getIt.registerFactory<DesktopSidebarWrapper>(() {
    final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
    return DesktopSidebarWrapper(
      bottomSheetService: getIt.get<BottomSheetService>(),
      dashboardViewModel: getIt.get<DashboardViewModel>(),
      desktopSidebarViewModel: getIt.get<DesktopSidebarViewModel>(),
      child: getIt.get<DesktopDashboardPage>(param1: _navigatorKey),
      desktopNavigatorKey: _navigatorKey,
    );
  });
  getIt.registerFactoryParam<DesktopDashboardPage, GlobalKey<NavigatorState>, void>(
      (desktopKey, _) => DesktopDashboardPage(
            balancePage: getIt.get<BalancePage>(),
            dashboardViewModel: getIt.get<DashboardViewModel>(),
            addressListViewModel: getIt.get<WalletAddressListViewModel>(),
            desktopKey: desktopKey,
          ));

  getIt.registerFactory<TransactionsPage>(
      () => TransactionsPage(dashboardViewModel: getIt.get<DashboardViewModel>()));

  getIt.registerFactory<Setup2FAInfoPage>(() => Setup2FAInfoPage());

  getIt.registerFactory<Setup2FAPage>(
      () => Setup2FAPage(setup2FAViewModel: getIt.get<Setup2FAViewModel>()));

  getIt.registerFactory<Setup2FAQRPage>(
      () => Setup2FAQRPage(setup2FAViewModel: getIt.get<Setup2FAViewModel>()));

  getIt.registerFactory<Modify2FAPage>(
      () => Modify2FAPage(setup2FAViewModel: getIt.get<Setup2FAViewModel>()));

  getIt.registerFactory<DesktopSettingsPage>(
      () => DesktopSettingsPage(getIt.get<DashboardViewModel>()));

  getIt.registerFactoryParam<ReceiveOptionViewModel, ReceivePageOption?, void>(
      (pageOption, _) => ReceiveOptionViewModel(getIt.get<AppStore>().wallet!, pageOption));

  getIt.registerFactoryParam<AnonInvoicePageViewModel, List<dynamic>, void>((args, _) {
    final address = args.first as String;
    final pageOption = args.last as ReceivePageOption;
    return AnonInvoicePageViewModel(
      getIt.get<AnonPayApi>(),
      address,
      getIt.get<SettingsStore>(),
      getIt.get<AppStore>().wallet!,
      _anonpayInvoiceInfoSource,
      getIt.get<SharedPreferences>(),
      pageOption,
    );
  });

  getIt.registerFactoryParam<AnonPayInvoicePage, List<dynamic>, void>((List<dynamic> args, _) {
    final pageOption = args.last as ReceivePageOption;
    return AnonPayInvoicePage(getIt.get<AnonInvoicePageViewModel>(param1: args),
        getIt.get<ReceiveOptionViewModel>(param1: pageOption));
  });

  getIt.registerFactory<ReceivePage>(
      () => ReceivePage(addressListViewModel: getIt.get<WalletAddressListViewModel>()));
  getIt.registerFactory<AddressPage>(() => AddressPage(
      addressListViewModel: getIt.get<WalletAddressListViewModel>(),
      dashboardViewModel: getIt.get<DashboardViewModel>(),
      receiveOptionViewModel: getIt.get<ReceiveOptionViewModel>()));

  getIt.registerFactoryParam<WalletAddressEditOrCreateViewModel, WalletAddressListItem?, void>(
      (WalletAddressListItem? item, _) =>
          WalletAddressEditOrCreateViewModel(wallet: getIt.get<AppStore>().wallet!, item: item));

  getIt.registerFactoryParam<AddressEditOrCreatePage, dynamic, void>((dynamic item, _) =>
      AddressEditOrCreatePage(
          addressEditOrCreateViewModel:
              getIt.get<WalletAddressEditOrCreateViewModel>(param1: item)));

  getIt.registerFactory<SendTemplateViewModel>(() => SendTemplateViewModel(
      getIt.get<AppStore>().wallet!,
      getIt.get<AppStore>().settingsStore,
      getIt.get<SendTemplateStore>(),
      getIt.get<FiatConversionStore>()));

  getIt.registerFactoryParam<SendViewModel, UnspentCoinType?, void>(
    (coinTypeToSpendFrom, _) => SendViewModel(
      getIt.get<AppStore>(),
      getIt.get<SendTemplateViewModel>(),
      getIt.get<FiatConversionStore>(),
      getIt.get<BalanceViewModel>(),
      getIt.get<ContactListViewModel>(),
      _transactionDescriptionBox,
      getIt.get<AppStore>().wallet!.isHardwareWallet
          ? getIt<HardwareWalletViewModel>(
              param1: getIt.get<AppStore>().wallet!.hardwareWalletType!)
          : null,
      coinTypeToSpendFrom: coinTypeToSpendFrom ?? UnspentCoinType.nonMweb,
      getIt.get<UnspentCoinsListViewModel>(param1: coinTypeToSpendFrom),
      getIt.get<FeesViewModel>()
    ),
  );

  getIt.registerFactoryParam<SendPage, PaymentRequest?, UnspentCoinType?>(
      (PaymentRequest? initialPaymentRequest, coinTypeToSpendFrom) => SendPage(
            sendViewModel: getIt.get<SendViewModel>(param1: coinTypeToSpendFrom),
            authService: getIt.get<AuthService>(),
            initialPaymentRequest: initialPaymentRequest,
            paymentViewModel: getIt.get<PaymentViewModel>(),
            walletSwitcherViewModel: getIt.get<WalletSwitcherViewModel>(),
          ));

  getIt.registerFactory(
      () => SendTemplatePage(sendTemplateViewModel: getIt.get<SendTemplateViewModel>()));

  if (DeviceInfo.instance.isMobile) {
    getIt.registerFactory(
      () => WalletListViewModel(
        getIt.get<AppStore>(),
        getIt.get<WalletLoadingService>(),
        getIt.get<WalletManager>(),
      ),
    );
  } else {
    // register wallet list view model as singleton on desktop since it can be accessed
    // from multiple places at the same time (Wallets DropDown, Wallets List in settings)
    getIt.registerLazySingleton(
      () => WalletListViewModel(
        getIt.get<AppStore>(),
        getIt.get<WalletLoadingService>(),
        getIt.get<WalletManager>(),
      ),
    );
  }

  getIt.registerFactoryParam<WalletListPage, Function(BuildContext)?, void>(
      (Function(BuildContext)? onWalletLoaded, _) => WalletListPage(
            walletListViewModel: getIt.get<WalletListViewModel>(),
            authService: getIt.get<AuthService>(),
            onWalletLoaded: onWalletLoaded as Future<void> Function(BuildContext)?,
          ));

  getIt.registerFactoryParam<WalletEditViewModel, WalletListViewModel, void>(
    (WalletListViewModel walletListViewModel, _) => WalletEditViewModel(
      walletListViewModel,
      getIt.get<WalletLoadingService>(),
      getIt.get<WalletManager>(),
    ),
  );

  getIt.registerFactoryParam<WalletEditPage, WalletEditPageArguments, void>((arguments, _) {

    return WalletEditPage(
      pageArguments: WalletEditPageArguments(
        walletEditViewModel: getIt.get<WalletEditViewModel>(param1: arguments.walletListViewModel),
        authService: getIt.get<AuthService>(),
        walletNewVM: getIt.get<WalletNewVM>(
          param1: NewWalletArguments(type: arguments.editingWallet.type),
        ),
        editingWallet: arguments.editingWallet,
        isWalletGroup: arguments.isWalletGroup,
        groupName: arguments.groupName,
        walletGroupKey: arguments.walletGroupKey,
      ),
    );
  });

  getIt.registerFactory<NanoAccountListViewModel>(() {
    final wallet = getIt.get<AppStore>().wallet!;
    if (wallet.type == WalletType.nano || wallet.type == WalletType.banano) {
      return NanoAccountListViewModel(wallet);
    }
    throw Exception(
        'Unexpected wallet type: ${wallet.type} for generate Nano/Banano AccountListViewModel');
  });

  getIt.registerFactory<MoneroAccountListViewModel>(() {
    final wallet = getIt.get<AppStore>().wallet!;
    if (wallet.type == WalletType.monero ||
        wallet.type == WalletType.wownero ||
        wallet.type == WalletType.haven) {
      return MoneroAccountListViewModel(wallet,getIt.get<SettingsStore>());
    }
    throw Exception(
        'Unexpected wallet type: ${wallet.type} for generate Monero AccountListViewModel');
  });

  getIt.registerFactory(
      () => MoneroAccountListPage(accountListViewModel: getIt.get<MoneroAccountListViewModel>()));

  getIt.registerFactory(
      () => NanoAccountListPage(accountListViewModel: getIt.get<NanoAccountListViewModel>()));

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

  getIt.registerFactoryParam<MoneroAccountEditOrCreateViewModel, AccountListItem?, void>(
      (AccountListItem? account, _) => MoneroAccountEditOrCreateViewModel(
          monero!.getAccountList(getIt.get<AppStore>().wallet!),
          wownero?.getAccountList(getIt.get<AppStore>().wallet!),
          wallet: getIt.get<AppStore>().wallet!,
          accountListItem: account));

  getIt.registerFactoryParam<MoneroAccountEditOrCreatePage, AccountListItem?, void>(
      (AccountListItem? account, _) => MoneroAccountEditOrCreatePage(
          moneroAccountCreationViewModel:
              getIt.get<MoneroAccountEditOrCreateViewModel>(param1: account)));

  getIt.registerFactoryParam<NanoAccountEditOrCreateViewModel, NanoAccount?, void>(
      (NanoAccount? account, _) =>
          NanoAccountEditOrCreateViewModel(nano!.getAccountList(getIt.get<AppStore>().wallet!),
              // banano?.getAccountList(getIt.get<AppStore>().wallet!),
              wallet: getIt.get<AppStore>().wallet!,
              accountListItem: account));

  getIt.registerFactoryParam<NanoAccountEditOrCreatePage, NanoAccount?, void>(
      (NanoAccount? account, _) => NanoAccountEditOrCreatePage(
          nanoAccountCreationViewModel:
              getIt.get<NanoAccountEditOrCreateViewModel>(param1: account)));

  getIt.registerFactory(() =>
      DisplaySettingsViewModel(getIt.get<SettingsStore>(), getIt.get<ThemeStore>()));

  getIt.registerFactory(() =>
      SilentPaymentsSettingsViewModel(getIt.get<SettingsStore>(), getIt.get<AppStore>().wallet!));

  getIt.registerFactory(
      () => MwebSettingsViewModel(getIt.get<SettingsStore>(), getIt.get<AppStore>().wallet!));

  getIt.registerFactory(() =>
      PrivacySettingsViewModel(getIt.get<SettingsStore>(), getIt.get<AppStore>().wallet!));

  getIt.registerFactory(() => TrocadorExchangeProvider());

  getIt.registerFactory(() => TrocadorProvidersViewModel(
      getIt.get<SettingsStore>(), getIt.get<TrocadorExchangeProvider>()));

  getIt.registerFactory(() =>
      OtherSettingsViewModel(getIt.get<SettingsStore>(), getIt.get<AppStore>().wallet!,
          getIt.get<SendViewModel>()));

  getIt.registerFactory(() =>
      SecuritySettingsViewModel(getIt.get<SettingsStore>(), getIt.get<AuthService>()));

  getIt.registerFactory(() => WalletSeedViewModel(getIt.get<AppStore>().wallet!));

  getIt.registerFactory<SeedSettingsViewModel>(() => SeedSettingsViewModel(getIt.get<AppStore>(), getIt.get<SeedSettingsStore>()));

  getIt.registerFactory(() => DevMoneroBackgroundSync(getIt.get<AppStore>().wallet!));

  getIt.registerFactory(() => DevSharedPreferences());

  getIt.registerFactory(() => DevSecurePreferences());

  getIt.registerFactoryParam<WalletSeedPage, bool, void>((bool isWalletCreated, _) =>
      WalletSeedPage(getIt.get<WalletSeedViewModel>(), isNewWalletCreated: isWalletCreated));

  getIt.registerFactory(() => WalletKeysViewModel(getIt.get<AppStore>()));

  getIt.registerFactory(() => WalletKeysPage(getIt.get<WalletKeysViewModel>()));
  
  getIt.registerFactory(() => AnimatedURModel(getIt.get<AppStore>()));

  getIt.registerFactoryParam<AnimatedURPage, Map<String, String>, void>((Map<String, String> urQr, _) =>
    AnimatedURPage(getIt.get<AnimatedURModel>(), urQr: urQr));

  getIt.registerFactoryParam<ContactViewModel, ContactRecord?, void>(
      (ContactRecord? contact, _) => ContactViewModel(_contactSource, contact: contact));

  getIt.registerFactoryParam<ContactListViewModel, CryptoCurrency?, void>(
      (CryptoCurrency? cur, _) =>
          ContactListViewModel(_contactSource, walletList, cur, getIt.get<SettingsStore>()));

  getIt.registerFactoryParam<ContactListPage, CryptoCurrency?, void>((CryptoCurrency? cur, _) =>
      ContactListPage(getIt.get<ContactListViewModel>(param1: cur), getIt.get<AuthService>()));

  getIt.registerFactoryParam<ContactPage, ContactRecord?, void>(
      (ContactRecord? contact, _) => ContactPage(getIt.get<ContactViewModel>(param1: contact)));

  getIt.registerFactory(() => AddressListPage(getIt.get<WalletAddressListViewModel>()));

  getIt.registerLazySingleton(() {
    final appStore = getIt.get<AppStore>();
    return NodeListViewModel(appStore);
  });

  getIt.registerLazySingleton(() {
    final appStore = getIt.get<AppStore>();
    return PowNodeListViewModel(appStore);
  });

  getIt.registerFactory(() => ConnectionSyncPage(getIt.get<DashboardViewModel>()));

  getIt.registerFactory(() => SecurityBackupPage(getIt.get<SecuritySettingsViewModel>(),
      getIt.get<AuthService>(), getIt.get<AppStore>().wallet!.isHardwareWallet));

  getIt.registerFactory(() => PrivacyPage(getIt.get<PrivacySettingsViewModel>()));

  getIt.registerFactory(() => TrocadorProvidersPage(getIt.get<TrocadorProvidersViewModel>()));

  getIt.registerFactory(() => DomainLookupsPage(getIt.get<PrivacySettingsViewModel>()));

  getIt.registerFactory(() => DisplaySettingsPage(getIt.get<DisplaySettingsViewModel>()));

  getIt.registerFactory(
      () => SilentPaymentsSettingsPage(getIt.get<SilentPaymentsSettingsViewModel>()));

  getIt.registerFactory(() => SilentPaymentsLogPage(getIt.get<SilentPaymentsSettingsViewModel>()));

  getIt.registerFactory(() => MwebSettingsPage(getIt.get<MwebSettingsViewModel>()));

  getIt.registerFactory(() => MwebLogsPage(getIt.get<MwebSettingsViewModel>()));

  getIt.registerFactory(() => MwebNodePage(getIt.get<MwebSettingsViewModel>()));

  getIt.registerFactory(() => OtherSettingsPage(getIt.get<OtherSettingsViewModel>()));

  getIt.registerFactory(() => NanoChangeRepPage(
        settingsStore: getIt.get<AppStore>().settingsStore,
        wallet: getIt.get<AppStore>().wallet!,
      ));

  getIt.registerFactoryParam<NodeCreateOrEditViewModel, WalletType?, bool?>(
      (WalletType? type, bool? isPow) => NodeCreateOrEditViewModel(
        isPow ?? false,
          (isPow ?? false) ? null : getIt.get<NodeListViewModel>(),
          (isPow ?? false) ? getIt.get<PowNodeListViewModel>() : null,
          type ?? getIt.get<AppStore>().wallet!.type,
          getIt.get<SettingsStore>()));

  getIt.registerFactoryParam<NodeCreateOrEditPage, Node?, bool?>(
      (Node? editingNode, bool? isSelected) => NodeCreateOrEditPage(
          nodeCreateOrEditViewModel: getIt.get<NodeCreateOrEditViewModel>(param2: false),
          editingNode: editingNode,
          isSelected: isSelected,
          type: getIt.get<AppStore>().wallet!.type));

  getIt.registerFactoryParam<PowNodeCreateOrEditPage, Node?, bool?>(
      (Node? editingNode, bool? isSelected) => PowNodeCreateOrEditPage(
          nodeCreateOrEditViewModel: getIt.get<NodeCreateOrEditViewModel>(param2: true),
          editingNode: editingNode,
          isSelected: isSelected));

  getIt.registerFactory<RobinhoodBuyProvider>(() => RobinhoodBuyProvider(
        wallet: getIt.get<AppStore>().wallet!,
        hardwareWalletVM: getIt<AppStore>().wallet!.isHardwareWallet
            ? getIt<HardwareWalletViewModel>(param1: getIt<AppStore>().wallet!.hardwareWalletType!)
            : null,
      ));

  getIt.registerFactory<DFXBuyProvider>(() => DFXBuyProvider(
        wallet: getIt<AppStore>().wallet!,
        hardwareWalletVM: getIt<AppStore>().wallet!.isHardwareWallet
            ? getIt<HardwareWalletViewModel>(param1: getIt<AppStore>().wallet!.hardwareWalletType!)
            : null,
      ));

  getIt.registerFactory<MoonPayProvider>(() => MoonPayProvider(
        appStore: getIt.get<AppStore>(),
        wallet: getIt.get<AppStore>().wallet!,
        isTestEnvironment: kDebugMode,
      ));

  getIt.registerFactory<OnRamperBuyProvider>(() => OnRamperBuyProvider(
        getIt.get<ThemeStore>(),
        wallet: getIt.get<AppStore>().wallet!,
      ));

  getIt.registerFactory<MeldBuyProvider>(() => MeldBuyProvider(
    wallet: getIt.get<AppStore>().wallet!,
  ));

  getIt.registerFactory<KryptonimBuyProvider>(() => KryptonimBuyProvider(
    wallet: getIt.get<AppStore>().wallet!,
  ));

  getIt.registerFactoryParam<WebViewPage, String, Uri>((title, uri) => WebViewPage(title, uri));

  getIt.registerFactory<FeesViewModel>(
    () => FeesViewModel(
      getIt.get<AppStore>(),
      getIt.get<BalanceViewModel>(),
    ),
  );

  getIt.registerFactory(
    () => ExchangeTradeViewModel(
      wallet: getIt.get<AppStore>().wallet!,
      trades: _tradesSource,
      tradesStore: getIt.get<TradesStore>(),
      sendViewModel: getIt.get<SendViewModel>(),
      feesViewModel: getIt.get<FeesViewModel>(),
      fiatConversionStore: getIt.get<FiatConversionStore>(),
    ),
  );

  getIt.registerFactoryParam<ExchangePage, PaymentRequest?, void>(
      (PaymentRequest? paymentRequest, __) {
    return ExchangePage(getIt.get<ExchangeViewModel>(), getIt.get<AuthService>(), paymentRequest);
  });

  getIt.registerFactory(() => ExchangeConfirmPage(tradesStore: getIt.get<TradesStore>()));

  getIt.registerFactory(
      () => ExchangeTradePage(exchangeTradeViewModel: getIt.get<ExchangeTradeViewModel>()));

  getIt.registerFactory(
      () => ExchangeTradeExternalSendPage(exchangeTradeViewModel: getIt.get<ExchangeTradeViewModel>()));

  getIt.registerFactory(() => BackgroundSyncPage(getIt.get<DashboardViewModel>()));

  getIt.registerFactory(() => ExchangeTemplatePage(getIt.get<ExchangeViewModel>()));

  getIt.registerFactoryParam<SwapConfirmationBottomSheet, PaymentFlowResult, void>(
    (paymentFlowResult, _) => SwapConfirmationBottomSheet(
      paymentFlowResult: paymentFlowResult,
      exchangeViewModel: getIt.get<ExchangeViewModel>(),
      authService: getIt.get<AuthService>(),
    ),
  );

  getIt.registerFactory<SwapDetailsBottomSheet>(
    () => SwapDetailsBottomSheet(
      exchangeTradeViewModel: getIt.get<ExchangeTradeViewModel>(),
    ),
  );

  getIt.registerFactory(() => PaymentViewModel(
    appStore: getIt.get<AppStore>(),
  ));

  getIt.registerFactory(() => WalletSwitcherViewModel(
    appStore: getIt.get<AppStore>(),
    walletLoadingService: getIt.get<WalletLoadingService>(),
  ));

  getIt.registerFactoryParam<WalletService, WalletType, void>((WalletType param1, __) {
    switch (param1) {
      case WalletType.monero:
        return monero!.createMoneroWalletService(_unspentCoinsInfoSource);
      case WalletType.bitcoin:
        return bitcoin!.createBitcoinWalletService(
          _unspentCoinsInfoSource,
          _payjoinSessionSource,
          SettingsStoreBase.walletPasswordDirectInput,
        );
      case WalletType.litecoin:
        return bitcoin!.createLitecoinWalletService(
          _unspentCoinsInfoSource,
          SettingsStoreBase.walletPasswordDirectInput,
        );
      case WalletType.ethereum:
        return ethereum!.createEthereumWalletService(SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.bitcoinCash:
        return bitcoinCash!.createBitcoinCashWalletService(_unspentCoinsInfoSource, SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.dogecoin:
        return dogecoin!.createDogeCoinWalletService(_unspentCoinsInfoSource, SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.nano:
      case WalletType.banano:
        return nano!.createNanoWalletService(SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.polygon:
        return polygon!.createPolygonWalletService(SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.solana:
        return solana!.createSolanaWalletService(SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.tron:
        return tron!.createTronWalletService(SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.wownero:
        return wownero!.createWowneroWalletService(_unspentCoinsInfoSource);
      case WalletType.zano:
        return zano!.createZanoWalletService();
      case WalletType.decred:
        return decred!.createDecredWalletService(_unspentCoinsInfoSource);
      case WalletType.base:
        return base!.createBaseWalletService(SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.arbitrum:
        return arbitrum!.createArbitrumWalletService(SettingsStoreBase.walletPasswordDirectInput);
      case WalletType.haven:
        return HavenWalletService();
      case WalletType.none:
        throw Exception('Unexpected token: ${param1.toString()} for generating of WalletService');
    }
  });

  getIt.registerFactoryParam<SetupPinCodeViewModel, bool?, void>(
        (isDuressPin, _) => SetupPinCodeViewModel(
      getIt.get<AuthService>(),
      getIt.get<SettingsStore>(),
      isDuressPin: isDuressPin ?? false,
    ),
  );


  getIt.registerFactoryParam<
      SetupPinCodePage,
      void Function(PinCodeState<PinCodeWidget>, String),
      bool?>(
        (onSuccessfulPinSetup, isDuressPin) => SetupPinCodePage(
      getIt.get<SetupPinCodeViewModel>(param1: isDuressPin),
      onSuccessfulPinSetup: onSuccessfulPinSetup,
      isDuressPin: isDuressPin ?? false,
    ),
  );

  getIt.registerFactory(() => WelcomePage());

  getIt.registerFactory(() => RescanViewModel(getIt.get<AppStore>().wallet!));

  getIt.registerFactory(() => RescanPage(getIt.get<RescanViewModel>()));

  getIt.registerFactory(() => FaqPage(getIt.get<SettingsStore>()));

  getIt.registerFactoryParam<WalletRestoreViewModel, WalletType, Map<String, dynamic>?>(
      (type, additionalParams) {
    final restoredWallet = additionalParams?['restoredWallet'] as RestoredWallet?;
    final hardwareWalletType = additionalParams?['hardwareWalletType'] as HardwareWalletType?;

    return WalletRestoreViewModel(
        getIt.get<AppStore>(),
        getIt.get<WalletCreationService>(param1: type),
        getIt.get<SeedSettingsViewModel>(),
        type: type,
        restoredWallet: restoredWallet,
        hardwareWalletType: hardwareWalletType);
  });

  getIt.registerFactoryParam<WalletRestorePage, WalletType, Map<String, dynamic>?>((type, additionalParams) =>
      WalletRestorePage(getIt.get<WalletRestoreViewModel>(param1: type, param2: additionalParams),
          getIt.get<SeedSettingsViewModel>()));

  getIt.registerFactoryParam<WalletRestoreChooseDerivationViewModel, List<DerivationInfo>, void>(
      (derivations, _) => WalletRestoreChooseDerivationViewModel(derivationInfos: derivations));

  getIt.registerFactoryParam<WalletRestoreChooseDerivationPage, List<DerivationInfo>, void>(
      (derivations, _) =>
          WalletRestoreChooseDerivationPage(getIt.get<WalletRestoreChooseDerivationViewModel>(
            param1: derivations,
          )));

  getIt.registerFactoryParam<TransactionDetailsViewModel, List<dynamic>, void>(
          (params, _) {
        final transactionInfo = params[0] as TransactionInfo;
        final canReplaceByFee = params[1] as bool? ?? false;
        final wallet = getIt.get<AppStore>().wallet!;

        return TransactionDetailsViewModel(
          transactionInfo: transactionInfo,
          transactionDescriptionBox: _transactionDescriptionBox,
          wallet: wallet,
          settingsStore: getIt.get<SettingsStore>(),
          sendViewModel: getIt.get<SendViewModel>(),
          canReplaceByFee: canReplaceByFee,
        );
      }
  );

  getIt.registerFactoryParam<TransactionDetailsPage, TransactionInfo, void>(
          (TransactionInfo transactionInfo, _) => TransactionDetailsPage(
          transactionDetailsViewModel: getIt.get<TransactionDetailsViewModel>(
              param1: [transactionInfo, false])));

  getIt.registerFactoryParam<RBFDetailsPage, List<dynamic>, void>(
          (params, _) {
        final transactionInfo = params[0] as TransactionInfo;
        final txHex = params[1] as String;
        return RBFDetailsPage(
          transactionDetailsViewModel: getIt.get<TransactionDetailsViewModel>(
            param1: [transactionInfo, true],
          ),
          rawTransaction: txHex,
        );
      }
  );

  getIt.registerFactoryParam<NewWalletTypePage, NewWalletTypeArguments, void>(
      (newWalletTypeArguments, _) {
    return NewWalletTypePage(
      newWalletTypeArguments: newWalletTypeArguments,
      newWalletTypeViewModel: getIt.get<NewWalletTypeViewModel>(),
    );
  });

  getIt.registerFactory<PreSeedPage>(() => PreSeedPage());

  getIt.registerFactoryParam<TransactionSuccessPage, String, void>(
          (content, _) => TransactionSuccessPage(content: content));

  getIt.registerFactoryParam<TradeDetailsViewModel, Trade, void>((trade, _) =>
      TradeDetailsViewModel(
          tradeForDetails: trade,
          trades: _tradesSource,
          appStore: getIt.get<AppStore>()));

  getIt.registerFactory(() => CakeFeaturesViewModel(getIt.get<CakePayService>()));

  getIt.registerFactory(() => BackupServiceV3(getIt.get<SecureStorage>(),
      _transactionDescriptionBox,
      getIt.get<KeyService>(), getIt.get<SharedPreferences>()));


  getIt.registerFactory(() => BackupPage(getIt.get<BackupViewModel>()));

  getIt.registerLazySingleton<EditBackupPasswordViewModel>(
    () => EditBackupPasswordViewModel(getIt.get<SecureStorage>()),
  );

  getIt.registerFactory(() => BackupViewModel(
      getIt.get<SecureStorage>(),getIt.get<BackupServiceV3>(), getIt.get<EditBackupPasswordViewModel>()));

  getIt.registerFactory(() => EditBackupPasswordPage(getIt.get<EditBackupPasswordViewModel>()));

  getIt.registerFactoryParam<RestoreOptionsPage, bool, void>(
      (bool isNewInstall, _) => RestoreOptionsPage(isNewInstall: isNewInstall));

  getIt.registerFactory(() => RestoreFromBackupViewModel(getIt.get<BackupServiceV3>()));

  getIt.registerFactory(() => RestoreFromBackupPage(getIt.get<RestoreFromBackupViewModel>()));

  getIt.registerFactoryParam<TradeDetailsPage, Trade, void>(
      (Trade trade, _) => TradeDetailsPage(getIt.get<TradeDetailsViewModel>(param1: trade)));

  getIt.registerFactory(() => BuyAmountViewModel());

  getIt.registerFactory(() => BuySellViewModel(getIt.get<AppStore>()));

  getIt.registerFactory(() => BuySellPage(getIt.get<BuySellViewModel>()));

  getIt.registerFactoryParam<BuyOptionsPage, List<dynamic>, void>((List<dynamic> args, _) {
    final items = args.first as List<SelectableItem>;
    final pickAnOption = args[1] as void Function(SelectableOption option)?;
    final confirmOption = args[2] as void Function(BuildContext contex)?;
    return BuyOptionsPage(
        items: items, pickAnOption: pickAnOption, confirmOption: confirmOption);
  });

  getIt.registerFactoryParam<PaymentMethodOptionsPage, List<dynamic>, void>((List<dynamic> args, _) {
    final items = args.first as List<SelectableOption>;
    final pickAnOption = args[1] as void Function(SelectableOption option)?;

    return PaymentMethodOptionsPage(
        items: items, pickAnOption: pickAnOption);
  });

  getIt.registerFactory(() {
    final wallet = getIt.get<AppStore>().wallet;

    return BuyViewModel(_ordersSource, getIt.get<OrdersStore>(), getIt.get<SettingsStore>(),
        getIt.get<BuyAmountViewModel>(),
        wallet: wallet!);
  });

  getIt.registerFactoryParam<BuyWebViewPage, List<dynamic>, void>((List<dynamic> args, _) {
    final url = args.first as String;
    final buyViewModel = args[1] as BuyViewModel;

    return BuyWebViewPage(
        buyViewModel: buyViewModel, ordersStore: getIt.get<OrdersStore>(), url: url);
  });

  getIt.registerFactoryParam<OrderDetailsViewModel, Order, void>((order, _) {
    final wallet = getIt.get<AppStore>().wallet;
    final cakePayService = getIt.get<CakePayService>();

    return OrderDetailsViewModel(
        wallet: wallet!,
        orderForDetails: order,
        cakePayService: cakePayService,
        orders: _ordersSource);
  });

  getIt.registerFactoryParam<OrderDetailsPage, Order, void>(
      (Order order, _) => OrderDetailsPage(getIt.get<OrderDetailsViewModel>(param1: order)));

  getIt.registerFactory(() => SupportViewModel(getIt.get<AppStore>()));

  getIt.registerFactory(() => SupportPage(getIt.get<SupportViewModel>()));

  getIt.registerFactory(() =>
      SupportChatPage(getIt.get<SupportViewModel>(), secureStorage: getIt.get<SecureStorage>()));

  getIt.registerFactory(() => SupportOtherLinksPage(getIt.get<SupportViewModel>()));

  getIt.registerFactoryParam<UnspentCoinsListViewModel, UnspentCoinType?, void>(
      (coinTypeToSpendFrom, _) {
    final wallet = getIt.get<AppStore>().wallet;

    return UnspentCoinsListViewModel(
      wallet: wallet!,
      unspentCoinsInfo: _unspentCoinsInfoSource,
      fiatConversationStore: getIt.get<FiatConversionStore>(),
      settingsStore: getIt.get<SettingsStore>(),
      coinTypeToSpendFrom: coinTypeToSpendFrom ?? UnspentCoinType.any,
    );
  });

  getIt.registerFactoryParam<UnspentCoinsListPage, UnspentCoinType?, void>(
      (coinTypeToSpendFrom, _) => UnspentCoinsListPage(
          unspentCoinsListViewModel:
              getIt.get<UnspentCoinsListViewModel>(param1: coinTypeToSpendFrom)));

  getIt.registerFactoryParam<UnspentCoinsDetailsViewModel, UnspentCoinsItem,
          UnspentCoinsListViewModel>(
      (item, model) =>
          UnspentCoinsDetailsViewModel(unspentCoinsItem: item, unspentCoinsListViewModel: model));

  getIt.registerFactoryParam<UnspentCoinsDetailsPage, List<dynamic>, void>((List<dynamic> args, _) {
    final item = args.first as UnspentCoinsItem;
    final unspentCoinsListViewModel = args[1] as UnspentCoinsListViewModel;

    return UnspentCoinsDetailsPage(
        unspentCoinsDetailsViewModel: getIt.get<UnspentCoinsDetailsViewModel>(
            param1: item, param2: unspentCoinsListViewModel));
  });

  getIt.registerFactory(() => YatService());

  getIt.registerFactory(() => AddressResolver(
      yatService: getIt.get<YatService>(),
      wallet: getIt.get<AppStore>().wallet!,
      settingsStore: getIt.get<SettingsStore>()));

  getIt.registerFactoryParam<FullscreenQRPage, QrViewData, void>(
      (QrViewData viewData, _) => FullscreenQRPage(qrViewData: viewData));

  getIt.registerFactory(() => CakePayApi());

  getIt.registerFactory(() => AnyPayApi());

  getIt.registerFactory<CakePayService>(
      () => CakePayService(getIt.get<SecureStorage>(), getIt.get<CakePayApi>()));

  getIt.registerFactory(
      () => CakePayCardsListViewModel(cakePayService: getIt.get<CakePayService>(),
          settingsStore: getIt.get<SettingsStore>()));

  getIt.registerFactory(() => CakePayAuthViewModel(cakePayService: getIt.get<CakePayService>()));

  getIt.registerFactoryParam<CakePayBuyCardViewModel, CakePayVendor, void>(
      (CakePayVendor vendor, _) {
    return CakePayBuyCardViewModel(vendor: vendor,
        cakePayService: getIt.get<CakePayService>(),
        sendViewModel: getIt.get<SendViewModel>(),
        orders: _ordersSource);
  });

  getIt.registerFactory(() => CakePayAccountViewModel(cakePayService: getIt.get<CakePayService>()));

  getIt.registerFactory(() => CakePayWelcomePage(getIt.get<CakePayAuthViewModel>()));

  getIt.registerFactoryParam<CakePayVerifyOtpPage, List<dynamic>, void>((List<dynamic> args, _) {
    final email = args.first as String;
    final isSignIn = args[1] as bool;

    return CakePayVerifyOtpPage(getIt.get<CakePayAuthViewModel>(), email, isSignIn);
  });

  getIt.registerFactoryParam<CakePayBuyCardPage, List<dynamic>, void>((List<dynamic> args, _) {
    final vendor = args.first as CakePayVendor;

    return CakePayBuyCardPage(getIt.get<CakePayBuyCardViewModel>(param1: vendor));
  });

  getIt.registerFactory(() => CakePayCardsPage(getIt.get<CakePayCardsListViewModel>()));

  getIt.registerFactory(() => CakePayAccountPage(getIt.get<CakePayAccountViewModel>()));

  getIt.registerFactory(() => AnonPayApi(
      useTorOnly: getIt.get<SettingsStore>().exchangeStatus == ExchangeApiMode.torOnly,
      wallet: getIt.get<AppStore>().wallet!));

  getIt.registerFactory(() =>
      DesktopWalletSelectionDropDown(getIt.get<WalletListViewModel>(), getIt.get<AuthService>()));

  getIt.registerFactory(() => DesktopSidebarViewModel());

  getIt.registerFactoryParam<AnonpayDetailsViewModel, AnonpayInvoiceInfo, void>(
      (AnonpayInvoiceInfo anonpayInvoiceInfo, _) => AnonpayDetailsViewModel(
            anonPayApi: getIt.get<AnonPayApi>(),
            anonpayInvoiceInfo: anonpayInvoiceInfo,
            themeStore: getIt.get<ThemeStore>(),
          ));

  getIt.registerFactoryParam<PayjoinDetailsViewModel, String, TransactionInfo?>(
      (String sessionId, TransactionInfo? transactionInfo) =>
          PayjoinDetailsViewModel(
            sessionId,
            transactionInfo,
            payjoinSessionSource: _payjoinSessionSource,
            themeStore: getIt.get<ThemeStore>(),
          ));

  getIt.registerFactoryParam<AnonPayReceivePage, AnonPayReceivePageArgs, void>(
      (AnonPayReceivePageArgs anonpayReceivePageArgs, _) =>
          AnonPayReceivePage(args: anonpayReceivePageArgs));

  getIt.registerFactoryParam<AnonpayDetailsPage, AnonpayInvoiceInfo, void>(
      (AnonpayInvoiceInfo anonpayInvoiceInfo, _) => AnonpayDetailsPage(
          anonpayDetailsViewModel: getIt.get<AnonpayDetailsViewModel>(param1: anonpayInvoiceInfo)));

  getIt.registerFactoryParam<PayjoinDetailsPage, String, TransactionInfo?>(
      (String sessionId, TransactionInfo? transactionInfo) => PayjoinDetailsPage(
          payjoinDetailsViewModel: getIt.get<PayjoinDetailsViewModel>(
              param1: sessionId, param2: transactionInfo)));

  getIt.registerFactoryParam<HomeSettingsPage, BalanceViewModel, void>((balanceViewModel, _) =>
      HomeSettingsPage(getIt.get<HomeSettingsViewModel>(param1: balanceViewModel)));

  getIt.registerFactoryParam<HomeSettingsViewModel, BalanceViewModel, void>(
      (balanceViewModel, _) => HomeSettingsViewModel(getIt.get<SettingsStore>(), balanceViewModel));

  getIt.registerFactoryParam<EditTokenPage, HomeSettingsViewModel, Map<String, dynamic>>(
    (homeSettingsViewModel, arguments) => EditTokenPage(
      homeSettingsViewModel: homeSettingsViewModel,
      token: arguments['token'] as CryptoCurrency?,
      initialContractAddress: arguments['contractAddress'] as String?,
    ),
  );

  getIt.registerFactoryParam<ManageNodesPage, bool, void>((bool isPow, _) {
    if (isPow) {
      return ManageNodesPage(isPow, powNodeListViewModel: getIt.get<PowNodeListViewModel>());
    }
    return ManageNodesPage(isPow, nodeListViewModel: getIt.get<NodeListViewModel>());
  });

  getIt.registerFactory(
    () => WalletConnectConnectionsView(walletKitService: getIt.get<WalletKitService>()),
  );

  getIt.registerFactory(() => NFTViewModel(appStore, getIt.get<BottomSheetService>()));

  getIt.registerFactory(() => SignViewModel(getIt.get<AppStore>().wallet!));

  getIt.registerFactory(() => SeedVerificationPage(getIt.get<WalletSeedViewModel>()));

  getIt.registerFactory(() => DevMoneroBackgroundSyncPage(getIt.get<DevMoneroBackgroundSync>()));

  getIt.registerFactory(() => DevMoneroCallProfilerPage());

  getIt.registerFactory(() => DevMoneroWalletCacheDebugPage());

  getIt.registerFactory(() => DevSharedPreferencesPage(getIt.get<DevSharedPreferences>()));

  getIt.registerFactory(() => DevSecurePreferencesPage(getIt.get<DevSecurePreferences>()));
  
  getIt.registerFactory(() => BackgroundSyncLogsViewModel());
  
  getIt.registerFactory(() => DevBackgroundSyncLogsPage(getIt.get<BackgroundSyncLogsViewModel>()));
  
  getIt.registerFactory(() => SocketHealthLogsViewModel());

  getIt.registerFactory(() => DevSocketHealthLogsPage(getIt.get<SocketHealthLogsViewModel>()));
  
  getIt.registerFactory(() => DevNetworkRequests());
  
  getIt.registerFactory(() => DevQRToolsPage());

  getIt.registerFactory(() => ExchangeProviderLogsViewModel());
  getIt.registerFactory(() => DevExchangeProviderLogsPage(getIt.get<ExchangeProviderLogsViewModel>()));

  getIt.registerFactory(() => StartTorPage(StartTorViewModel(),));

  getIt.registerFactory(() => DEuroViewModel(
        getIt<AppStore>(),
        getIt<BalanceViewModel>(),
        getIt<SettingsStore>(),
        getIt<FiatConversionStore>(),
        getIt.get<AppStore>().wallet!.isHardwareWallet
            ? getIt<HardwareWalletViewModel>(
                param1: getIt.get<AppStore>().wallet!.hardwareWalletType!)
            : null,
      ));

  getIt.registerFactory(() => DEuroSavingsPage(getIt<DEuroViewModel>()));

  getIt.registerLazySingleton(() => NodeSwitchingService(
    appStore: getIt.get<AppStore>(),
    settingsStore: getIt.get<SettingsStore>(),
  ));

  _isSetupFinished = true;
}
