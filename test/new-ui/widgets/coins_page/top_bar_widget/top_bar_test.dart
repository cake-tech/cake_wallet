import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/sync_status_display_mode.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/top_bar.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show Observable, runInAction;
import "package:mocktail/mocktail.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _ObservableDashboardViewModel extends Mock implements DashboardViewModel {
  _ObservableDashboardViewModel(SyncStatus initialStatus)
      : _status = Observable<SyncStatus>(initialStatus);

  final Observable<SyncStatus> _status;

  @override
  SyncStatus get status => _status.value;

  void setStatus(SyncStatus status) => runInAction(() => _status.value = status);
}

class _MockSettingsStore extends Mock implements SettingsStore {}

void _stubDashboardViewModel(
  _ObservableDashboardViewModel dashboardViewModel,
  _MockWallet wallet,
  String walletName, {
  bool hasLightning = true,
  bool isSyncHeavy = false,
  bool hasSilentPayments = false,
  bool silentPaymentsScanningActive = false,
}) {
  when(() => dashboardViewModel.hasLightning).thenReturn(hasLightning);
  when(() => dashboardViewModel.isSyncHeavy).thenReturn(isSyncHeavy);
  when(() => dashboardViewModel.isTorEnabled).thenReturn(false);
  when(() => dashboardViewModel.hasMweb).thenReturn(false);
  when(() => dashboardViewModel.hasSilentPayments).thenReturn(hasSilentPayments);
  when(() => dashboardViewModel.silentPaymentsScanningActive)
      .thenReturn(silentPaymentsScanningActive);
  when(() => dashboardViewModel.wallet).thenReturn(wallet);
  when(() => wallet.name).thenReturn(walletName);
  when(() => wallet.hardwareWalletType).thenReturn(null);
}

Widget _buildTopBar(DashboardViewModel dashboardViewModel) => TopBar(
      lightningMode: false,
      onLightningSwitchPress: () {},
      dashboardViewModel: dashboardViewModel,
      onSettingsButtonPress: () {},
    );

Widget _buildTestApp(Widget child) => MaterialApp(
      localizationsDelegates: localizationDelegates,
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  late bool registeredThemeStore;

  setUpAll(() {
    registeredThemeStore = !getIt.isRegistered<ThemeStore>();
    if (registeredThemeStore) {
      getIt.registerSingleton(ThemeStore());
    }
  });

  tearDownAll(() async {
    if (registeredThemeStore) {
      await getIt.unregister<ThemeStore>();
    }
  });

  testWidgets("light sync keeps the wallet name hidden for the three-second Synced message",
      (tester) async {
    const walletName = "My Bitcoin Wallet";
    final wallet = _MockWallet();
    final dashboardViewModel = _ObservableDashboardViewModel(SyncingSyncStatus(100, 0.5));

    _stubDashboardViewModel(dashboardViewModel, wallet, walletName);

    await tester.pumpWidget(_buildTestApp(_buildTopBar(dashboardViewModel)));
    await tester.pump();

    expect(find.text(walletName), findsNothing);
    expect(find.byType(SyncBar), findsOneWidget);

    dashboardViewModel.setStatus(SyncedSyncStatus());
    await tester.pump();

    expect(find.text(walletName), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.widget<SyncBar>(find.byType(SyncBar)).showSyncedMessage, isTrue);

    await tester.pump(const Duration(seconds: 3) - const Duration(milliseconds: 1));

    expect(find.text(walletName), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text(walletName), findsOneWidget);
    expect(find.byType(SyncBar), findsNothing);
  });

  testWidgets("rebinds to a replacement view model and cancels its stale Synced timer",
      (tester) async {
    const firstWalletName = "First Wallet";
    const secondWalletName = "Second Wallet";
    final firstWallet = _MockWallet();
    final secondWallet = _MockWallet();
    final firstViewModel = _ObservableDashboardViewModel(SyncingSyncStatus(100, 0.5));
    final secondViewModel = _ObservableDashboardViewModel(SyncingSyncStatus(100, 0.5));
    DashboardViewModel activeViewModel = firstViewModel;
    late StateSetter setHarnessState;

    _stubDashboardViewModel(firstViewModel, firstWallet, firstWalletName);
    _stubDashboardViewModel(secondViewModel, secondWallet, secondWalletName);

    await tester.pumpWidget(
      _buildTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            setHarnessState = setState;
            return _buildTopBar(activeViewModel);
          },
        ),
      ),
    );
    await tester.pump();

    firstViewModel.setStatus(SyncedSyncStatus());
    await tester.pump();
    expect(tester.widget<SyncBar>(find.byType(SyncBar)).showSyncedMessage, isTrue);

    await tester.pump(const Duration(seconds: 1));
    setHarnessState(() => activeViewModel = secondViewModel);
    await tester.pump();
    expect(tester.widget<SyncBar>(find.byType(SyncBar)).showSyncedMessage, isFalse);

    firstViewModel.setStatus(SyncingSyncStatus(50, 0.75));
    await tester.pump();
    firstViewModel.setStatus(SyncedSyncStatus());
    await tester.pump();
    expect(tester.widget<SyncBar>(find.byType(SyncBar)).showSyncedMessage, isFalse);

    secondViewModel.setStatus(SyncedSyncStatus());
    await tester.pump();
    expect(tester.widget<SyncBar>(find.byType(SyncBar)).showSyncedMessage, isTrue);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<SyncBar>(find.byType(SyncBar)).showSyncedMessage, isTrue);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text(secondWalletName), findsOneWidget);
    expect(find.byType(SyncBar), findsNothing);
  });

  testWidgets("cancels the Synced timer when disposed", (tester) async {
    final wallet = _MockWallet();
    final dashboardViewModel = _ObservableDashboardViewModel(SyncingSyncStatus(100, 0.5));

    _stubDashboardViewModel(dashboardViewModel, wallet, "Wallet");

    await tester.pumpWidget(_buildTestApp(_buildTopBar(dashboardViewModel)));
    await tester.pump();

    dashboardViewModel.setStatus(SyncedSyncStatus());
    await tester.pump();
    expect(tester.widget<SyncBar>(find.byType(SyncBar)).showSyncedMessage, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());

    // Flutter reports any timer that survives disposal as pending when this test ends.
    expect(tester.takeException(), isNull);
  });

  testWidgets("lays out the synced Bitcoin header to the Figma geometry", (tester) async {
    await tester.binding.setSurfaceSize(const Size(376, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final wallet = _MockWallet();
    final dashboardViewModel = _ObservableDashboardViewModel(SyncedSyncStatus());

    _stubDashboardViewModel(dashboardViewModel, wallet, "My Bitcoin Wallet");

    await tester.pumpWidget(
      _buildTestApp(
        Align(
          alignment: Alignment.topCenter,
          child: _buildTopBar(dashboardViewModel),
        ),
      ),
    );
    await tester.pump();

    final switcher = find.byType(LightningSwitcher);
    final walletInfo = find.byType(WalletInfoBar);
    final settingsButton = find.byType(ModernButton);
    final switcherIcons = find.descendant(
      of: switcher,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is CakeImageWidget &&
            widget.imageUrl?.startsWith("assets/new-ui/switcher-") == true,
      ),
    );

    expect(tester.getSize(switcher), const Size(63, 36));
    expect(switcherIcons, findsNWidgets(2));
    for (final icon in tester.widgetList<CakeImageWidget>(switcherIcons)) {
      expect(Size(icon.width!, icon.height!), const Size(27, 27));
    }
    expect(tester.getSize(walletInfo).width, 190);
    expect(tester.getRect(settingsButton).right, 358);
  });

  testWidgets("centers the 333-wide syncing group without growing its 36-high header slot",
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(376, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final wallet = _MockWallet();
    final settingsStore = _MockSettingsStore();
    final dashboardViewModel = _ObservableDashboardViewModel(SyncingSyncStatus(100, 0.24));

    _stubDashboardViewModel(
      dashboardViewModel,
      wallet,
      "My Bitcoin Wallet",
      isSyncHeavy: true,
      hasSilentPayments: true,
      silentPaymentsScanningActive: true,
    );
    when(() => dashboardViewModel.settingsStore).thenReturn(settingsStore);
    when(() => settingsStore.syncStatusDisplayMode)
        .thenReturn(SyncStatusDisplayMode.blocksRemaining);

    await tester.pumpWidget(
      _buildTestApp(
        Align(
          alignment: Alignment.topCenter,
          child: _buildTopBar(dashboardViewModel),
        ),
      ),
    );
    await tester.pump();

    final switcherRect = tester.getRect(find.byType(LightningSwitcher));
    final syncBarRect = tester.getRect(find.byType(SyncBar));
    final settingsRect = tester.getRect(find.byType(ModernButton));
    final pill = find.descendant(
      of: find.byType(SyncBar),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.minHeight == 40 &&
            widget.constraints?.maxHeight == 40,
      ),
    );
    final pillRect = tester.getRect(pill);

    expect(syncBarRect.size, const Size(210, 36));
    expect(pillRect.size, const Size(210, 40));
    expect(pillRect.left - switcherRect.right, closeTo(12, 0.001));
    expect(settingsRect.left - pillRect.right, closeTo(12, 0.001));
    expect(pillRect.center.dy, closeTo(syncBarRect.center.dy, 0.001));
    expect(settingsRect.right - switcherRect.left, closeTo(333, 0.001));
    expect((switcherRect.left + settingsRect.right) / 2, closeTo(188, 0.001));
  });

  testWidgets("keeps the non-Lightning header geometry unchanged", (tester) async {
    await tester.binding.setSurfaceSize(const Size(376, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final wallet = _MockWallet();
    final dashboardViewModel = _ObservableDashboardViewModel(SyncedSyncStatus());

    _stubDashboardViewModel(
      dashboardViewModel,
      wallet,
      "My Monero Wallet",
      hasLightning: false,
    );
    when(() => wallet.currency).thenReturn(CryptoCurrency.xmr);

    await tester.pumpWidget(
      _buildTestApp(
        Align(
          alignment: Alignment.topCenter,
          child: _buildTopBar(dashboardViewModel),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(WalletInfoBar)).width, 244);
  });
}
