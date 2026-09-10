import "dart:async";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/account_customizer.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockAccountEditOrCreateViewModel extends Mock
    implements MoneroAccountEditOrCreateViewModel {}

void main() {
  late _MockAccountEditOrCreateViewModel viewModel;
  bool? routeResult;

  setUp(() {
    viewModel = _MockAccountEditOrCreateViewModel();
    routeResult = null;
  });

  Widget creationLauncher() => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                routeResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: AccountCreationModal(
                        accountEditOrCreateViewModel: viewModel,
                      ),
                    ),
                  ),
                );
              },
              child: const Text("Open account creation"),
            ),
          ),
        ),
      );

  Future<void> openModal(WidgetTester tester) async {
    await tester.pumpWidget(creationLauncher());
    await tester.tap(find.text("Open account creation"));
    await tester.pumpAndSettle();
  }

  testWidgets("shows the Figma account-creation presentation", (tester) async {
    await openModal(tester);

    expect(find.text("Create Account"), findsOneWidget);
    expect(
      find.text(
        "Accounts let you organize your funds into different compartments without needing to create a separate wallet",
      ),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("Continue"), findsOneWidget);
    expect(find.bySemanticsLabel("Close"), findsOneWidget);
  });

  testWidgets("passes the entered name to the existing account save operation", (tester) async {
    when(() => viewModel.save()).thenAnswer((_) async {});
    when(() => viewModel.state).thenReturn(ExecutedSuccessfullyState());
    await openModal(tester);

    await tester.enterText(find.byType(TextField), "Savings");
    await tester.pump();
    await tester.tap(find.text("Continue"));
    await tester.pumpAndSettle();

    verify(() => viewModel.label = "Savings").called(1);
    verify(() => viewModel.save()).called(1);
    expect(routeResult, isTrue);
    expect(find.byType(AccountCreationModal), findsNothing);
  });

  testWidgets("cannot be dismissed while account creation is in progress", (tester) async {
    final saveCompleter = Completer<void>();
    when(() => viewModel.save()).thenAnswer((_) => saveCompleter.future);
    when(() => viewModel.state).thenReturn(ExecutedSuccessfullyState());
    await openModal(tester);

    await tester.enterText(find.byType(TextField), "Savings");
    await tester.pump();
    await tester.tap(find.text("Continue"));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel("Close"));
    await tester.pump();
    expect(find.byType(AccountCreationModal), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AccountCreationModal), findsOneWidget);

    saveCompleter.complete();
    await tester.pumpAndSettle();
    expect(routeResult, isTrue);
    expect(find.byType(AccountCreationModal), findsNothing);
  });

  testWidgets("shows a save failure and restores safe dismissal", (tester) async {
    when(() => viewModel.save()).thenAnswer((_) async {});
    when(() => viewModel.state).thenReturn(FailureState("Could not create account"));
    await openModal(tester);

    await tester.enterText(find.byType(TextField), "Savings");
    await tester.pump();
    await tester.tap(find.text("Continue"));
    await tester.pumpAndSettle();

    expect(find.text("Could not create account"), findsOneWidget);
    expect(find.byType(AccountCreationModal), findsOneWidget);
    expect(routeResult, isNull);

    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel("Close"));
    await tester.pumpAndSettle();

    verify(() => viewModel.save()).called(1);
    expect(find.byType(AccountCreationModal), findsNothing);
    expect(routeResult, isNull);
  });

  testWidgets("shows a thrown save error and restores safe dismissal", (tester) async {
    when(() => viewModel.save()).thenThrow(Exception("Card design failed"));
    await openModal(tester);

    await tester.enterText(find.byType(TextField), "Savings");
    await tester.pump();
    await tester.tap(find.text("Continue"));
    await tester.pumpAndSettle();

    expect(find.text("Exception: Card design failed"), findsOneWidget);
    expect(find.byType(AccountCreationModal), findsOneWidget);
    expect(routeResult, isNull);

    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel("Close"));
    await tester.pumpAndSettle();

    verify(() => viewModel.save()).called(1);
    expect(find.byType(AccountCreationModal), findsNothing);
    expect(routeResult, isNull);
  });

  testWidgets("requires a non-empty account name before continuing", (tester) async {
    await openModal(tester);

    TextButton continueButton() => tester.widget<TextButton>(
          find.ancestor(
            of: find.text("Continue"),
            matching: find.byType(TextButton),
          ),
        );

    expect(continueButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), "   ");
    await tester.pump();
    expect(continueButton().onPressed, isNull);
    verifyNever(() => viewModel.save());

    await tester.enterText(find.byType(TextField), "Savings");
    await tester.pump();
    expect(continueButton().onPressed, isNotNull);
  });
}
