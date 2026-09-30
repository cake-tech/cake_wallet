import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" as mobx;
import "package:mocktail/mocktail.dart";

class _MockBitcoin extends Mock implements Bitcoin {}

class _MockWallet extends Mock implements WalletBase {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _FakeSettingsStore extends Fake implements SettingsStore {
  _FakeSettingsStore({
    AutoGenerateSubaddressStatus status = AutoGenerateSubaddressStatus.disabled,
  }) : _status = status;

  final AutoGenerateSubaddressStatus _status;

  @override
  AutoGenerateSubaddressStatus get autoGenerateSubaddressStatus => _status;
}

class _Option implements ReceivePageOption {
  const _Option(this.value);

  @override
  final String value;
  @override
  String? get iconPath => null;
  @override
  String? get description => null;
  @override
  bool get isCommon => false;
  @override
  bool get addAddressWord => false;
  @override
  bool get canRotateAddress => true;
}

const _selectedType = _Option("selected-type");

class _TestScope {
  _TestScope({
    WalletType walletType = WalletType.bitcoin,
    bool autoGenerateSubaddress = false,
    bool autoGeneratesForType = true,
    bool hasPayjoinSupport = false,
    String currentAddress = "addr-current",
    String latestAddress = "",
    AutoGenerateSubaddressStatus autoStatus = AutoGenerateSubaddressStatus.disabled,
  }) : settings = _FakeSettingsStore(status: autoStatus) {
    walletAddresses = _MockWalletAddresses();
    when(() => walletAddresses.address).thenReturn(currentAddress);
    when(() => walletAddresses.latestAddress).thenReturn(latestAddress);
    when(() => walletAddresses.autoGeneratesAddresses(any())).thenReturn(autoGeneratesForType);

    wallet = _MockWallet();
    when(() => wallet.type).thenReturn(walletType);
    when(() => wallet.walletAddresses).thenReturn(walletAddresses);
    when(() => wallet.chainId).thenReturn(null);
    when(() => wallet.isEnabledAutoGenerateSubaddress).thenReturn(autoGenerateSubaddress);
    when(() => wallet.hasPayjoinSupport).thenReturn(hasPayjoinSupport);
  }

  late final _MockWallet wallet;
  late final _MockWalletAddresses walletAddresses;
  final _FakeSettingsStore settings;

  AddressService build() => AddressService(settingsStore: settings);
}

void main() {
  Bitcoin? originalBitcoin;
  late _MockBitcoin mockBitcoin;

  setUpAll(() {
    registerFallbackValue(ReceivePageOption.mainnet);
    registerFallbackValue(_MockWallet());
    originalBitcoin = bitcoin;
  });

  setUp(() {
    mockBitcoin = _MockBitcoin();
    when(() => mockBitcoin.getPayjoinEndpoint(any())).thenReturn("");
    bitcoin = mockBitcoin;
  });

  tearDownAll(() {
    bitcoin = originalBitcoin;
  });

  group("auto-generate subaddress", () {
    test("autoGenerateSubaddressStatus reads settings", () {
      final scope = _TestScope(autoStatus: AutoGenerateSubaddressStatus.enabled);

      expect(scope.build().autoGenerateSubaddressStatus, AutoGenerateSubaddressStatus.enabled);
    });

    test("isAutoGenerateSubaddressEnabled is true when status is on and the type auto-generates",
        () {
      final scope = _TestScope(autoStatus: AutoGenerateSubaddressStatus.enabled);

      expect(scope.build().isAutoGenerateSubaddressEnabled(scope.wallet, _selectedType), isTrue);
      verify(() => scope.walletAddresses.autoGeneratesAddresses(_selectedType)).called(1);
    });

    test("isAutoGenerateSubaddressEnabled is false for a type that does not auto-generate", () {
      final scope = _TestScope(
        autoStatus: AutoGenerateSubaddressStatus.enabled,
        autoGeneratesForType: false,
      );

      expect(scope.build().isAutoGenerateSubaddressEnabled(scope.wallet, _selectedType), isFalse);
    });

    test("isAutoGenerateSubaddressEnabled is false when status is disabled", () {
      final scope = _TestScope(autoStatus: AutoGenerateSubaddressStatus.disabled);

      expect(scope.build().isAutoGenerateSubaddressEnabled(scope.wallet, _selectedType), isFalse);
    });
  });

  group("payjoinEndpointChanges", () {
    test("is empty for wallets without payjoin support", () async {
      final scope = _TestScope(walletType: WalletType.monero);

      final events = await scope.build().payjoinEndpointChanges(scope.wallet).toList();

      expect(events, isEmpty);
      verifyNever(() => mockBitcoin.getPayjoinEndpoint(any()));
    });

    test("emits when the endpoint observable changes, and stops after cancel", () async {
      final scope = _TestScope(hasPayjoinSupport: true);
      final endpoint = mobx.Observable<String>("");
      when(() => mockBitcoin.getPayjoinEndpoint(any())).thenAnswer((_) => endpoint.value);

      int events = 0;
      final sub = scope.build().payjoinEndpointChanges(scope.wallet).listen((_) => events++);
      await Future<void>.delayed(Duration.zero);

      mobx.runInAction(() => endpoint.value = "https://payjo.in/abc");
      await Future<void>.delayed(Duration.zero);
      expect(events, 1);

      await sub.cancel();
      clearInteractions(mockBitcoin);
      mobx.runInAction(() => endpoint.value = "https://payjo.in/def");
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => mockBitcoin.getPayjoinEndpoint(any()));
    });

    test("does not read the endpoint until someone listens", () {
      final scope = _TestScope(hasPayjoinSupport: true);

      scope.build().payjoinEndpointChanges(scope.wallet);

      verifyNever(() => mockBitcoin.getPayjoinEndpoint(any()));
    });
  });
}
