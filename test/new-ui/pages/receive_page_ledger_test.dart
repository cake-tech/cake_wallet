import 'dart:async';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/locales/locale.dart';
import 'package:cake_wallet/new-ui/pages/receive_page.dart';
import 'package:cake_wallet/new-ui/widgets/hardware_wallet/proceed_on_device_message.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/tron/tron.dart' as tron_bridge;
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AddressList extends Mock implements WalletAddressListViewModel {}

class _ReceiveOptions extends Mock implements ReceiveOptionViewModel {}

class _Dashboard extends Mock implements DashboardViewModel {}

class _Settings extends Mock implements SettingsStore {}

class _Wallet extends Mock implements WalletBase {}

class _WalletInfo extends Mock implements WalletInfo {}

class _Hardware extends Mock implements HardwareWalletViewModel {}

class _Tron extends Mock implements tron_bridge.Tron {}

class _Context extends Mock implements BuildContext {}

void main() {
  late _AddressList addressList;
  late _ReceiveOptions options;
  late _Dashboard dashboard;
  late _Wallet wallet;
  late _Hardware hardware;
  late _Tron tron;
  late tron_bridge.Tron? previousTron;

  setUpAll(() {
    registerFallbackValue(_Context());
    registerFallbackValue(_Wallet());
  });

  setUp(() {
    addressList = _AddressList();
    options = _ReceiveOptions();
    dashboard = _Dashboard();
    final settings = _Settings();
    wallet = _Wallet();
    final info = _WalletInfo();
    hardware = _Hardware();
    tron = _Tron();
    previousTron = tron_bridge.tron;
    tron_bridge.tron = tron;
    getIt.registerSingleton(ThemeStore());
    getIt.registerFactoryParam<HardwareWalletViewModel, HardwareWalletType, void>(
      (_, __) => hardware,
    );

    when(() => wallet.type).thenReturn(WalletType.tron);
    when(() => wallet.hardwareWalletType).thenReturn(HardwareWalletType.ledger);
    when(() => wallet.walletInfo).thenReturn(info);
    when(() => info.receiveInfoboxDismissed).thenReturn(true);
    when(() => addressList.wallet).thenReturn(wallet);
    when(() => addressList.type).thenReturn(WalletType.tron);
    when(() => addressList.uri).thenReturn(
      TronURI(amount: '', address: 'TQzMiZ4wGQeKZt6bGyX7vnuV4aS7j2Qx3T'),
    );
    when(() => addressList.forceRecomputeItems).thenReturn([]);
    when(() => addressList.tokenCurrencies).thenReturn([]);
    when(() => addressList.hasAddressRotation).thenReturn(false);
    when(() => addressList.hasAddressList).thenReturn(false);
    when(() => addressList.hasPayjoin).thenReturn(false);
    when(() => addressList.isLightning).thenReturn(false);
    when(() => addressList.isFiatDisabled).thenReturn(true);
    when(() => addressList.displayAmount).thenReturn('');
    when(() => addressList.cryptoCurrencySymbol).thenReturn('TRX');
    when(() => addressList.qrImage).thenReturn('assets/images/trx_chain_qr.svg');
    when(() => options.options).thenReturn([ReceivePageOption.mainnet]);
    when(() => options.selectedReceiveOption).thenReturn(ReceivePageOption.mainnet);
    when(() => dashboard.type).thenReturn(WalletType.tron);
    when(() => dashboard.settingsStore).thenReturn(settings);
    when(() => settings.autoGenerateSubaddressStatus)
        .thenReturn(AutoGenerateSubaddressStatus.disabled);
  });

  tearDown(() async {
    tron_bridge.tron = previousTron;
    await getIt.unregister<HardwareWalletViewModel>();
    await getIt.unregister<ThemeStore>();
  });

  Future<void> openPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: localizationDelegates,
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: NewReceivePage(
          addressListViewModel: addressList,
          receiveOptionViewModel: options,
          dashboardViewModel: dashboard,
          lightningMode: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the receive page waits for reconnection and verifies on the Ledger', (tester) async {
    final connected = Completer<bool>();
    final verified = Completer<void>();
    when(() => hardware.ensureDeviceConnection(any(), wallet)).thenAnswer((_) => connected.future);
    when(() => tron.verifyHardwareAddress(wallet)).thenAnswer((_) => verified.future);
    await openPage(tester);

    await tester.tap(find.text(S.current.verify_address_on_device));
    await tester.pump();
    expect(find.byType(HardwareWalletProceedOnDeviceMessage), findsOneWidget);
    verifyNever(() => tron.verifyHardwareAddress(wallet));
    connected.complete(true);
    await tester.pump();
    verify(() => tron.verifyHardwareAddress(wallet)).called(1);
    verified.complete();
    await tester.pumpAndSettle();
    expect(find.text(S.current.verify_address_on_device), findsOneWidget);
  });

  testWidgets('the receive page hides verification for a software wallet', (tester) async {
    when(() => wallet.hardwareWalletType).thenReturn(null);
    await openPage(tester);
    expect(find.text(S.current.verify_address_on_device), findsNothing);
  });

  testWidgets('the receive page reports device verification errors and resets', (tester) async {
    when(() => hardware.ensureDeviceConnection(any(), wallet)).thenAnswer((_) async => true);
    when(() => tron.verifyHardwareAddress(wallet)).thenThrow(StateError('device mismatch'));
    await openPage(tester);

    await tester.tap(find.text(S.current.verify_address_on_device));
    await tester.pumpAndSettle();
    expect(find.text('Bad state: device mismatch'), findsOneWidget);
    await tester.tap(find.text(S.current.close));
    await tester.pumpAndSettle();
    expect(find.byType(HardwareWalletProceedOnDeviceMessage), findsNothing);
    expect(find.text(S.current.verify_address_on_device), findsOneWidget);
  });

  testWidgets('a wallet switch during reconnect prevents stale verification', (tester) async {
    final connected = Completer<bool>();
    when(() => hardware.ensureDeviceConnection(any(), wallet)).thenAnswer((_) => connected.future);
    await openPage(tester);

    await tester.tap(find.text(S.current.verify_address_on_device));
    await tester.pump();
    final replacement = _Wallet();
    when(() => replacement.type).thenReturn(WalletType.tron);
    when(() => replacement.hardwareWalletType).thenReturn(null);
    when(() => replacement.walletInfo).thenReturn(wallet.walletInfo);
    when(() => addressList.wallet).thenReturn(replacement);
    connected.complete(true);
    await tester.pumpAndSettle();
    verifyNever(() => tron.verifyHardwareAddress(any()));
    expect(find.text(S.current.verify_address_on_device), findsNothing);
  });
}
