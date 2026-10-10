import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/src/screens/seed/seed_verification/seed_verification_step_view.dart";
import "package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/themes/core/theme_store.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_list_item.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart";
import "package:cake_wallet/view_model/wallet_seed_view_model.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show ObservableList;
import "package:mocktail/mocktail.dart";

import "../../utils/semantics_helpers.dart";

class _MockWalletListViewModel extends Mock implements WalletListViewModel {}

class _MockWalletSeedViewModel extends Mock implements WalletSeedViewModel {}

class _MockAuthService extends Mock implements AuthService {}

List<String> _allIdentifiers(WidgetTester tester) {
  final ids = <String>[];

  void visit(SemanticsNode node) {
    final id = node.getSemanticsData().identifier;
    if (id.isNotEmpty) {
      ids.add(id);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return ids;
}

void main() {
  late bool registeredThemeStore;

  setUpAll(() async {
    await S.delegate.load(const Locale("en"));
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
        home: Scaffold(body: child),
      );

  testWidgets("wallet list rows use index ids and never the wallet name", (tester) async {
    final handle = tester.ensureSemantics();
    final viewModel = _MockWalletListViewModel();
    when(() => viewModel.multiWalletGroups).thenReturn(ObservableList());
    when(() => viewModel.singleWalletsList).thenReturn(
      ObservableList.of(const [
        WalletListItem(name: "Alice Savings", type: WalletType.bitcoin, key: 0, isHardware: false, isCurrent: true),
        WalletListItem(name: "Bob Spending", type: WalletType.litecoin, key: 1, isHardware: false),
      ]),
    );

    await tester.pumpWidget(
      wrap(
        WalletListBody(
          walletListViewModel: viewModel,
          authService: _MockAuthService(),
          onWalletLoaded: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(platformNodesWithId(tester, "wallet_list_single_wallet_0_key").single, isSemantics(label: "Alice Savings"));
    expect(
      platformNodesWithId(tester, "wallet_list_single_wallet_1_key").single,
      isSemantics(label: "Bob Spending", hasTapAction: true),
    );
    expect(
      platformNodesWithId(tester, "wallet_list_single_wallet_1_edit_button_key").single,
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(find.byKey(const ValueKey("wallet_list_single_wallet_1_edit_button_key")), findsOneWidget);
    expect(_allIdentifiers(tester).where((id) => id.contains("alice") || id.contains("bob")), isEmpty);
    handle.dispose();
  });

  testWidgets("seed verification options use index ids and never the seed word", (tester) async {
    final handle = tester.ensureSemantics();
    const words = ["abandon", "zebra", "orbit", "lunar"];
    final viewModel = _MockWalletSeedViewModel();
    when(() => viewModel.currentOptions).thenReturn(ObservableList.of(words));
    when(() => viewModel.currentWordIndex).thenReturn(2);

    await tester.pumpWidget(
      wrap(SeedVerificationStepView(walletSeedViewModel: viewModel, questionTextColor: Colors.black)),
    );

    for (final (index, word) in words.indexed) {
      expect(
        platformNodesWithId(tester, "seed_verification_option_${index}_button_key").single,
        isSemantics(label: word, hasTapAction: true),
      );
    }
    expect(_allIdentifiers(tester).where((id) => words.any(id.contains)), isEmpty);
    handle.dispose();
  });

  testWidgets("an alert's own key lands on exactly one widget", (tester) async {
    const oneKey = ValueKey("one_action_dialog_key");
    await tester.pumpWidget(
      wrap(AlertWithOneAction(key: oneKey, alertTitle: "T", alertContent: "C", buttonText: "OK", buttonAction: () {})),
    );
    expect(find.byKey(oneKey), findsOneWidget);

    const twoKey = ValueKey("two_actions_dialog_key");
    await tester.pumpWidget(
      wrap(
        AlertWithTwoActions(
          alertDialogKey: twoKey,
          alertTitle: "T",
          alertContent: "C",
          leftButtonText: "No",
          rightButtonText: "Yes",
          actionLeftButton: () {},
          actionRightButton: () {},
        ),
      ),
    );
    expect(find.byKey(twoKey), findsOneWidget);
  });
}
