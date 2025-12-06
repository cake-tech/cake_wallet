import 'dart:io';

import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/new-ui/new_dashboard.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/core/new_wallet_type_arguments.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/qr_view_data.dart';
import 'package:cake_wallet/entities/wallet_edit_page_arguments.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/anonpay_details/anonpay_details_page.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/backup/backup_page.dart';
import 'package:cake_wallet/src/screens/backup/edit_backup_password_page.dart';
import 'package:cake_wallet/src/screens/buy/buy_sell_options_page.dart';
import 'package:cake_wallet/src/screens/buy/buy_webview_page.dart';
import 'package:cake_wallet/src/screens/buy/payment_method_options_page.dart';
import 'package:cake_wallet/src/screens/buy/webview_page.dart';
import 'package:cake_wallet/cake_pay/cake_pay.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/screens/connect_device/monero_hardware_wallet_options_page.dart';
import 'package:cake_wallet/src/screens/connect_device/select_device_manufacturer_page.dart';
import 'package:cake_wallet/src/screens/connect_device/select_hardware_wallet_account_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_page.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_dashboard_actions.dart';
import 'package:cake_wallet/src/screens/dashboard/edit_token_page.dart';
import 'package:cake_wallet/src/screens/dashboard/home_settings_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/address_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_details_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/transactions_page.dart';
import 'package:cake_wallet/src/screens/dashboard/sign_page.dart';
import 'package:cake_wallet/src/screens/dev/exchange_provider_logs_page.dart';
import 'package:cake_wallet/src/screens/dev/monero_background_sync.dart';
import 'package:cake_wallet/src/screens/dev/moneroc_cache_debug.dart';
import 'package:cake_wallet/src/screens/dev/moneroc_call_profiler.dart';
import 'package:cake_wallet/src/screens/dev/network_requests.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/src/screens/dev/qr_tools_page.dart';
import 'package:cake_wallet/src/screens/dev/secure_preferences_page.dart';
import 'package:cake_wallet/src/screens/dev/shared_preferences_page.dart';
import 'package:cake_wallet/src/screens/dev/background_sync_logs_page.dart';
import 'package:cake_wallet/src/screens/dev/socket_health_logs_page.dart';
import 'package:cake_wallet/src/screens/disclaimer/disclaimer_page.dart';
import 'package:cake_wallet/src/screens/disclaimer/third_party_disclaimer_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_template_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_confirm_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_external_send_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_page.dart';
import 'package:cake_wallet/src/screens/faq/faq_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/savings_page.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/nano/nano_change_rep_page.dart';
import 'package:cake_wallet/src/screens/nano_accounts/nano_account_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/wallet_group_display_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/advanced_privacy_settings_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/new_wallet_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/new_wallet_type_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/wallet_group_description_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/wallet_group_existing_seed_description_page.dart';
import 'package:cake_wallet/src/screens/nodes/node_create_or_edit_page.dart';
import 'package:cake_wallet/src/screens/nodes/pow_node_create_or_edit_page.dart';
import 'package:cake_wallet/src/screens/order_details/order_details_page.dart';
import 'package:cake_wallet/src/screens/payjoin_details/payjoin_details_page.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/receive/address_list_page.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_invoice_page.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_receive_page.dart';
import 'package:cake_wallet/src/screens/receive/fullscreen_qr_page.dart';
import 'package:cake_wallet/src/screens/receive/receive_page.dart';
import 'package:cake_wallet/src/screens/rescan/rescan_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_from_backup_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_options_page.dart';
import 'package:cake_wallet/src/screens/restore/sweeping_wallet_page.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_choose_derivation.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_page.dart';
import 'package:cake_wallet/src/screens/seed/pre_seed_page.dart';
import 'package:cake_wallet/src/screens/seed/seed_verification/seed_verification_page.dart';
import 'package:cake_wallet/src/screens/seed/wallet_seed_page.dart';
import 'package:cake_wallet/src/screens/send/send_page.dart';
import 'package:cake_wallet/src/screens/send/send_template_page.dart';
import 'package:cake_wallet/src/screens/send/transaction_success_info_page.dart';
import 'package:cake_wallet/src/screens/settings/background_sync_page.dart';
import 'package:cake_wallet/src/screens/settings/connection_sync_page.dart';
import 'package:cake_wallet/src/screens/settings/desktop_settings/desktop_settings_page.dart';
import 'package:cake_wallet/src/screens/settings/display_settings_page.dart';
import 'package:cake_wallet/src/screens/settings/domain_lookups_page.dart';
import 'package:cake_wallet/src/screens/settings/manage_nodes_page.dart';
import 'package:cake_wallet/src/screens/settings/mweb_logs_page.dart';
import 'package:cake_wallet/src/screens/settings/mweb_node_page.dart';
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
import 'package:cake_wallet/src/screens/start_tor/start_tor_page.dart';
import 'package:cake_wallet/src/screens/subaddress/address_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/support/support_page.dart';
import 'package:cake_wallet/src/screens/support_chat/support_chat_page.dart';
import 'package:cake_wallet/src/screens/support_other_links/support_other_links_page.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_page.dart';
import 'package:cake_wallet/src/screens/transaction_details/rbf_details_page.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/unspent_coins_details_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/unspent_coins_list_page.dart';
import 'package:cake_wallet/src/screens/ur/animated_ur_page.dart';
import 'package:cake_wallet/src/screens/wallet/wallet_edit_page.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/wc_connections_listing_view.dart';
import 'package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_page.dart';
import 'package:cake_wallet/src/screens/welcome/create_pin_welcome_page.dart';
import 'package:cake_wallet/src/screens/welcome/welcome_page.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/sign_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cake_wallet/view_model/wallet_groups_display_view_model.dart';
import 'package:cake_wallet/view_model/seed_settings_view_model.dart';
import 'package:cake_wallet/view_model/wallet_hardware_restore_view_model.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/nano_account.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/screens/buy/buy_sell_page.dart';
import 'src/screens/dashboard/pages/nft_import_page.dart';

late RouteSettings currentRouteSettings;

Route<T> handleRouteWithPlatformAwareness<T>(
  Widget Function(BuildContext) builder, {
  bool fullscreenDialog = false,
}) {
  if (Platform.isIOS) {
    return CupertinoPageRoute<T>(builder: builder, fullscreenDialog: fullscreenDialog);
  } else {
    return MaterialPageRoute<T>(builder: builder, fullscreenDialog: fullscreenDialog);
  }
}

Route<dynamic> createRoute(RouteSettings settings) {
  currentRouteSettings = settings;

  printV(settings.name);

  switch (settings.name) {
    case Routes.welcome:
      return MaterialPageRoute<void>(
        builder: (_) => CreatePinWelcomePage(
          SettingsStoreBase.walletPasswordDirectInput,
        ),
      );

    case Routes.welcomeWallet:
      if (SettingsStoreBase.walletPasswordDirectInput) {
        return createRoute(RouteSettings(name: Routes.welcomePage));
      }
      return handleRouteWithPlatformAwareness(
        (_) => getIt.get<SetupPinCodePage>(
          param1: (PinCodeState<PinCodeWidget> context, dynamic _) {
            Navigator.of(context.context).pushNamed(Routes.welcomePage);
          },
        ),
        fullscreenDialog: true,
      );

    case Routes.welcomePage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<WelcomePage>());

    case Routes.newWalletFromWelcome:
      if (isSingleCoin) {
        return createRoute(
          RouteSettings(
              name: Routes.newWallet,
              arguments: NewWalletArguments(type: availableWalletTypes.first)),
        );
      }
      return createRoute(RouteSettings(name: Routes.newWalletType));

    case Routes.newWalletType:
      return handleRouteWithPlatformAwareness(
        (_) => getIt.get<NewWalletTypePage>(
          param1: NewWalletTypeArguments(
            onTypeSelected: (BuildContext context, WalletType type) =>
                Navigator.of(context).pushNamed(
              Routes.newWallet,
              arguments: NewWalletArguments(type: type),
            ),
            isCreate: true,
          ),
        ),
      );

    case Routes.walletGroupsDisplayPage:
      final type = settings.arguments as WalletType;
      final walletGroupsDisplayVM = getIt.get<WalletGroupsDisplayViewModel>(param1: type);

      return handleRouteWithPlatformAwareness(
        (_) => WalletGroupsDisplayPage(
          walletGroupsDisplayVM,
        ),
      );

    case Routes.newWallet:
      final args = settings.arguments as NewWalletArguments;

      final walletNewVM = getIt.get<WalletNewVM>(param1: args);
      final seedSettingsViewModel = getIt.get<SeedSettingsViewModel>();

      return handleRouteWithPlatformAwareness(
        (_) => NewWalletPage(
          walletNewVM,
          seedSettingsViewModel,
          isChildWallet: args.isChildWallet,
        ),
      );

    case Routes.chooseHardwareWalletAccount:
      final arguments = settings.arguments as List<dynamic>;
      final type = arguments[0] as WalletType;
      final hardwareWallet = arguments[1] as HardwareWalletType;

      final walletVM = getIt.get<WalletHardwareRestoreViewModel>(
          param1: type, param2: getIt<HardwareWalletViewModel>(param1: hardwareWallet));

      if (type == WalletType.monero)
        return handleRouteWithPlatformAwareness((_) => MoneroHardwareWalletOptionsPage(walletVM));

      return handleRouteWithPlatformAwareness((_) => SelectHardwareWalletAccountPage(walletVM));

    case Routes.setupPin:
      Function(PinCodeState<PinCodeWidget>, String)? callback;

      if (settings.arguments is Function(PinCodeState<PinCodeWidget>, String)) {
        callback = settings.arguments as Function(PinCodeState<PinCodeWidget>, String);
      }

      return handleRouteWithPlatformAwareness(
        (_) => getIt.get<SetupPinCodePage>(param1: callback),
      );

    case Routes.restoreWalletType:
      return handleRouteWithPlatformAwareness(
        (_) => getIt.get<NewWalletTypePage>(
          param1: NewWalletTypeArguments(
            onTypeSelected: (BuildContext context, WalletType type) {
              final arg = {'walletType': type};
              Navigator.of(context).pushNamed(Routes.restoreWallet, arguments: arg);
            },
            isCreate: false,
          ),
        ),
      );

    case Routes.setupDuressPin:
      Function(PinCodeState<PinCodeWidget>, String)? callback;

      if (settings.arguments is Function(PinCodeState<PinCodeWidget>, String)) {
        callback = settings.arguments as Function(PinCodeState<PinCodeWidget>, String);
      }

      return handleRouteWithPlatformAwareness(
        (_) => getIt.get<SetupPinCodePage>(param1: callback, param2: true),
      );

    case Routes.restoreOptions:
      if (SettingsStoreBase.walletPasswordDirectInput) {
        return createRoute(RouteSettings(name: Routes.restoreWalletType));
      }

      final isNewInstall = settings.arguments as bool;
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<RestoreOptionsPage>(param1: isNewInstall),
      );

    case Routes.restoreWalletFromSeedKeys:
      if (isSingleCoin) {
        return handleRouteWithPlatformAwareness(
          (context) => getIt.get<WalletRestorePage>(param1: availableWalletTypes.first),
        );
      }
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<NewWalletTypePage>(
          param1: NewWalletTypeArguments(
            onTypeSelected: (BuildContext context, WalletType type) {
              final arg = {'walletType': type};
              Navigator.of(context).pushNamed(Routes.restoreWallet, arguments: arg);
            },
            isCreate: false,
          ),
        ),
      );

    case Routes.restoreWalletFromHardwareWallet:
      final arguments = settings.arguments as Map<String, dynamic>?;
      final showUnavailable = (arguments?['showUnavailable'] as bool?) ?? true;
      final onSelect = arguments?['onSelect'] as void Function(BuildContext, HardwareWalletType)?;
      final availableHardwareWalletTypes =
          arguments?['availableHardwareWalletTypes'] as List<HardwareWalletType>?;

      return handleRouteWithPlatformAwareness((_) => SelectDeviceManufacturerPage(
            showUnavailable: showUnavailable,
            onSelect: onSelect,
            availableHardwareWalletTypes: availableHardwareWalletTypes,
          ));

    case Routes.connectHardwareWallet:
      final arguments = settings.arguments as List<dynamic>;
      final hardwareWalletType = (arguments[0] as HardwareWalletType?) ?? HardwareWalletType.ledger;

      if (isSingleCoin) {
        return handleRouteWithPlatformAwareness(
          (_) => ConnectDevicePage(
            ConnectDevicePageParams(
              walletType: availableWalletTypes.first,
              hardwareWalletType: hardwareWalletType,
              onConnectDevice: (BuildContext context, _) => Navigator.of(context).pushNamed(
                  Routes.chooseHardwareWalletAccount,
                  arguments: [availableWalletTypes.first, hardwareWalletType]),
              isReconnect: false,
            ),
            getIt.get<LedgerViewModel>(),
          ),
        );
      }
      return handleRouteWithPlatformAwareness(
        (_) => getIt.get<NewWalletTypePage>(
          param1: NewWalletTypeArguments(
            onTypeSelected: (BuildContext context, WalletType type) {
              if (hardwareWalletType == HardwareWalletType.trezor) {
                Navigator.of(context).pushNamed(Routes.chooseHardwareWalletAccount,
                    arguments: [type, hardwareWalletType]);
                return;
              }

              final arguments = ConnectDevicePageParams(
                walletType: type,
                hardwareWalletType: hardwareWalletType,
                onConnectDevice: (BuildContext context, _) => Navigator.of(context).pushNamed(
                    Routes.chooseHardwareWalletAccount,
                    arguments: [type, hardwareWalletType]),
                isReconnect: false,
              );

              Navigator.of(context).pushNamed(Routes.connectDevices, arguments: arguments);
            },
            isCreate: false,
            hardwareWalletType: hardwareWalletType,
          ),
        ),
      );

    case Routes.restoreWalletTypeFromQR:
      return CupertinoPageRoute<void>(
        builder: (_) => getIt.get<NewWalletTypePage>(
          param1: NewWalletTypeArguments(
            onTypeSelected: (BuildContext context, WalletType type) =>
                Navigator.of(context).pop(type),
            isCreate: false,
          ),
        ),
      );

    case Routes.seed:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<WalletSeedPage>(param1: settings.arguments as bool),
      );

    case Routes.restoreWallet:
      final args = settings.arguments as Map<String, dynamic>?;
      final walletType = args?['walletType'] as WalletType;
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<WalletRestorePage>(param1: walletType, param2: args));

    case Routes.restoreWalletChooseDerivation:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<WalletRestoreChooseDerivationPage>(
              param1: settings.arguments as List<DerivationInfo>));

    case Routes.sweepingWalletPage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<SweepingWalletPage>());

    case Routes.dashboard:
      return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) =>
              FeatureFlag.hasNewUi ? getIt.get<NewDashboard>() : getIt.get<DashboardPage>());

    case Routes.send:
      final args = settings.arguments as Map<String, dynamic>?;
      final initialPaymentRequest = args?['paymentRequest'] as PaymentRequest?;
      final coinTypeToSpendFrom = args?['coinTypeToSpendFrom'] as UnspentCoinType?;

      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<SendPage>(
          param1: initialPaymentRequest,
          param2: coinTypeToSpendFrom,
        ),
      );

    case Routes.sendTemplate:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<SendTemplatePage>());

    case Routes.receive:
      return CupertinoPageRoute<void>(builder: (context) => getIt.get<ReceivePage>());

    case Routes.addressPage:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<AddressPage>(),
      );

    case Routes.transactionDetails:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) =>
              getIt.get<TransactionDetailsPage>(param1: settings.arguments as TransactionInfo));

    case Routes.bumpFeePage:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<RBFDetailsPage>(param1: settings.arguments as List<dynamic>));

    case Routes.newSubaddress:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<AddressEditOrCreatePage>(param1: settings.arguments));

    case Routes.disclaimer:
      return CupertinoPageRoute<void>(builder: (_) => DisclaimerPage());

    case Routes.readDisclaimer:
      return CupertinoPageRoute<void>(builder: (_) => DisclaimerPage(isReadOnly: true));

    case Routes.readThirdPartyDisclaimer:
      return CupertinoPageRoute<void>(builder: (_) => ThirdPartyDisclaimerPage());

    case Routes.changeRep:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<NanoChangeRepPage>());

    case Routes.walletList:
      final onWalletLoaded = settings.arguments as Function(BuildContext)?;
      return MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => getIt.get<WalletListPage>(param1: onWalletLoaded),
      );

    case Routes.walletEdit:
      return MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            getIt.get<WalletEditPage>(param1: settings.arguments as WalletEditPageArguments),
      );

    case Routes.auth:
      return MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => SettingsStoreBase.walletPasswordDirectInput
              ? getIt.get<WalletUnlockPage>(
                  param1: WalletUnlockArguments(
                      callback: settings.arguments as OnAuthenticationFinished),
                  instanceName: 'wallet_unlock_verifiable',
                  param2: true)
              : getIt.get<AuthPage>(
                  param1: settings.arguments as OnAuthenticationFinished, param2: true));

    case Routes.totpAuthCodePage:
      final args = settings.arguments as TotpAuthArgumentsModel;
      return MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => getIt.get<TotpAuthCodePage>(
          param1: args,
        ),
      );

    case Routes.walletUnlockLoadable:
      return MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<WalletUnlockPage>(
              param1: settings.arguments as WalletUnlockArguments,
              instanceName: 'wallet_unlock_loadable',
              param2: true));

    case Routes.unlock:
      return MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => SettingsStoreBase.walletPasswordDirectInput
              ? WillPopScope(
                  child: getIt.get<WalletUnlockPage>(
                      param1: WalletUnlockArguments(
                          callback: settings.arguments as OnAuthenticationFinished),
                      param2: false,
                      instanceName: 'wallet_unlock_verifiable'),
                  onWillPop: () async => false)
              : WillPopScope(
                  child: getIt.get<AuthPage>(
                      param1: settings.arguments as OnAuthenticationFinished, param2: false),
                  onWillPop: () async => false));

    case Routes.silentPaymentsSettings:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<SilentPaymentsSettingsPage>(),
      );

    case Routes.silentPaymentsLogs:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<SilentPaymentsLogPage>(),
      );

    case Routes.mwebSettings:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<MwebSettingsPage>(),
      );

    case Routes.mwebLogs:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<MwebLogsPage>(),
      );

    case Routes.mwebNode:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<MwebNodePage>(),
      );

    case Routes.connectionSync:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<ConnectionSyncPage>(),
      );

    case Routes.securityBackupPage:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<SecurityBackupPage>(),
      );

    case Routes.securityBackupDuressPin:
      return handleRouteWithPlatformAwareness(
            (context) => getIt.get<SecurityBackupPage>(),
      );


    case Routes.privacyPage:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<PrivacyPage>(),
      );

    case Routes.trocadorProvidersPage:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<TrocadorProvidersPage>());

    case Routes.domainLookupsPage:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<DomainLookupsPage>());

    case Routes.displaySettingsPage:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<DisplaySettingsPage>(),
      );

    case Routes.otherSettingsPage:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<OtherSettingsPage>(),
      );

    case Routes.newNode:
      final args = settings.arguments as Map<String, dynamic>?;
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<NodeCreateOrEditPage>(
              param1: args?['editingNode'] as Node?, param2: args?['isSelected'] as bool?));

    case Routes.login:
      return CupertinoPageRoute<void>(
          builder: (context) => WillPopScope(
              child: SettingsStoreBase.walletPasswordDirectInput
                  ? getIt.get<WalletUnlockPage>(instanceName: 'wallet_password_login')
                  : getIt.get<AuthPage>(instanceName: 'login'),
              onWillPop: () async =>
                  // FIX-ME: Additional check does it works correctly
                  (await SystemChannels.platform.invokeMethod<bool>('SystemNavigator.pop') ??
                      false)),
          fullscreenDialog: true);

    case Routes.newPowNode:
      final args = settings.arguments as Map<String, dynamic>?;
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<PowNodeCreateOrEditPage>(
              param1: args?['editingNode'] as Node?, param2: args?['isSelected'] as bool?));

    case Routes.accountCreation:
      return CupertinoPageRoute<String>(
          builder: (_) => getIt.get<MoneroAccountEditOrCreatePage>(
              param1: settings.arguments as AccountListItem?));

    case Routes.nanoAccountCreation:
      return CupertinoPageRoute<String>(
          builder: (_) =>
              getIt.get<NanoAccountEditOrCreatePage>(param1: settings.arguments as NanoAccount?));

    case Routes.addressBook:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<ContactListPage>(),
      );

    case Routes.pickerAddressBook:
      final selectedCurrency = settings.arguments as CryptoCurrency?;
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<ContactListPage>(param1: selectedCurrency));

    case Routes.pickerWalletAddress:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<AddressListPage>());

    case Routes.addressBookAddContact:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<ContactPage>(param1: settings.arguments as ContactRecord?),
      );

    case Routes.showKeys:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<WalletKeysPage>(),
      );

    case Routes.exchangeTrade:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<ExchangeTradePage>());

    case Routes.exchangeConfirm:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<ExchangeConfirmPage>());

    case Routes.tradeDetails:
      return MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<TradeDetailsPage>(param1: settings.arguments as Trade));

    case Routes.orderDetails:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<OrderDetailsPage>(param1: settings.arguments as Order));

    case Routes.buySellPage:
      final args = settings.arguments as bool;
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<BuySellPage>(param1: args),
      );

    case Routes.buyOptionsPage:
      final args = settings.arguments as List;
      return MaterialPageRoute<void>(builder: (_) => getIt.get<BuyOptionsPage>(param1: args));

    case Routes.paymentMethodOptionsPage:
      final args = settings.arguments as List;
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<PaymentMethodOptionsPage>(param1: args));

    case Routes.buyWebView:
      final args = settings.arguments as List;

      return MaterialPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<BuyWebViewPage>(param1: args));

    case Routes.exchange:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<ExchangePage>(param1: settings.arguments as PaymentRequest?),
      );

    case Routes.exchangeTemplate:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<ExchangeTemplatePage>());

    case Routes.rescan:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<RescanPage>());

    case Routes.faq:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<FaqPage>());

    case Routes.preSeedPage:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<PreSeedPage>());

    case Routes.walletGroupExistingSeedDescriptionPage:
      return MaterialPageRoute<void>(builder: (_) => WalletGroupExistingSeedDescriptionPage());

    case Routes.transactionSuccessPage:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<TransactionSuccessPage>(param1: settings.arguments as String));

    case Routes.backup:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<BackupPage>(),
      );

    case Routes.editBackupPassword:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<EditBackupPasswordPage>());

    case Routes.restoreFromBackup:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<RestoreFromBackupPage>());

    case Routes.support:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<SupportPage>(),
      );

    case Routes.supportLiveChat:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<SupportChatPage>());

    case Routes.supportOtherLinks:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<SupportOtherLinksPage>(),
      );

    case Routes.unspentCoinsList:
      final coinTypeToSpendFrom = settings.arguments as UnspentCoinType?;
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<UnspentCoinsListPage>(param1: coinTypeToSpendFrom),
      );

    case Routes.unspentCoinsDetails:
      final args = settings.arguments as List;

      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<UnspentCoinsDetailsPage>(param1: args));

    case Routes.fullscreenQR:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<FullscreenQRPage>(
                param1: settings.arguments as QrViewData,
              ));

    case Routes.cakePayCardsPage:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<CakePayCardsPage>(),
      );

    case Routes.cakePayBuyCardPage:
      final args = settings.arguments as List;
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<CakePayBuyCardPage>(param1: args),
      );

    case Routes.cakePayWelcomePage:
      return handleRouteWithPlatformAwareness<bool>(
        (context) => getIt.get<CakePayWelcomePage>(),
      );

    case Routes.cakePayVerifyOtpPage:
      final args = settings.arguments as List;
      return handleRouteWithPlatformAwareness<bool>(
        (context) => getIt.get<CakePayVerifyOtpPage>(param1: args),
      );

    case Routes.cakePayAccountPage:
      return handleRouteWithPlatformAwareness<bool>(
        (context) => getIt.get<CakePayAccountPage>(),
      );

    case Routes.webViewPage:
      final args = settings.arguments as List;
      final title = args.first as String;
      final url = args[1] as Uri;
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<WebViewPage>(param1: title, param2: url));

    case Routes.advancedPrivacySettings:
      final args = settings.arguments as Map<String, dynamic>;
      final type = args['type'] as WalletType;
      final isFromRestore = args['isFromRestore'] as bool? ?? false;
      final isChildWallet = args['isChildWallet'] as bool? ?? false;
      final useTestnet = args['useTestnet'] as bool;
      final toggleTestnet = args['toggleTestnet'] as Function(bool? val);
      final restoredWallet = args['restoredWallet'] as RestoredWallet?;

      final viewModelParam = {'type' : type, 'isPow' : false};

      return handleRouteWithPlatformAwareness(
        (context) => AdvancedPrivacySettingsPage(
          isFromRestore: isFromRestore,
          isChildWallet: isChildWallet,
          useTestnet: useTestnet,
          toggleUseTestnet: toggleTestnet,
          advancedPrivacySettingsViewModel:
              getIt.get<AdvancedPrivacySettingsViewModel>(param1: type),
          nodeViewModel: getIt.get<NodeCreateOrEditViewModel>(param1: viewModelParam),
          seedSettingsViewModel: getIt.get<SeedSettingsViewModel>(),
        ),
      );

    case Routes.anonPayInvoicePage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<AnonPayInvoicePage>(param1: args));

    case Routes.anonPayReceivePage:
      final anonReceivePageArgs = settings.arguments as AnonPayReceivePageArgs;
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<AnonPayReceivePage>(param1: anonReceivePageArgs));

    case Routes.anonPayDetailsPage:
      final anonInvoiceViewData = settings.arguments as AnonpayInvoiceInfo;
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<AnonpayDetailsPage>(param1: anonInvoiceViewData));

    case Routes.payjoinDetails:
      final arguments = settings.arguments as List;
      final sessionId = arguments.first as String;
      final transactionInfo = arguments[1] as TransactionInfo?;
      return CupertinoPageRoute<void>(
          builder: (_) =>
              getIt.get<PayjoinDetailsPage>(param1: sessionId, param2: transactionInfo));

    case Routes.desktop_actions:
      return PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => DesktopDashboardActions(getIt<DashboardViewModel>()),
      );

    case Routes.desktop_settings_page:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<DesktopSettingsPage>());

    case Routes.empty_no_route:
      return MaterialPageRoute<void>(builder: (_) => SizedBox.shrink());

    case Routes.transactionsPage:
      return CupertinoPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => getIt.get<TransactionsPage>());

    case Routes.setup_2faPage:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<Setup2FAPage>());

    case Routes.setup_2faQRPage:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<Setup2FAQRPage>());

    case Routes.modify2FAPage:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<Modify2FAPage>());

    case Routes.setup2faInfoPage:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<Setup2FAInfoPage>());

    case Routes.urqrAnimatedPage:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<AnimatedURPage>(param1: settings.arguments));

    case Routes.homeSettings:
      return CupertinoPageRoute<void>(
        builder: (_) => getIt.get<HomeSettingsPage>(param1: settings.arguments),
      );

    case Routes.editToken:
      final args = settings.arguments as Map<String, dynamic>;

      return CupertinoPageRoute<void>(
        settings: RouteSettings(name: Routes.editToken),
        builder: (_) => getIt.get<EditTokenPage>(
          param1: args['homeSettingsViewModel'],
          param2: {
            'token': args['token'],
            'contractAddress': args['contractAddress'],
          },
        ),
      );

    case Routes.manageNodes:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<ManageNodesPage>(param1: false));

    case Routes.managePowNodes:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<ManageNodesPage>(param1: true));

    case Routes.walletConnectConnectionsListing:
      return MaterialPageRoute<void>(
          builder: (_) => WalletConnectConnectionsView(
                walletKitService: getIt.get<WalletKitService>(),
                launchUri: settings.arguments as Uri?,
              ));

    case Routes.nftDetailsPage:
      return MaterialPageRoute<void>(
        builder: (_) => NFTDetailsPage(
          arguments: settings.arguments as NFTDetailsPageArguments,
          dashboardViewModel: getIt.get<DashboardViewModel>(),
        ),
      );

    case Routes.importNFTPage:
      return MaterialPageRoute<void>(
        builder: (_) => ImportNFTPage(
          nftViewModel: settings.arguments as NFTViewModel,
        ),
      );

    case Routes.signPage:
      return MaterialPageRoute<void>(
        builder: (_) => SignPage(
          getIt.get<SignViewModel>(),
        ),
      );

    case Routes.connectDevices:
      final params = settings.arguments as ConnectDevicePageParams;

      return MaterialPageRoute<void>(
          builder: (_) => ConnectDevicePage(
              params, getIt.get<HardwareWalletViewModel>(param1: params.hardwareWalletType)));

    case Routes.walletGroupDescription:
      final walletType = settings.arguments as WalletType;

      return MaterialPageRoute<void>(
        builder: (_) => WalletGroupDescriptionPage(
          selectedWalletType: walletType,
        ),
      );

    case Routes.walletSeedVerificationPage:
      return MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => getIt.get<SeedVerificationPage>(),
      );

    case Routes.exchangeTradeExternalSendPage:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<ExchangeTradeExternalSendPage>(),
      );

    case Routes.backgroundSync:
      return handleRouteWithPlatformAwareness(
        (context) => getIt.get<BackgroundSyncPage>(),
      );

    case Routes.devMoneroBackgroundSync:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevMoneroBackgroundSyncPage>(),
      );
    case Routes.devSharedPreferences:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevSharedPreferencesPage>(),
      );

    case Routes.devBackgroundSyncLogs:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevBackgroundSyncLogsPage>(),
      );

    case Routes.devSocketHealthLogs:
      return CupertinoPageRoute<void>(
        builder: (_) => getIt.get<DevSocketHealthLogsPage>(),
      );

    case Routes.devQRTools:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevQRToolsPage>(),
      );

    case Routes.devNetworkRequests:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevNetworkRequests>(),
      );

    case Routes.devExchangeProviderLogs:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevExchangeProviderLogsPage>(),
      );

    case Routes.devMoneroCallProfiler:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevMoneroCallProfilerPage>(),
      );

    case Routes.devMoneroWalletCacheDebug:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevMoneroWalletCacheDebugPage>(),
      );

    case Routes.devSecurePreferences:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DevSecurePreferencesPage>(),
      );

    case Routes.startTor:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<StartTorPage>(),
      );

    case Routes.dEuroSavings:
      return MaterialPageRoute<void>(
        builder: (_) => getIt.get<DEuroSavingsPage>(),
      );

    default:
      return MaterialPageRoute<void>(
          builder: (_) => Scaffold(
              body: Center(child: Text(S.current.router_no_route(settings.name ?? 'No route')))));
  }
}
