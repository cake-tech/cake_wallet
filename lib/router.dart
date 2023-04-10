import 'package:cake_wallet/anonpay/anonpay_info_base.dart';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/src/screens/anonpay_details/anonpay_details_page.dart';
import 'package:cake_wallet/src/screens/backup/backup_page.dart';
import 'package:cake_wallet/src/screens/backup/edit_backup_password_page.dart';
import 'package:cake_wallet/src/screens/buy/buy_webview_page.dart';
import 'package:cake_wallet/src/screens/buy/onramper_page.dart';
import 'package:cake_wallet/src/screens/buy/payfura_page.dart';
import 'package:cake_wallet/src/screens/buy/pre_order_page.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_invoice_page.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_receive_page.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_dashboard_actions.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/transactions_page.dart';
import 'package:cake_wallet/src/screens/settings/desktop_settings/desktop_settings_page.dart';
import 'package:cake_wallet/src/screens/settings/display_settings_page.dart';
import 'package:cake_wallet/src/screens/settings/other_settings_page.dart';
import 'package:cake_wallet/src/screens/settings/privacy_page.dart';
import 'package:cake_wallet/src/screens/settings/security_backup_page.dart';
import 'package:cake_wallet/src/screens/ionia/cards/ionia_account_cards_page.dart';
import 'package:cake_wallet/src/screens/ionia/cards/ionia_account_page.dart';
import 'package:cake_wallet/src/screens/ionia/cards/ionia_custom_redeem_page.dart';
import 'package:cake_wallet/src/screens/ionia/cards/ionia_custom_tip_page.dart';
import 'package:cake_wallet/src/screens/ionia/cards/ionia_gift_card_detail_page.dart';
import 'package:cake_wallet/src/screens/ionia/cards/ionia_more_options_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/advanced_privacy_settings_page.dart';
import 'package:cake_wallet/src/screens/order_details/order_details_page.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/restore/restore_from_backup_page.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_page.dart';
import 'package:cake_wallet/src/screens/seed/pre_seed_page.dart';
import 'package:cake_wallet/src/screens/settings/connection_sync_page.dart';
import 'package:cake_wallet/src/screens/support/support_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/unspent_coins_details_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/unspent_coins_list_page.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/utils/language_list.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/view_model/wallet_restoration_from_seed_vm.dart';
import 'package:cake_wallet/view_model/wallet_restoration_from_keys_vm.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cake_wallet/src/screens/seed/wallet_seed_page.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/nodes/node_create_or_edit_page.dart';
import 'package:cake_wallet/src/screens/receive/receive_page.dart';
import 'package:cake_wallet/src/screens/subaddress/address_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/new_wallet_page.dart';
import 'package:cake_wallet/src/screens/setup_pin_code/setup_pin_code.dart';
import 'package:cake_wallet/src/screens/restore/restore_options_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_wallet_options_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_wallet_from_seed_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_wallet_from_keys_page.dart';
import 'package:cake_wallet/src/screens/send/send_page.dart';
import 'package:cake_wallet/src/screens/disclaimer/disclaimer_page.dart';
import 'package:cake_wallet/src/screens/seed_language/seed_language_page.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_page.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_edit_or_create_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_page.dart';
import 'package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart';
import 'package:cake_wallet/src/screens/restore/restore_wallet_from_seed_details.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/rescan/rescan_page.dart';
import 'package:cake_wallet/src/screens/faq/faq_page.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_page.dart';
import 'package:cake_wallet/src/screens/welcome/create_welcome_page.dart';
import 'package:cake_wallet/src/screens/new_wallet/new_wallet_type_page.dart';
import 'package:cake_wallet/src/screens/send/send_template_page.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_template_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_confirm_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_page.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/address_page.dart';
import 'package:cake_wallet/src/screens/receive/fullscreen_qr_page.dart';
import 'package:cake_wallet/src/screens/ionia/ionia.dart';
import 'package:cake_wallet/src/screens/ionia/cards/ionia_payment_status_page.dart';
import 'package:cake_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:cake_wallet/ionia/ionia_any_pay_payment_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';

late RouteSettings currentRouteSettings;

Route<dynamic> createRoute(RouteSettings settings) {
  currentRouteSettings = settings;

  switch (settings.name) {
    case Routes.welcome:
      return MaterialPageRoute<void>(builder: (_) => createWelcomePage());

    case Routes.newWalletFromWelcome:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<SetupPinCodePage>(
              param1: (PinCodeState<PinCodeWidget> context, dynamic _) {
	      	  if (availableWalletTypes.length == 1) {
              Navigator.of(context.context).pushNamed(Routes.newWallet, arguments: availableWalletTypes.first);
      		  } else {
      		    Navigator.of(context.context).pushNamed(Routes.newWalletType);
      		  }
		  }),
          fullscreenDialog: true);

    case Routes.newWalletType:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<NewWalletTypePage>(
              param1: (BuildContext context, WalletType type) =>
                  Navigator.of(context)
                      .pushNamed(Routes.newWallet, arguments: type)));

    case Routes.newWallet:
      final type = settings.arguments as WalletType;
      final walletNewVM = getIt.get<WalletNewVM>(param1: type);

      return CupertinoPageRoute<void>(
          builder: (_) => NewWalletPage(walletNewVM));

    case Routes.setupPin:
      Function(PinCodeState<PinCodeWidget>, String)? callback;

      if (settings.arguments is Function(PinCodeState<PinCodeWidget>, String)) {
        callback =
            settings.arguments as Function(PinCodeState<PinCodeWidget>, String);
      }

      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<SetupPinCodePage>(param1: callback));

    case Routes.moneroRestoreWalletFromWelcome:
     return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<SetupPinCodePage>(
              param1: (PinCodeState<PinCodeWidget> context, dynamic _) =>
                  Navigator.pushNamed(
                      context.context, Routes.restoreWallet, arguments: WalletType.monero)),
          fullscreenDialog: true);

    case Routes.restoreWalletType:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<NewWalletTypePage>(
              param1: (BuildContext context, WalletType type) =>
                  Navigator.of(context)
                      .pushNamed(Routes.restoreWallet, arguments: type),
              param2: false));

    case Routes.restoreOptions:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<RestoreOptionsPage>());

    case Routes.restoreWalletOptions:
      final type = WalletType.monero; //settings.arguments as WalletType;

      return CupertinoPageRoute<void>(
          builder: (_) => RestoreWalletOptionsPage(
              type: type,
              onRestoreFromSeed: (context) {
                final route = type == WalletType.monero
                    ? Routes.seedLanguage
                    : Routes.restoreWalletFromSeed;
                final args = type == WalletType.monero
                    ? [type, Routes.restoreWalletFromSeed]
                    : [type];

                Navigator.of(context).pushNamed(route, arguments: args);
              },
              onRestoreFromKeys: (context) {
                final route = type == WalletType.monero
                    ? Routes.seedLanguage
                    : Routes.restoreWalletFromKeys;
                final args = type == WalletType.monero
                    ? [type, Routes.restoreWalletFromKeys]
                    : [type];

                Navigator.of(context).pushNamed(route, arguments: args);
              }));

    case Routes.restoreWalletOptionsFromWelcome:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<SetupPinCodePage>(
              param1: (PinCodeState<PinCodeWidget> context, dynamic _) =>
                  Navigator.pushNamed(
                      context.context, Routes.restoreWalletType)),
          fullscreenDialog: true);

    case Routes.seed:
      return MaterialPageRoute<void>(
          builder: (_) =>
              getIt.get<WalletSeedPage>(param1: settings.arguments as bool));

    case Routes.restoreWallet:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<WalletRestorePage>(
              param1: settings.arguments as WalletType));

    case Routes.restoreWalletFromSeed:
      final type = settings.arguments as WalletType;
      return CupertinoPageRoute<void>(
          builder: (_) => RestoreWalletFromSeedPage(type: type));

    case Routes.restoreWalletFromKeys:
      final args = settings.arguments as List<dynamic>;
      final type = args.first as WalletType;
      final language =
          type == WalletType.monero ? args[1] as String : LanguageList.english;

      final walletRestorationFromKeysVM =
          getIt.get<WalletRestorationFromKeysVM>(param1: [type, language]);

      return CupertinoPageRoute<void>(
          builder: (_) => RestoreWalletFromKeysPage(
              walletRestorationFromKeysVM: walletRestorationFromKeysVM));

    case Routes.dashboard:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<DashboardPage>());

    case Routes.send:
      final initialPaymentRequest = settings.arguments as PaymentRequest?;

      return CupertinoPageRoute<void>(
        fullscreenDialog: true, builder: (_) => getIt.get<SendPage>(
          param1: initialPaymentRequest,
        ));

    case Routes.sendTemplate:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<SendTemplatePage>());

    case Routes.receive:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<ReceivePage>());

    case Routes.addressPage:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<AddressPage>());

    case Routes.transactionDetails:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<TransactionDetailsPage>(
              param1: settings.arguments as TransactionInfo));

    case Routes.newSubaddress:
      return CupertinoPageRoute<void>(
          builder: (_) =>
              getIt.get<AddressEditOrCreatePage>(param1: settings.arguments));

    case Routes.disclaimer:
      return CupertinoPageRoute<void>(builder: (_) => DisclaimerPage());

    case Routes.readDisclaimer:
      return CupertinoPageRoute<void>(
          builder: (_) => DisclaimerPage(isReadOnly: true));

    case Routes.seedLanguage:
      final args = settings.arguments as List<dynamic>;
      final type = args.first as WalletType;
      final redirectRoute = args[1] as String;

      return CupertinoPageRoute<void>(builder: (_) {
        return SeedLanguage(
            onConfirm: (context, lang) => Navigator.of(context)
                .popAndPushNamed(redirectRoute, arguments: [type, lang]));
      });

    case Routes.walletList:
      return MaterialPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<WalletListPage>());

    case Routes.auth:
      return MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<AuthPage>(
              param1: settings.arguments as OnAuthenticationFinished,
              param2: true));

    case Routes.unlock:
      return MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => WillPopScope(
              child: getIt.get<AuthPage>(
                  param1: settings.arguments as OnAuthenticationFinished,
                  param2: false),
              onWillPop: () async => false));

    case Routes.connectionSync:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<ConnectionSyncPage>());

    case Routes.securityBackupPage:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<SecurityBackupPage>());
    
     case Routes.privacyPage:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<PrivacyPage>());

     case Routes.displaySettingsPage:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<DisplaySettingsPage>());

    case Routes.otherSettingsPage:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<OtherSettingsPage>());
    
    case Routes.newNode:
      final args = settings.arguments as Map<String, dynamic>?;
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<NodeCreateOrEditPage>(
            param1: args?['editingNode'] as Node?,
            param2: args?['isSelected'] as bool?));

    case Routes.login:
      return CupertinoPageRoute<void>(
          builder: (context) => WillPopScope(
              child: getIt.get<AuthPage>(instanceName: 'login'),
              onWillPop: () async =>
              // FIX-ME: Additional check does it works correctly
                  (await SystemChannels.platform.invokeMethod<bool>('SystemNavigator.pop') ?? false)),
          fullscreenDialog: true);

    case Routes.accountCreation:
      return CupertinoPageRoute<String>(
          builder: (_) => getIt.get<MoneroAccountEditOrCreatePage>(
              param1: settings.arguments as AccountListItem?));

    case Routes.addressBook:
      return MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<ContactListPage>());

    case Routes.pickerAddressBook:
      final selectedCurrency = settings.arguments as CryptoCurrency?;
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<ContactListPage>(param1: selectedCurrency));

    case Routes.addressBookAddContact:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<ContactPage>(
              param1: settings.arguments as ContactRecord?));

    case Routes.showKeys:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<WalletKeysPage>(), fullscreenDialog: true);

    case Routes.exchangeTrade:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<ExchangeTradePage>());

    case Routes.exchangeConfirm:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<ExchangeConfirmPage>());

    case Routes.tradeDetails:
      return MaterialPageRoute<void>(
          builder: (_) =>
              getIt.get<TradeDetailsPage>(param1: settings.arguments as Trade));

    case Routes.orderDetails:
      return MaterialPageRoute<void>(
          builder: (_) =>
              getIt.get<OrderDetailsPage>(param1: settings.arguments as Order));

    case Routes.preOrder:
      return MaterialPageRoute<void>(
          builder: (_) =>
              getIt.get<PreOrderPage>());

    case Routes.buyWebView:
      final args = settings.arguments as List;

      return MaterialPageRoute<void>(
          builder: (_) =>
              getIt.get<BuyWebViewPage>(param1: args));

    case Routes.restoreWalletFromSeedDetails:
      final args = settings.arguments as List;
      final walletRestorationFromSeedVM =
          getIt.get<WalletRestorationFromSeedVM>(param1: args);

      return CupertinoPageRoute<void>(
          builder: (_) => RestoreWalletFromSeedDetailsPage(
              walletRestorationFromSeedVM: walletRestorationFromSeedVM));

    case Routes.exchange:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<ExchangePage>());

    case Routes.exchangeTemplate:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<ExchangeTemplatePage>());

    case Routes.rescan:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<RescanPage>());

    case Routes.faq:
      return MaterialPageRoute<void>(builder: (_) => getIt.get<FaqPage>());

    case Routes.preSeed:
      return MaterialPageRoute<void>(
          builder: (_) =>
              getIt.get<PreSeedPage>(param1: settings.arguments as WalletType));

    case Routes.backup:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true, builder: (_) => getIt.get<BackupPage>());

    case Routes.editBackupPassword:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<EditBackupPasswordPage>());

    case Routes.restoreFromBackup:
      return CupertinoPageRoute<void>(
          builder: (_) => getIt.get<RestoreFromBackupPage>());

    case Routes.support:
      return CupertinoPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => getIt.get<SupportPage>());

    case Routes.unspentCoinsList:
      return MaterialPageRoute<void>(
          builder: (_) => getIt.get<UnspentCoinsListPage>());

    case Routes.unspentCoinsDetails:
      final args = settings.arguments as List;

      return MaterialPageRoute<void>(
          builder: (_) =>
              getIt.get<UnspentCoinsDetailsPage>(
                  param1: args));

    case Routes.fullscreenQR:
      final args = settings.arguments as Map<String, dynamic>;

      return MaterialPageRoute<void>(
          builder: (_) =>
              getIt.get<FullscreenQRPage>(
                param1: args['qrData'] as String,
                param2: args['version'] as int?,

              ));

    case Routes.ioniaWelcomePage:
      return CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => getIt.get<IoniaWelcomePage>(),
      );
    
    case Routes.ioniaLoginPage:
      return CupertinoPageRoute<void>( builder: (_) => getIt.get<IoniaLoginPage>());

    case Routes.ioniaCreateAccountPage:
      return CupertinoPageRoute<void>( builder: (_) => getIt.get<IoniaCreateAccountPage>());

    case Routes.ioniaManageCardsPage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaManageCardsPage>());

    case Routes.ioniaBuyGiftCardPage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaBuyGiftCardPage>(param1: args));
    
    case Routes.ioniaBuyGiftCardDetailPage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaBuyGiftCardDetailPage>(param1: args));

    case Routes.ioniaVerifyIoniaOtpPage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) =>getIt.get<IoniaVerifyIoniaOtp>(param1: args));

    case Routes.ioniaDebitCardPage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaDebitCardPage>());

    case Routes.ioniaActivateDebitCardPage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaActivateDebitCardPage>());

    case Routes.ioniaAccountPage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaAccountPage>());
    
    case Routes.ioniaAccountCardsPage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaAccountCardsPage>());

    case Routes.ioniaCustomTipPage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) =>getIt.get<IoniaCustomTipPage>(param1: args));

    case Routes.ioniaGiftCardDetailPage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaGiftCardDetailPage>(param1: args.first));
    
    case Routes.ioniaCustomRedeemPage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaCustomRedeemPage>(param1: args));
 
    case Routes.ioniaMoreOptionsPage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaMoreOptionsPage>(param1: args));

    case Routes.ioniaPaymentStatusPage:
      final args = settings.arguments as List;
      final paymentInfo = args.first as IoniaAnyPayPaymentInfo;
      final commitedInfo = args[1] as AnyPayPaymentCommittedInfo;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<IoniaPaymentStatusPage>(
        param1: paymentInfo,
        param2: commitedInfo));

    case Routes.onramperPage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<OnRamperPage>());

    case Routes.payfuraPage:
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<PayFuraPage>());

    case Routes.advancedPrivacySettings:
      final type = settings.arguments as WalletType;

      return CupertinoPageRoute<void>(
          builder: (_) => AdvancedPrivacySettingsPage(
            getIt.get<AdvancedPrivacySettingsViewModel>(param1: type),
            getIt.get<NodeCreateOrEditViewModel>(param1: type),
          ));

    case Routes.anonPayInvoicePage:
      final args = settings.arguments as List;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<AnonPayInvoicePage>(param1: args));

    case Routes.anonPayReceivePage:
        final anonInvoiceViewData = settings.arguments as AnonpayInfoBase;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<AnonPayReceivePage>(param1: anonInvoiceViewData));

    case Routes.anonPayDetailsPage:
      final anonInvoiceViewData = settings.arguments as AnonpayInvoiceInfo;
      return CupertinoPageRoute<void>(builder: (_) => getIt.get<AnonpayDetailsPage>(param1: anonInvoiceViewData));

    case Routes.desktop_actions:
      return PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => DesktopDashboardActions(getIt<DashboardViewModel>()),
      );

    case Routes.desktop_settings_page:
      return CupertinoPageRoute<void>(
          builder: (_) => DesktopSettingsPage());

    case Routes.empty_no_route:
      return MaterialPageRoute<void>(
          builder: (_) => SizedBox.shrink());

    case Routes.transactionsPage:
      return CupertinoPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => getIt.get<TransactionsPage>());

    default:
      return MaterialPageRoute<void>(
          builder: (_) => Scaffold(
              body: Center(
                  child: Text(S.current.router_no_route(settings.name ?? 'No route')))));
  }
}
