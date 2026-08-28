import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/sync_status_display_mode.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/sync_status.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show Observable;
import "package:mocktail/mocktail.dart";

class _ObservableDashboardViewModel extends Mock implements DashboardViewModel {
  _ObservableDashboardViewModel(SyncStatus status) : _status = Observable(status);

  final Observable<SyncStatus> _status;

  @override
  SyncStatus get status => _status.value;
}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _UnknownSyncStatus extends SyncStatus {
  const _UnknownSyncStatus();

  @override
  double progress() => 0;
}

const _progressStatusTypes = <Type>[
  SyncingSyncStatus,
  NotConnectedSyncStatus,
  SyncronizingSyncStatus,
  AttemptingSyncStatus,
  StartingScanSyncStatus,
  AttemptingScanSyncStatus,
  SyncedTipSyncStatus,
  ProcessingSyncStatus,
  ConnectingSyncStatus,
  ConnectedSyncStatus,
];

const _failureStatusTypes = <Type>[
  FailedSyncStatus,
  LostConnectionSyncStatus,
  TimedOutSyncStatus,
  UnsupportedSyncStatus,
];

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

  group("SyncBar.replacesWalletNameForStatus", () {
    test("replaces the wallet name for every progress status in light and heavy wallets", () {
      for (final statusType in _progressStatusTypes) {
        for (final isSyncHeavy in [false, true]) {
          expect(
            SyncBar.replacesWalletNameForStatus(
              statusType,
              isSyncHeavy: isSyncHeavy,
              showSyncedMessage: false,
            ),
            isTrue,
            reason: "$statusType should replace the wallet name",
          );
        }
      }
    });

    test("replaces the wallet name for every failure status in light and heavy wallets", () {
      for (final statusType in _failureStatusTypes) {
        for (final isSyncHeavy in [false, true]) {
          expect(
            SyncBar.replacesWalletNameForStatus(
              statusType,
              isSyncHeavy: isSyncHeavy,
              showSyncedMessage: false,
            ),
            isTrue,
            reason: "$statusType should replace the wallet name",
          );
        }
      }
    });

    test("replaces the wallet name for the transient synced message in all wallets", () {
      for (final isSyncHeavy in [false, true]) {
        expect(
          SyncBar.replacesWalletNameForStatus(
            SyncedSyncStatus,
            isSyncHeavy: isSyncHeavy,
            showSyncedMessage: true,
          ),
          isTrue,
        );
      }
    });

    test("does not replace the wallet name once the synced message expires in any wallet", () {
      for (final isSyncHeavy in [false, true]) {
        expect(
          SyncBar.replacesWalletNameForStatus(
            SyncedSyncStatus,
            isSyncHeavy: isSyncHeavy,
            showSyncedMessage: false,
          ),
          isFalse,
        );
      }
    });

    test("unknown statuses replace the name only for sync-heavy wallets", () {
      expect(
        SyncBar.replacesWalletNameForStatus(
          _UnknownSyncStatus,
          isSyncHeavy: true,
          showSyncedMessage: false,
        ),
        isTrue,
      );
      expect(
        SyncBar.replacesWalletNameForStatus(
          _UnknownSyncStatus,
          isSyncHeavy: false,
          showSyncedMessage: false,
        ),
        isFalse,
      );
    });
  });

  testWidgets("unknown sync-heavy statuses render a localized fallback", (tester) async {
    const status = _UnknownSyncStatus();
    final dashboardViewModel = _ObservableDashboardViewModel(status);
    final settingsStore = _MockSettingsStore();

    when(() => dashboardViewModel.settingsStore).thenReturn(settingsStore);
    when(() => dashboardViewModel.isTorEnabled).thenReturn(false);
    when(() => dashboardViewModel.hasMweb).thenReturn(false);
    when(() => dashboardViewModel.hasSilentPayments).thenReturn(false);
    when(() => settingsStore.syncStatusDisplayMode)
        .thenReturn(SyncStatusDisplayMode.blocksRemaining);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: SyncBar(
            dashboardViewModel: dashboardViewModel,
            isSyncHeavy: true,
            showSyncedMessage: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(S.current.synchronizing), findsOneWidget);
    expect(find.bySemanticsLabel(S.current.synchronizing), findsOneWidget);
  });

  testWidgets("active Silent Payments syncing shows integer progress in the 210 by 40 pill",
      (tester) async {
    final dashboardViewModel = _ObservableDashboardViewModel(SyncingSyncStatus(100, 0.24));
    final settingsStore = _MockSettingsStore();

    when(() => dashboardViewModel.settingsStore).thenReturn(settingsStore);
    when(() => dashboardViewModel.isTorEnabled).thenReturn(false);
    when(() => dashboardViewModel.hasMweb).thenReturn(false);
    when(() => dashboardViewModel.hasSilentPayments).thenReturn(true);
    when(() => dashboardViewModel.silentPaymentsScanningActive).thenReturn(true);
    when(() => settingsStore.syncStatusDisplayMode)
        .thenReturn(SyncStatusDisplayMode.blocksRemaining);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 210,
              height: 36,
              child: SyncBar(
                dashboardViewModel: dashboardViewModel,
                isSyncHeavy: true,
                showSyncedMessage: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final progressText = tester.widget<Text>(find.text("24%"));
    final pill = find.descendant(
      of: find.byType(SyncBar),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.minHeight == 40 &&
            widget.constraints?.maxHeight == 40,
      ),
    );
    final silentPaymentsIcon = tester.widget<CakeImageWidget>(
      find.byWidgetPredicate(
        (widget) => widget is CakeImageWidget && widget.imageUrl == "assets/new-ui/silent_sync.svg",
      ),
    );

    final warningOutlineColor = getIt<ThemeStore>().currentTheme.customColors.warningOutlineColor;

    expect(progressText.style?.color, warningOutlineColor);
    expect(find.text("·"), findsOneWidget);
    expect(find.text(S.current.Blocks_remaining("100")), findsOneWidget);
    expect(tester.getSize(pill), const Size(210, 40));
    expect(Size(silentPaymentsIcon.width!, silentPaymentsIcon.height!), const Size(16, 16));
    expect(
      silentPaymentsIcon.colorFilter,
      ColorFilter.mode(warningOutlineColor, BlendMode.srcIn),
    );
    expect(tester.getSemantics(find.text("24%")).value, "24%");
  });

  testWidgets("Silent Payments progress requires support, active scanning, and syncing",
      (tester) async {
    final testCases = <({bool hasSilentPayments, bool scanningActive, SyncStatus status})>[
      (
        hasSilentPayments: false,
        scanningActive: true,
        status: SyncingSyncStatus(100, 0.24),
      ),
      (
        hasSilentPayments: true,
        scanningActive: false,
        status: SyncingSyncStatus(100, 0.24),
      ),
      (
        hasSilentPayments: true,
        scanningActive: true,
        status: AttemptingScanSyncStatus(),
      ),
    ];

    for (final testCase in testCases) {
      final dashboardViewModel = _ObservableDashboardViewModel(testCase.status);
      final settingsStore = _MockSettingsStore();

      when(() => dashboardViewModel.settingsStore).thenReturn(settingsStore);
      when(() => dashboardViewModel.isTorEnabled).thenReturn(false);
      when(() => dashboardViewModel.hasMweb).thenReturn(false);
      when(() => dashboardViewModel.hasSilentPayments).thenReturn(testCase.hasSilentPayments);
      when(() => dashboardViewModel.silentPaymentsScanningActive)
          .thenReturn(testCase.scanningActive);
      when(() => settingsStore.syncStatusDisplayMode)
          .thenReturn(SyncStatusDisplayMode.blocksRemaining);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: SyncBar(
              dashboardViewModel: dashboardViewModel,
              isSyncHeavy: true,
              showSyncedMessage: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text("24%"), findsNothing, reason: "$testCase");
      expect(find.text("0%"), findsNothing, reason: "$testCase");
      expect(find.text("·"), findsNothing, reason: "$testCase");
    }
  });
}
