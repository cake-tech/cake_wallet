import "dart:async";

import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/node_switching_service.dart";
import "package:cake_wallet/core/totp_request_details.dart";
import "package:cake_wallet/core/trade_monitor.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/biometric_auth.dart";
import "package:cake_wallet/entities/cake_2fa_preset_options.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/router.dart" as app_router;
import "package:cake_wallet/src/screens/auth/auth_page.dart";
import "package:cake_wallet/src/screens/root/root.dart";
import "package:cake_wallet/src/screens/setup_2fa/setup_2fa_enter_code_page.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_listener_widget.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_signing_request_sheet.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/authentication_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/auth_view_model.dart";
import "package:cake_wallet/view_model/link_view_model.dart";
import "package:cake_wallet/view_model/set_up_2fa_viewmodel.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:trezor_connect/trezor_connect.dart";

import "sheet_test_app.dart";

class _MockAuthService extends Mock implements AuthService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockThemeStore extends Mock implements ThemeStore {}

class _MockLinkViewModel extends Mock implements LinkViewModel {}

class _MockTradeMonitor extends Mock implements TradeMonitor {}

class _MockNodeSwitchingService extends Mock implements NodeSwitchingService {}

class _MockTrezorConnect extends Mock implements TrezorConnect {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}

class _MockBiometricAuth extends Mock implements BiometricAuth {}

const _signMessage = WCDecodedRequest(
  actionTitle: "Sign message",
  rows: [WCDecodedRow(label: "Message", value: "sign in to the lock test")],
);

void main() {
  late BottomSheetServiceImpl sheets;
  late _MockAuthService authService;
  late _MockSettingsStore settingsStore;
  late AuthViewModel authViewModel;
  late Setup2FAViewModel setup2FAViewModel;
  late bool isPinDue;

  setUpAll(() async {
    S.current = const S();
    await loadSheetFonts();
  });

  setUp(() {
    sheets = BottomSheetServiceImpl();
    authService = _MockAuthService();
    settingsStore = _MockSettingsStore();
    isPinDue = false;

    when(() => authService.requireAuth()).thenAnswer((_) async => isPinDue);
    when(() => authService.authenticate(any())).thenAnswer((_) async => true);
    when(() => settingsStore.pinCodeLength).thenReturn(4);
    when(() => settingsStore.allowBiometricalAuthentication).thenReturn(false);
    when(() => settingsStore.useTOTP2FA).thenReturn(false);
    when(() => settingsStore.shouldRequireTOTP2FAForAccessingWallet).thenReturn(false);
    when(() => settingsStore.selectedCake2FAPreset).thenReturn(Cake2FAPresetsOptions.none);

    final preferences = _MockSharedPreferences();
    authViewModel = AuthViewModel(authService, preferences, settingsStore, _MockBiometricAuth());
    setup2FAViewModel = Setup2FAViewModel(settingsStore, preferences, authService);

    getIt.registerFactoryParam<AuthPage, OnAuthenticationFinished, bool>(
      (onAuthenticationFinished, closable) => AuthPage(
        authViewModel,
        onAuthenticationFinished: onAuthenticationFinished,
        closable: closable,
      ),
    );
    getIt.registerFactoryParam<TotpAuthCodePage, TotpAuthArgumentsModel, void>(
      (arguments, _) => TotpAuthCodePage(setup2FAViewModel, totpArguments: arguments),
    );
  });

  tearDown(() async {
    await getIt.unregister<AuthPage>();
    await getIt.unregister<TotpAuthCodePage>();
  });

  Future<void> pumpFor(WidgetTester tester, Duration duration) async {
    const step = Duration(milliseconds: 50);
    for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
      await tester.pump(step);
    }
  }

  Future<void> pumpUnlockedApp(WidgetTester tester) async {
    setPhoneSize(tester, const Size(390, 844));
    final navigatorKey = GlobalKey<NavigatorState>();
    final appStore = _MockAppStore();
    final themeStore = _MockThemeStore();
    when(() => appStore.settingsStore).thenReturn(settingsStore);
    when(() => appStore.themeStore).thenReturn(themeStore);
    when(() => themeStore.themeMode).thenReturn(ThemeMode.dark);
    final nodeSwitchingService = _MockNodeSwitchingService();
    when(nodeSwitchingService.performHealthCheck).thenAnswer((_) async {});

    final rootKey = GlobalKey<RootState>();
    await tester.pumpWidget(
      Root(
        key: rootKey,
        authenticationStore: AuthenticationStore()..allowed(),
        appStore: appStore,
        navigatorKey: navigatorKey,
        authService: authService,
        linkViewModel: _MockLinkViewModel(),
        tradeMonitor: _MockTradeMonitor(),
        nodeSwitchingService: nodeSwitchingService,
        trezorConnect: _MockTrezorConnect(),
        quickActionsStream: const Stream.empty(),
        bottomSheetService: sheets,
        child: sheetTestApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: app_router.createRoute,
          home: BottomSheetListener(
            bottomSheetService: sheets,
            child: const Scaffold(body: Text("dashboard")),
          ),
        ),
      ),
    );
    await tester.pump();

    final root = rootKey.currentState!;
    addTearDown(() => WidgetsBinding.instance.removeObserver(root));
  }

  Future<void> background(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
  }

  Future<void> reopen(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await pumpFor(tester, const Duration(milliseconds: 500));
  }

  List<Object?> queueSigningRequest() {
    final answers = <Object?>[];
    unawaited(
      sheets
          .queueBottomSheet(
            widget: WCSigningRequestSheet(
              title: S.current.wc_signing_request_title,
              swipeLabel: S.current.wc_swipe_to_sign,
              dappName: "Lock test dApp",
              decoded: _signMessage,
              walletName: "EthTest",
              address: "0x52908400098527886E0F7030069857D2E4169EE7",
            ),
          )
          .then(answers.add),
    );

    return answers;
  }

  Future<void> enterPin(WidgetTester tester) async {
    for (var digit = 1; digit <= 4; digit++) {
      await tester.tap(find.byKey(ValueKey("pin_code_button_${digit}_key")));
      await tester.pump();
    }
    await pumpFor(tester, const Duration(seconds: 1));
  }

  Future<void> swipeToSign(WidgetTester tester) async {
    await tester.drag(find.text(S.current.wc_swipe_to_sign), const Offset(400, 0));
    await pumpFor(tester, const Duration(seconds: 1));
  }

  testWidgets("a request that arrives while the PIN page is up waits for the unlock", (
    tester,
  ) async {
    await pumpUnlockedApp(tester);
    await background(tester);
    isPinDue = true;
    await reopen(tester);
    expect(find.byType(AuthPage), findsOneWidget);

    final answers = queueSigningRequest();
    await pumpFor(tester, const Duration(seconds: 1));

    expect(find.byType(WCSigningRequestSheet), findsNothing);
    expect(find.text(S.current.wc_swipe_to_sign), findsNothing);
    expect(answers, isEmpty);

    await enterPin(tester);

    expect(find.byType(AuthPage), findsNothing);
    expect(find.byType(WCSigningRequestSheet), findsOneWidget);
    expect(answers, isEmpty, reason: "closing the PIN page must not pop the sheet");

    await swipeToSign(tester);
    expect(answers, [WCBottomSheetResult.one]);
  });

  testWidgets("a request that arrives in the background shows on reopen when no PIN is due", (
    tester,
  ) async {
    await pumpUnlockedApp(tester);
    await background(tester);

    final answers = queueSigningRequest();
    await pumpFor(tester, const Duration(seconds: 1));
    expect(sheets.currentSheet.value!.isPresented, isFalse);

    await reopen(tester);

    expect(find.byType(AuthPage), findsNothing);
    expect(find.byType(WCSigningRequestSheet), findsOneWidget);
    expect(answers, isEmpty);
  });

  testWidgets("with 2FA on, the request waits until the code page has closed", (tester) async {
    when(() => settingsStore.useTOTP2FA).thenReturn(true);
    when(() => settingsStore.shouldRequireTOTP2FAForAccessingWallet).thenReturn(true);
    await pumpUnlockedApp(tester);
    await background(tester);
    isPinDue = true;
    await reopen(tester);
    final answers = queueSigningRequest();

    await enterPin(tester);
    expect(find.byType(TotpAuthCodePage), findsOneWidget);
    expect(find.byType(WCSigningRequestSheet), findsNothing);

    isPinDue = false;
    await background(tester);
    await reopen(tester);
    expect(find.byType(TotpAuthCodePage), findsOneWidget);
    expect(find.byType(WCSigningRequestSheet), findsNothing);

    setup2FAViewModel.state = ExecutedSuccessfullyState();
    tester.binding.scheduleFrame();
    await pumpFor(tester, const Duration(seconds: 1));

    expect(find.byType(TotpAuthCodePage), findsNothing);
    expect(find.byType(WCSigningRequestSheet), findsOneWidget);
    expect(answers, isEmpty, reason: "closing the code page must not pop the sheet");
  });

  testWidgets("a PIN page removed without an unlock does not hold the queue for good", (
    tester,
  ) async {
    await pumpUnlockedApp(tester);
    await background(tester);
    isPinDue = true;
    await reopen(tester);
    final answers = queueSigningRequest();

    final navigator = Navigator.of(tester.element(find.byType(AuthPage)));
    unawaited(navigator.pushNamedAndRemoveUntil("/", (route) => false));
    await pumpFor(tester, const Duration(seconds: 1));
    expect(find.byType(AuthPage), findsNothing);
    expect(find.byType(WCSigningRequestSheet), findsNothing);

    isPinDue = false;
    await background(tester);
    await reopen(tester);

    expect(find.byType(WCSigningRequestSheet), findsOneWidget);
    expect(answers, isEmpty);
  });
}
