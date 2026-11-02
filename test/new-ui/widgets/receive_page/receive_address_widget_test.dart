import 'dart:async';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/locales/locale.dart';
import 'package:cake_wallet/new-ui/widgets/hardware_wallet/proceed_on_device_message.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_address_widget.dart';
import 'package:cake_wallet/view_model/wallet_address_list/receive_address_data.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletAddressListViewModel extends Mock implements ReceiveAddressData {}

ReceiveAddressData _mockAddressListViewModel(WalletType type) {
  final vm = _MockWalletAddressListViewModel();
  when(() => vm.type).thenReturn(type);
  when(() => vm.uri).thenReturn(TronURI(amount: '', address: 'TQzMiZ4wGQeKZt6bGyX7vnuV4aS7j2Qx3T'));
  return vm;
}

void main() {
  late S english;

  setUpAll(() async {
    english = await S.delegate.load(const Locale('en'));
  });

  testWidgets('verify action is hidden by default and visible when enabled', (tester) async {
    final hiddenVm = _mockAddressListViewModel(WalletType.bitcoin);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: ReceiveAddressWidget(
            addressListViewModel: hiddenVm,
            showVerifyAddressButton: false,
          ),
        ),
      ),
    );

    expect(find.text(english.verify_address_on_device), findsNothing);

    final enabledVm = _mockAddressListViewModel(WalletType.tron);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: ReceiveAddressWidget(
            addressListViewModel: enabledVm,
            showVerifyAddressButton: true,
            onVerifyAddressPressed: () async {},
          ),
        ),
      ),
    );

    expect(find.text(english.verify_address_on_device), findsOneWidget);
  });

  testWidgets('pending verification blocks repeated callback invocations', (tester) async {
    var verifyCalls = 0;
    final verifyFinished = Completer<void>();
    final viewModel = _mockAddressListViewModel(WalletType.tron);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: ReceiveAddressWidget(
            addressListViewModel: viewModel,
            showVerifyAddressButton: true,
            onVerifyAddressPressed: () async {
              verifyCalls += 1;
              await verifyFinished.future;
            },
          ),
        ),
      ),
    );

    final onPressed = tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!
        as Future<void> Function();
    final initialPress = onPressed();
    await onPressed();
    await tester.pump();

    expect(verifyCalls, 1);
    expect(find.byType(HardwareWalletProceedOnDeviceMessage), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    verifyFinished.complete();
    await initialPress;
    await tester.pumpAndSettle();

    expect(find.byType(HardwareWalletProceedOnDeviceMessage), findsNothing);
    expect(find.text(english.verify_address_on_device), findsOneWidget);
  });

  testWidgets('verify action surfaces the observed mismatch and resets without success', (
    tester,
  ) async {
    var verifyCalls = 0;
    final observedErrors = <Object>[];
    final verifyResolved = Completer<void>();
    final viewModel = _mockAddressListViewModel(WalletType.tron);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: ReceiveAddressWidget(
            addressListViewModel: viewModel,
            showVerifyAddressButton: true,
            onVerifyAddressPressed: () async {
              verifyCalls += 1;
              try {
                await verifyResolved.future;
                throw StateError('device mismatch');
              } catch (error) {
                observedErrors.add(error);
                rethrow;
              }
            },
          ),
        ),
      ),
    );

    final onPressed = tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!
        as Future<void> Function();
    final future = onPressed();
    await tester.pump();

    expect(verifyCalls, 1);
    expect(find.byType(HardwareWalletProceedOnDeviceMessage), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    verifyResolved.complete();
    await expectLater(
      future,
      throwsA(isA<StateError>().having((error) => error.message, 'message', 'device mismatch')),
    );
    await tester.pumpAndSettle();

    expect(observedErrors, hasLength(1));
    expect(observedErrors.single, isA<StateError>());
    expect((observedErrors.single as StateError).message, 'device mismatch');
    expect(find.byType(HardwareWalletProceedOnDeviceMessage), findsNothing);
    expect(find.text(english.verify_address_on_device), findsOneWidget);
  });
}
