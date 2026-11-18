import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/reset_service.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/biometric_auth.dart";
import "package:cake_wallet/entities/encrypt.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/authentication_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/auth_view_model.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockAppStore extends Mock implements AppStore {}

class _MockResetService extends Mock implements ResetService {}

class _MockAuthService extends Mock implements AuthService {}

class _MockBiometricAuth extends Mock implements BiometricAuth {}

const _pinKey = "PIN_CODE_PASSWORD";
const _duressKey = "DURESS_PIN_CODE_PASSWORD";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences sharedPreferences;

  setUpAll(() {
    S.current = const S();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  group("AuthService.authenticate", () {
    late _MockSecureStorage secureStorage;
    late AuthService authService;

    setUp(() {
      secureStorage = _MockSecureStorage();
      authService = AuthService(
        secureStorage: secureStorage,
        sharedPreferences: sharedPreferences,
        settingsStore: _MockSettingsStore(),
        authenticationStore: AuthenticationStore(),
        appStore: _MockAppStore(),
        resetService: _MockResetService(),
        walletList: [],
      );
    });

    test("throws PinCodeUnreadableException instead of a null-check error", () async {
      when(() => secureStorage.read(key: _pinKey)).thenAnswer((_) async => null);

      await expectLater(
        authService.authenticate("1234"),
        throwsA(
          isA<PinCodeUnreadableException>()
              // Not iOS here, so no Keychain status is fetched.
              .having((e) => e.keychainStatus, "keychainStatus", isNull),
        ),
      );
      verifyNever(() => secureStorage.read(key: _duressKey));
    });

    test("still accepts the right PIN and rejects a wrong one", () async {
      when(() => secureStorage.read(key: _pinKey))
          .thenAnswer((_) async => encodedPinCode(pin: "1234"));
      when(() => secureStorage.read(key: _duressKey)).thenAnswer((_) async => null);

      expect(await authService.authenticate("1234"), isTrue);
      expect(await authService.authenticate("0000"), isFalse);
    });
  });

  group("AuthViewModel.auth", () {
    late _MockAuthService authService;
    late AuthViewModel viewModel;

    setUp(() {
      authService = _MockAuthService();
      viewModel = AuthViewModel(
        authService,
        sharedPreferences,
        _MockSettingsStore(),
        _MockBiometricAuth(),
      );
    });

    test("leaves the executing state with the unreadable-PIN message and status", () async {
      when(() => authService.authenticate(any()))
          .thenAnswer((_) => Future<bool>.error(PinCodeUnreadableException(-25308)));

      await viewModel.auth(password: "1234");

      expect(
        viewModel.state,
        isA<FailureState>().having(
          (s) => s.error,
          "error",
          "${S.current.auth_store_pin_unreadable} (OSStatus -25308)",
        ),
      );
    });

    test("omits the status suffix when no status is available", () async {
      when(() => authService.authenticate(any()))
          .thenAnswer((_) => Future<bool>.error(PinCodeUnreadableException(null)));

      await viewModel.auth(password: "1234");

      expect(
        viewModel.state,
        isA<FailureState>().having((s) => s.error, "error", S.current.auth_store_pin_unreadable),
      );
    });

    test("a wrong PIN still reports the incorrect-PIN message", () async {
      when(() => authService.authenticate(any())).thenAnswer((_) async => false);

      await viewModel.auth(password: "0000");

      expect(
        viewModel.state,
        isA<FailureState>()
            .having((s) => s.error, "error", S.current.auth_store_incorrect_password),
      );
    });
  });

  group("keychainSecretsMissing", () {
    const notFound = -25300;
    const mainKey = "MONERO_WALLET_PASSWORD_MAIN";
    const savingsKey = "MONERO_WALLET_PASSWORD_SAVINGS";

    Future<bool> check(
      Map<String, int?> statuses, {
      Iterable<String> wallets = const ["Main", "Savings"],
    }) =>
        keychainSecretsMissing(
          readStatus: (key) async => statuses[key],
          walletNames: () async => wallets,
        );

    test("true only when the PIN and every wallet password are not found", () async {
      expect(
        await check({_pinKey: notFound, mainKey: notFound, savingsKey: notFound}),
        isTrue,
      );
    });

    test("false while any wallet password is still on the device", () async {
      expect(await check({_pinKey: notFound, mainKey: notFound, savingsKey: 0}), isFalse);
    });

    test("false when the PIN exists, is locked, or has no status (non-iOS)", () async {
      for (final status in [0, -25308, null]) {
        expect(
          await check({_pinKey: status, mainKey: notFound, savingsKey: notFound}),
          isFalse,
        );
      }
    });

    test("false when there are no wallets", () async {
      expect(await check({_pinKey: notFound}, wallets: const []), isFalse);
    });

    test("only loads wallet names once the PIN is missing", () async {
      var loaded = false;
      await keychainSecretsMissing(
        readStatus: (_) async => 0,
        walletNames: () async {
          loaded = true;
          return const ["Main"];
        },
      );
      expect(loaded, isFalse);
    });
  });
}
