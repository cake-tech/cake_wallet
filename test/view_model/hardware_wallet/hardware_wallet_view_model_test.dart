import "dart:async";

import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page_params.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

class _WalletInfo implements WalletInfo {
  @override
  WalletType get type => WalletType.tron;

  @override
  HardwareWalletType get hardwareWalletType => HardwareWalletType.ledger;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Wallet implements WalletBase {
  @override
  bool get isHardwareWallet => true;

  @override
  WalletInfo get walletInfo => _WalletInfo();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HardwareViewModel extends HardwareWalletViewModel {
  bool connected = false;
  final initialization = Completer<void>();
  Completer<bool>? connection;
  int initializationCount = 0;

  @override
  bool get hasBluetooth => false;

  @override
  bool get isBleEnabled => false;

  @override
  bool get isConnecting => false;

  @override
  Future<void> updateBleState() async {}

  @override
  Future<void> stopScanning() async {}

  @override
  Future<List<HardwareWalletDevice>> getConnectedBleDevices() async => [_Device()];

  @override
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    connected = await (connection?.future ?? Future.value(true));
    return connected;
  }

  @override
  bool isConnected(WalletType type) => connected;

  @override
  Future<void> initWallet(WalletBase wallet) {
    initializationCount++;
    return initialization.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Device implements HardwareWalletDevice {
  @override
  String get name => "Test Ledger";

  @override
  HardwareWalletDeviceType get type => HardwareWalletDeviceType.ledgerStax;

  @override
  HardwareWalletConnectionType get connectionType => HardwareWalletConnectionType.ble;
}

void main() {
  testWidgets("reconnection waits for wallet service attachment", (tester) async {
    final vm = _HardwareViewModel();
    final wallet = _Wallet();
    bool? result;

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        expect(settings.name, Routes.connectDevices);
        final params = settings.arguments! as ConnectDevicePageParams;
        return MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key("connect"),
              onPressed: () {
                vm.connected = true;
                params.onConnectDevice(context, vm);
              },
              child: const Text("Connect"),
            ),
          ),
        );
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key("begin"),
            onPressed: () async {
              result = await vm.ensureDeviceConnection(context, wallet);
            },
            child: const Text("Begin"),
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key("begin")));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("connect")));
    await tester.pump();
    await tester.tap(find.byKey(const Key("connect")));
    await tester.pump();
    expect(vm.initializationCount, 1);
    expect(result, isNull);
    expect(find.byKey(const Key("connect")), findsOneWidget);

    vm.initialization.complete();
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byKey(const Key("connect")), findsNothing);
  });

  testWidgets("attachment errors are returned to the reconnect caller", (tester) async {
    final vm = _HardwareViewModel();
    Object? error;

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        final params = settings.arguments! as ConnectDevicePageParams;
        return MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key("connect"),
              onPressed: () {
                vm.connected = true;
                params.onConnectDevice(context, vm);
              },
              child: const Text("Connect"),
            ),
          ),
        );
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key("begin"),
            onPressed: () async {
              try {
                await vm.ensureDeviceConnection(context, _Wallet());
              } catch (e) {
                error = e;
              }
            },
            child: const Text("Begin"),
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key("begin")));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("connect")));
    await tester.pump();
    vm.initialization.completeError(StateError("attachment failed"));
    await tester.pumpAndSettle();
    expect(error, isA<StateError>());
  });

  for (final failLate in [false, true]) {
    testWidgets(
        "back during attachment returns false and ignores late ${failLate ? "failure" : "success"}",
        (tester) async {
      final vm = _HardwareViewModel();
      final wallet = _Wallet();
      bool? result;
      Object? error;
      var continued = 0;
      var callbacks = 0;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        onGenerateRoute: (settings) {
          expect(settings.name, Routes.connectDevices);
          final params = settings.arguments! as ConnectDevicePageParams;
          return MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(),
              body: ConnectDevicePageBody(
                params.walletType,
                (context, hardware) {
                  callbacks++;
                  params.onConnectDevice(context, hardware);
                },
                vm,
                ThemeStore().currentTheme,
              ),
            ),
          );
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key("underlying-send"),
              onPressed: () async {
                try {
                  result = await vm.ensureDeviceConnection(context, wallet);
                  if (result == true) continued++;
                } catch (e) {
                  error = e;
                }
              },
              child: const Text("Send"),
            ),
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key("underlying-send")));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Test Ledger"));
      await tester.pump();
      tester.binding.scheduleFrame();
      await tester.pumpAndSettle();
      expect(vm.connected, isTrue);
      expect(ModalRoute.of(tester.element(find.byType(ConnectDevicePageBody)))?.isCurrent, isTrue);
      expect(callbacks, 1);
      expect(vm.initializationCount, 1);
      expect(result, isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.byKey(const Key("underlying-send")), findsOneWidget);

      if (failLate) {
        vm.initialization.completeError(StateError("late attachment failure"));
      } else {
        vm.initialization.complete();
      }
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(error, isNull);
      expect(continued, 0);
      expect(find.byKey(const Key("underlying-send")), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("a late device connection cannot invoke a dismissed route callback", (tester) async {
    final vm = _HardwareViewModel()..connection = Completer<bool>();
    bool? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: localizationDelegates,
      supportedLocales: S.delegate.supportedLocales,
      onGenerateRoute: (settings) {
        final params = settings.arguments! as ConnectDevicePageParams;
        return MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(),
            body: ConnectDevicePageBody(
              params.walletType,
              params.onConnectDevice,
              vm,
              ThemeStore().currentTheme,
            ),
          ),
        );
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key("underlying-send"),
            onPressed: () async => result = await vm.ensureDeviceConnection(context, _Wallet()),
            child: const Text("Send"),
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key("underlying-send")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Test Ledger"));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(result, isFalse);
    vm.connection!.complete(true);
    await tester.pump();
    tester.binding.scheduleFrame();
    await tester.pumpAndSettle();
    expect(vm.initializationCount, 0);
    expect(find.byKey(const Key("underlying-send")), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
