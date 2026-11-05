import "dart:async";

import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart";
import "package:cake_wallet/view_model/hardware_wallet/ledger_view_model_dependencies.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus.dart" as sdk;
import "package:mobx/mobx.dart";

class _Wallet implements WalletBase {
  @override
  WalletType get type => WalletType.tron;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HardwareService implements HardwareWalletService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Manager implements sdk.ConnectionManager {
  _Manager(this.deviceStates);
  final Stream<sdk.BleConnectionState> Function(String) deviceStates;
  final disconnected = <String>[];

  @override
  sdk.ConnectionType get connectionType => sdk.ConnectionType.ble;

  @override
  Stream<sdk.BleConnectionState> deviceStateChanges(String deviceId) => deviceStates(deviceId);

  @override
  Future<void> disconnect(String deviceId) async {
    disconnected.add(deviceId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Fixture {
  final wallet = _Wallet();
  final otherWallet = _Wallet();
  final selectedWallet = Observable<WalletBase?>(null);
  late final manager = _Manager((id) => stream(id).stream);
  final streams = <String, StreamController<sdk.BleConnectionState>>{};
  final attached = <WalletBase, sdk.LedgerConnection>{};
  final cleared = <WalletBase>[];
  Completer<void>? initializationGate;
  Completer<sdk.LedgerConnection>? connectGate;
  late final LedgerViewModel viewModel;

  LedgerHardwareWalletDevice device(String id) => LedgerHardwareWalletDevice(
        sdk.LedgerDevice.ble(id: id, name: id, deviceInfo: sdk.LedgerDeviceType.stax),
      );

  StreamController<sdk.BleConnectionState> stream(String id) =>
      streams.putIfAbsent(id, () => StreamController<sdk.BleConnectionState>.broadcast(sync: true));

  void init() {
    selectedWallet.value = wallet;
    viewModel = LedgerViewModel(LedgerViewModelDependencies(
      currentWallet: () => selectedWallet.value,
      supportsHardwareWallets: true,
      getHardwareWalletService: (_, __) => _HardwareService(),
      initWallet: (wallet, connection) async {
        await initializationGate?.future;
        attached[wallet] = connection;
      },
      clearTronService: (wallet) {
        cleared.add(wallet);
        attached.remove(wallet);
      },
      onMoneroDisconnected: (_) {},
      deviceStateChanges: (device) => stream(device.device.id).stream,
      connectDevice: (device) =>
          connectGate?.future ?? Future.value(sdk.LedgerConnection(manager, device.device)),
    ));
  }

  Future<void> dispose() async {
    await viewModel.close();
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Fixture fixture;

  setUp(() {
    fixture = _Fixture()..init();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test("switching A to B replaces the subscription and clears the old wallet service", () async {
    final vm = fixture.viewModel;
    expect(await vm.connectDevice(fixture.device("A"), WalletType.tron), isTrue);
    await vm.initWallet(fixture.wallet);
    final oldConnection = fixture.attached[fixture.wallet]!;

    expect(await vm.connectDevice(fixture.device("B"), WalletType.tron), isTrue);
    expect(oldConnection.isDisconnected, isTrue);
    expect(fixture.manager.disconnected, contains("A"));
    expect(fixture.attached, isNot(contains(fixture.wallet)));
    await vm.initWallet(fixture.wallet);
    final newConnection = fixture.attached[fixture.wallet]!;
    expect(newConnection.device.id, "B");

    fixture.stream("A").add(sdk.BleConnectionState.disconnected);
    expect(vm.isConnected(WalletType.tron), isTrue);
    expect(fixture.attached[fixture.wallet], same(newConnection));

    fixture.stream("B").add(sdk.BleConnectionState.disconnected);
    expect(vm.isConnected(WalletType.tron), isFalse);
    expect(newConnection.isDisconnected, isTrue);
    expect(fixture.attached, isNot(contains(fixture.wallet)));

    expect(await vm.connectDevice(fixture.device("A"), WalletType.tron), isTrue);
    await vm.initWallet(fixture.wallet);
    expect(fixture.attached[fixture.wallet]!.device.id, "A");
  });

  test("switching same-type wallets clears the old attachment", () async {
    final vm = fixture.viewModel;
    await vm.connectDevice(fixture.device("A"), WalletType.tron);
    await vm.initWallet(fixture.wallet);

    runInAction(() => fixture.selectedWallet.value = fixture.otherWallet);
    expect(fixture.attached, isNot(contains(fixture.wallet)));
    expect(vm.isConnected(WalletType.tron), isTrue);
    await vm.initWallet(fixture.otherWallet);
    expect(fixture.attached, contains(fixture.otherWallet));
    await vm.close();
    expect(fixture.attached, isEmpty);
  });

  test("disconnect during initialization cannot reattach a stale service", () async {
    final vm = fixture.viewModel;
    await vm.connectDevice(fixture.device("A"), WalletType.tron);
    fixture.initializationGate = Completer<void>();
    final initializing = vm.initWallet(fixture.wallet);
    final rejected = expectLater(initializing, throwsStateError);
    fixture.stream("A").add(sdk.BleConnectionState.disconnected);
    fixture.initializationGate!.complete();
    await rejected;
    expect(vm.isConnected(WalletType.tron), isFalse);
    expect(fixture.attached, isEmpty);
    expect(fixture.cleared.where((wallet) => identical(wallet, fixture.wallet)).length, 2);
  });

  test("late initialization after reconnect fails closed until reinitialized", () async {
    final vm = fixture.viewModel;
    await vm.connectDevice(fixture.device("A"), WalletType.tron);
    final oldInitialization = Completer<void>();
    fixture.initializationGate = oldInitialization;
    final stale = vm.initWallet(fixture.wallet);
    final rejected = expectLater(stale, throwsStateError);

    fixture.stream("A").add(sdk.BleConnectionState.disconnected);
    await vm.connectDevice(fixture.device("B"), WalletType.tron);
    fixture.initializationGate = null;
    await vm.initWallet(fixture.wallet);
    expect(fixture.attached[fixture.wallet]!.device.id, "B");

    oldInitialization.complete();
    await rejected;
    expect(fixture.attached, isEmpty);
    expect(vm.isConnected(WalletType.tron), isTrue);
    await vm.initWallet(fixture.wallet);
    expect(fixture.attached[fixture.wallet]!.device.id, "B");
  });

  test("disconnect while connecting rejects and disposes the resulting connection", () async {
    final vm = fixture.viewModel;
    fixture.connectGate = Completer<sdk.LedgerConnection>();
    final device = fixture.device("A");
    final connecting = vm.connectDevice(device, WalletType.tron);
    await Future<void>.delayed(Duration.zero);
    fixture.stream("A").add(sdk.BleConnectionState.disconnected);
    final connection = sdk.LedgerConnection(fixture.manager, device.device);
    fixture.connectGate!.complete(connection);
    expect(await connecting, isFalse);
    expect(connection.isDisconnected, isTrue);
    expect(vm.isConnected(WalletType.tron), isFalse);
  });

  test("close invalidates a pending connection without disrupting a later connection", () async {
    final vm = fixture.viewModel;
    final pending = Completer<sdk.LedgerConnection>();
    fixture.connectGate = pending;
    final deviceA = fixture.device("A");
    final connectingA = vm.connectDevice(deviceA, WalletType.tron);
    await Future<void>.delayed(Duration.zero);
    await vm.close();

    fixture.connectGate = null;
    final connectingB = vm.connectDevice(fixture.device("B"), WalletType.tron);
    await Future<void>.delayed(Duration.zero);
    expect(fixture.streams, isNot(contains("B")));
    final stale = sdk.LedgerConnection(fixture.manager, deviceA.device);
    pending.complete(stale);
    expect(await connectingA, isFalse);
    expect(stale.isDisconnected, isTrue);
    expect(await connectingB, isTrue);
    await vm.initWallet(fixture.wallet);
    expect(vm.isConnected(WalletType.tron), isTrue);
    expect(fixture.attached[fixture.wallet]!.device.id, "B");

    fixture.stream("B").add(sdk.BleConnectionState.disconnected);
    expect(vm.isConnected(WalletType.tron), isFalse);
    expect(fixture.attached, isEmpty);
  });

  test("reconnecting the same device waits for the stale connect to be disposed", () async {
    final vm = fixture.viewModel;
    final pending = Completer<sdk.LedgerConnection>();
    fixture.connectGate = pending;
    final device = fixture.device("A");
    final first = vm.connectDevice(device, WalletType.tron);
    await Future<void>.delayed(Duration.zero);
    await vm.close();

    fixture.connectGate = null;
    final second = vm.connectDevice(device, WalletType.tron);
    await Future<void>.delayed(Duration.zero);
    expect(fixture.manager.disconnected, isEmpty);
    pending.complete(sdk.LedgerConnection(fixture.manager, device.device));
    expect(await first, isFalse);
    expect(fixture.manager.disconnected, ["A"]);
    expect(await second, isTrue);
    expect(vm.isConnected(WalletType.tron), isTrue);
    await vm.initWallet(fixture.wallet);
    expect(fixture.attached[fixture.wallet]!.device.id, "A");
  });
}
