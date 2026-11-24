import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/receive_page.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/dashboard/receive_option_view_model.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show Observable, runInAction;
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";

class _AddressList extends Mock implements WalletAddressListViewModel {
  final currentUri = Observable<PaymentURI>(
    MoneroURI(amount: "", address: "test-address"),
  );

  @override
  PaymentURI get uri => currentUri.value;
}

class _ReceiveOptions extends Mock implements ReceiveOptionViewModel {
  final currentOption = Observable(ReceivePageOption.mainnet);

  @override
  ReceivePageOption get selectedReceiveOption => currentOption.value;
}

class _Dashboard extends Mock implements DashboardViewModel {}

class _Settings extends Mock implements SettingsStore {}

class _Wallet extends Mock implements WalletBase {}

class _WalletInfo extends Mock implements WalletInfo {}

void main() {
  testWidgets("Receive releases both reactions after each visit", (tester) async {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton(ThemeStore());
    addTearDown(() => getIt.unregister<ThemeStore>());
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final addresses = _AddressList();
    final options = _ReceiveOptions();
    final dashboard = _Dashboard();
    final settings = _Settings();
    final wallet = _Wallet();
    final info = _WalletInfo();
    when(() => addresses.wallet).thenReturn(wallet);
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => wallet.walletInfo).thenReturn(info);
    when(() => info.receiveInfoboxDismissed).thenReturn(true);
    when(() => addresses.type).thenReturn(WalletType.monero);
    when(() => addresses.forceRecomputeItems).thenAnswer(
      (_) => [
        WalletAddressListItem(
          address: addresses.uri.address,
          isPrimary: true,
          name: addresses.uri.address,
        ),
      ],
    );
    when(() => addresses.tokenCurrencies).thenReturn([]);
    when(() => addresses.tokenCurrency).thenReturn(null);
    when(() => addresses.displayAmount).thenReturn("");
    when(() => addresses.cryptoCurrencySymbol).thenReturn("XMR");
    when(() => addresses.isFiatDisabled).thenReturn(true);
    when(() => addresses.hasAddressRotation).thenReturn(false);
    when(() => addresses.hasAddressList).thenReturn(false);
    when(() => addresses.hasPayjoin).thenReturn(false);
    when(() => addresses.hasTokensList).thenReturn(false);
    when(() => addresses.qrImage).thenReturn("assets/images/xmr_chain_qr.svg");
    when(() => addresses.isLightning).thenReturn(false);
    when(() => options.options).thenReturn([ReceivePageOption.mainnet]);
    when(() => dashboard.type).thenReturn(WalletType.monero);
    when(() => dashboard.settingsStore).thenReturn(settings);
    when(() => settings.autoGenerateSubaddressStatus)
        .thenReturn(AutoGenerateSubaddressStatus.disabled);

    for (var visit = 0; visit < 3; visit++) {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: NewReceivePage(
              addressListViewModel: addresses,
              receiveOptionViewModel: options,
              dashboardViewModel: dashboard,
              lightningMode: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(addresses.currentUri.hasObservers, isTrue);
      expect(options.currentOption.hasObservers, isTrue);

      runInAction(() {
        addresses.currentUri.value = MoneroURI(amount: "", address: "updated-address-$visit");
        options.currentOption.value = ReceivePageOption.testnet;
      });
      await tester.pumpAndSettle();
      expect(find.text("updated-address-$visit"), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(
        addresses.currentUri.hasObservers,
        isFalse,
        reason: "The URI reaction must be disposed after visit $visit",
      );
      expect(
        options.currentOption.hasObservers,
        isFalse,
        reason: "The receive-option reaction must be disposed after visit $visit",
      );

      runInAction(() {
        addresses.currentUri.value = MoneroURI(amount: "", address: "closed-address-$visit");
        options.currentOption.value = ReceivePageOption.mainnet;
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
