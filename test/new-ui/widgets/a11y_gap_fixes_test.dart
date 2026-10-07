import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/model/charts/util/chart_range.dart";
import "package:cake_wallet/new-ui/widgets/charts_page/range_selector.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/cards_view.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_address_type_selector.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_amount_modal.dart";
import "package:cake_wallet/src/screens/pin_code/pin_code_widget.dart";
import "package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart";
import "package:cake_wallet/src/screens/settings/widgets/settings_theme_choice.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/themes/theme_classes/black_theme.dart";
import "package:cake_wallet/themes/theme_classes/dark_theme.dart";
import "package:cake_wallet/view_model/dashboard/balance_view_model.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/dashboard/receive_option_view_model.dart";
import "package:cake_wallet/view_model/settings/choices_list_item.dart";
import "package:cake_wallet/view_model/settings/display_settings_view_model.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableList, ObservableMap;
import "package:mocktail/mocktail.dart";

import "../../utils/semantics_helpers.dart";

class _MockWalletAddressListViewModel extends Mock implements WalletAddressListViewModel {}

class _MockDashboardViewModel extends Mock implements DashboardViewModel {}

class _MockBalanceViewModel extends Mock implements BalanceViewModel {}

class _MockAppStore extends Mock implements AppStore {}

class _MockReceiveOptionViewModel extends Mock implements ReceiveOptionViewModel {}

class _MockDisplaySettingsViewModel extends Mock implements DisplaySettingsViewModel {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

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

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  SemanticsNode one(WidgetTester tester, String id) {
    final nodes = platformNodesWithId(tester, id);
    expect(nodes, hasLength(1), reason: "exactly one platform node should carry '$id'");
    return nodes.single;
  }

  Future<void> pumpReceiveAmountModal(WidgetTester tester) async {
    final viewModel = _MockWalletAddressListViewModel();
    when(() => viewModel.selectedCurrency).thenReturn(CryptoCurrency.btc);
    when(() => viewModel.displayAmount).thenReturn("");
    when(() => viewModel.hasTokensList).thenReturn(false);
    when(() => viewModel.selectedCurrencyDecimals).thenReturn(8);
    when(() => viewModel.useSatoshi).thenReturn(false);
    when(() => viewModel.selectedCurrencySymbol).thenReturn("BTC");
    await tester.pumpWidget(
      wrap(ReceiveAmountModal(walletAddressListViewModel: viewModel, onSubmitted: (_) {})),
    );
  }

  group("receive amount modal", () {
    testWidgets("field, title and continue button are distinct identified nodes", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpReceiveAmountModal(tester);

      expect(
        one(tester, "receive_amount_modal_amount_textfield_key"),
        isSemantics(isTextField: true, hasTapAction: true),
      );
      expect(
        one(tester, "receive_amount_modal_title_key"),
        isSemantics(label: "Set amount", isHeader: true),
      );
      expect(
        one(tester, "receive_amount_modal_continue_button_key"),
        isSemantics(label: "Continue", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });

  group("amount semantics label", () {
    testWidgets("the Set amount field label has no doubled colon", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpReceiveAmountModal(tester);

      final label = one(tester, "receive_amount_modal_amount_textfield_key").label;
      expect(label, startsWith("Amount\n"));
      expect(label, isNot(contains(":")));
      handle.dispose();
    });
  });

  group("PIN pad", () {
    testWidgets("progress is a live region that never exposes the PIN", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          PinCodeWidget(
            key: const ValueKey("pin_code_widget"),
            onFullPin: (_, __) {},
            initialPinLength: 4,
            onChangedPin: (_) {},
            hasLengthSwitcher: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(one(tester, "pin_code_progress_key"), isSemantics(label: "0 of 4 digits entered"));
      await tester.tap(find.byKey(const ValueKey("pin_code_button_7_key")));
      await tester.tap(find.byKey(const ValueKey("pin_code_button_3_key")));
      await tester.pump();

      final progress = one(tester, "pin_code_progress_key");
      expect(progress, isSemantics(label: "2 of 4 digits entered", isLiveRegion: true));
      expect(progress.value, isEmpty);
      expect(
        find.semantics.byPredicate((node) => "${node.label}${node.value}".contains("73")),
        findsNothing,
      );
      expect(one(tester, "pin_code_button_7_key"), isSemantics(label: "7", isButton: true));
      expect(one(tester, "pin_code_button_0_key"), isSemantics(label: "0", isButton: true));
      expect(
        one(tester, "pin_code_delete_button_key"),
        isSemantics(label: "Delete", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });

  Future<void> pumpCardsView(WidgetTester tester) async {
    final dashboard = _MockDashboardViewModel();
    final balance = _MockBalanceViewModel();
    final appStore = _MockAppStore();
    final settingsStore = _MockSettingsStore();
    final wallet = _MockWallet();
    when(() => dashboard.cardOrder).thenReturn(ObservableMap<int, int>());
    when(() => dashboard.cardDesigns).thenReturn(
      ObservableList.of([CardDesign.genericDefault, CardDesign.genericDefault]),
    );
    when(() => dashboard.wallet).thenReturn(wallet);
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => wallet.currency).thenReturn(CryptoCurrency.xmr);
    when(() => dashboard.balanceViewModel).thenReturn(balance);
    when(() => balance.displayMode).thenReturn(BalanceDisplayMode.displayableBalance);
    when(() => balance.getMainBalanceRecord(any())).thenReturn(null);
    when(() => balance.showCombinedBalance).thenReturn(false);
    when(() => dashboard.mwebEnabled).thenReturn(false);
    when(() => dashboard.hasMweb).thenReturn(false);
    when(() => dashboard.isEnabledTradeAction).thenReturn(false);
    when(() => dashboard.settingsStore).thenReturn(settingsStore);
    when(() => settingsStore.fiatCurrency).thenReturn(FiatCurrency.usd);
    when(() => dashboard.appStore).thenReturn(appStore);
    when(() => appStore.amountParsingProxy)
        .thenReturn(const AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin));
    await tester.pumpWidget(
      wrap(
        CardsView(
          dashboardViewModel: dashboard,
          accountListViewModel: null,
          lightningMode: false,
          onCompactModeBackgroundCardsTapped: () {},
          onCustomizeTapped: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group("balance cards", () {
    testWidgets("the home card is a container whose balances stay separate nodes", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCardsView(tester);

      final card = one(tester, "home_page_balance_card_0_key");
      expect(card, isSemantics(label: "Balance", isButton: true, hasTapAction: true));
      expect(card.mergeAllDescendantsIntoThisNode, isFalse);
      final childLabels = <String>[];
      card.visitChildren((child) {
        childLabels.add(child.label);
        return true;
      });
      expect(childLabels, contains("Menu"));
      expect(childLabels.join(), allOf(contains("XMR"), contains("0.00")));
      handle.dispose();
    });

    testWidgets("the selected card's balance lines are identified nodes", (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCardsView(tester);

      expect(one(tester, "balance_card_crypto_balance_key"), isSemantics(label: "0\nXMR"));
      expect(one(tester, "balance_card_fiat_balance_key"), isSemantics(label: "0.00"));
      handle.dispose();
    });

    testWidgets("an unselected card still hides its crypto balance", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          const BalanceCard(
            width: 300,
            design: CardDesign.genericDefault,
            balance: "1.5",
            assetName: "BTC",
            fiatBalance: "USD 90,000.00",
          ),
        ),
      );

      expect(platformNodesWithId(tester, "balance_card_crypto_balance_key"), isEmpty);
      expect(find.bySemanticsLabel(RegExp("1.5")), findsNothing);
      expect(one(tester, "balance_card_fiat_balance_key"), isSemantics(label: "USD 90,000.00"));
      handle.dispose();
    });
  });

  group("segmented controls", () {
    testWidgets("chart range options are selectable buttons in one group", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(ChartRangeSelector(selectedRange: ChartRange.oneDay, onRangeSelected: (_) {})),
      );

      for (final (index, range) in ChartRange.ranges.indexed) {
        expect(
          one(tester, "chart_range_${index}_key"),
          isSemantics(
            label: range.displayText,
            isButton: true,
            hasSelectedState: true,
            isSelected: range == ChartRange.oneDay,
            isInMutuallyExclusiveGroup: true,
            hasTapAction: true,
          ),
        );
      }
      handle.dispose();
    });

    testWidgets("lightning switch carries its id on the toggle node", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(LightningSwitcher(lightningMode: true, onLightningSwitchPress: () {})),
      );
      expect(
        one(tester, "home_page_lightning_switch_key"),
        isSemantics(
          label: "Lightning mode",
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets("address type rows carry an index-based id", (tester) async {
      final handle = tester.ensureSemantics();
      final viewModel = _MockReceiveOptionViewModel();
      when(() => viewModel.options)
          .thenReturn([ReceivePageOption.mainnet, ReceivePageOption.testnet]);
      when(() => viewModel.walletTypeString).thenReturn("Monero");
      await tester.pumpWidget(
        wrap(
          ReceiveAddressTypeRow(
            option: ReceivePageOption.testnet,
            roundedTop: true,
            roundedBottom: true,
            selected: true,
            onItemTap: () {},
            receiveOptionViewModel: viewModel,
          ),
        ),
      );
      expect(
        one(tester, "receive_address_type_1_key"),
        isSemantics(
          label: "testnet",
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    for (final testId in [null, "display_settings_mode"]) {
      testWidgets("SettingsChoicesCell options expose selection (testId: $testId)", (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          wrap(
            SettingsChoicesCell(
              ChoicesListItem<String>(title: "", selectedItem: "B", items: ["A", "B"]),
              testId: testId,
            ),
          ),
        );
        expect(
          tester.getSemantics(find.text("A")),
          isSemantics(label: "A", isButton: true, hasSelectedState: true, isSelected: false),
        );
        expect(
          tester.getSemantics(find.text("B")),
          isSemantics(
            label: "B",
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            isInMutuallyExclusiveGroup: true,
            hasTapAction: true,
          ),
        );
        if (testId != null) {
          expect(one(tester, "display_settings_mode_1_key"), isSemantics(label: "B"));
        }
        handle.dispose();
      });
    }
  });

  group("theme choice", () {
    testWidgets("options are labelled by title and identified by family", (tester) async {
      final handle = tester.ensureSemantics();
      final dark = DarkTheme();
      final black = BlackTheme(BlackThemeAccentColor.cakePrimary);
      final viewModel = _MockDisplaySettingsViewModel();
      when(() => viewModel.availableThemes).thenReturn([dark, black]);
      when(() => viewModel.currentTheme).thenReturn(dark);
      when(() => viewModel.availableAccentColors).thenReturn([]);
      when(() => viewModel.isThemeSelected(dark)).thenReturn(true);
      when(() => viewModel.isThemeSelected(black)).thenReturn(false);
      for (final theme in [dark, black]) {
        when(() => viewModel.getImageForTheme(theme)).thenReturn("assets/new-ui/dark.svg");
      }
      tester.view.physicalSize = const Size(1170, 2700);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrap(SettingsThemeChoicesCell(viewModel)));

      expect(
        one(tester, "display_settings_theme_dark_key"),
        isSemantics(label: "Dark Theme", isSelected: true, hasTapAction: true),
      );
      expect(
        one(tester, "display_settings_theme_blacktheme_key"),
        isSemantics(label: "Black Theme (Cake Primary)", isSelected: false),
      );
      expect(find.bySemanticsLabel(RegExp("Instance of")), findsNothing);
      handle.dispose();
    });
  });

  group("alert actions", () {
    testWidgets("one- and two-action alerts expose button nodes", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          AlertWithOneAction(
            alertTitle: "Title",
            alertContent: "Content",
            buttonText: "OK",
            buttonAction: () {},
          ),
        ),
      );
      expect(
        one(tester, "alert_dialog_action_button_key"),
        isSemantics(label: "OK", isButton: true, hasTapAction: true),
      );

      await tester.pumpWidget(
        wrap(
          AlertWithTwoActions(
            alertTitle: "Title",
            alertContent: "Content",
            leftButtonText: "Cancel",
            rightButtonText: "Confirm",
            actionLeftButton: () {},
            actionRightButton: () {},
          ),
        ),
      );
      expect(
        one(tester, "alert_dialog_left_button_key"),
        isSemantics(label: "Cancel", isButton: true, hasTapAction: true),
      );
      expect(
        one(tester, "alert_dialog_right_button_key"),
        isSemantics(label: "Confirm", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });
}
