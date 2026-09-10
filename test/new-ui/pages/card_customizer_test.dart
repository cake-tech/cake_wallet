import "dart:async";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/pages/card_customizer.dart";
import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cw_core/card_design.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockCardCustomizerBloc extends Mock implements CardCustomizerBloc {}

class _RouteTracker {
  bool completed = false;
  bool? result;
}

CardCustomizerState _accountState(String accountName) => CardCustomizerInitial(
      0,
      0,
      const <CardDesign>[CardDesign.gradientOnlyDesign],
      const <Gradient>[CardDesign.gradientBlue],
      accountName,
      0,
      false,
      0,
    );

Future<_RouteTracker> _openCustomizer(
  WidgetTester tester,
  CardCustomizerBloc bloc, {
  Future<bool> Function()? onArchive,
}) async {
  final tracker = _RouteTracker();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: localizationDelegates,
      supportedLocales: S.delegate.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push<bool>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider<CardCustomizerBloc>.value(
                    value: bloc,
                    child: Material(
                      child: CardCustomizer(
                        cryptoTitle: "Monero",
                        cryptoName: "xmr",
                        accountNumber: 1,
                        balance: "1.25",
                        fiatBalance: "USD 2.50",
                        onArchive: onArchive,
                      ),
                    ),
                  ),
                ),
              )
                  .then((result) {
                tracker
                  ..completed = true
                  ..result = result;
              });
            },
            child: const Text("Open card customizer"),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text("Open card customizer"));
  await tester.pumpAndSettle();
  return tracker;
}

void main() {
  late _MockCardCustomizerBloc bloc;
  late StreamController<CardCustomizerState> stateController;

  setUp(() {
    bloc = _MockCardCustomizerBloc();
    stateController = StreamController<CardCustomizerState>.broadcast();
    when(() => bloc.stream).thenAnswer((_) => stateController.stream);
    when(() => bloc.canHide).thenReturn(true);
  });

  tearDown(() async {
    await stateController.close();
  });

  testWidgets("account mode renders the Figma edit and archive controls", (tester) async {
    when(() => bloc.state).thenReturn(_accountState(""));
    final tracker = await _openCustomizer(
      tester,
      bloc,
      onArchive: () async => false,
    );

    expect(find.text("Edit Account"), findsOneWidget);
    expect(find.text("#1"), findsOneWidget);
    expect(find.text("Unnamed Account"), findsOneWidget);
    expect(find.text("1.25"), findsOneWidget);
    expect(find.text("USD 2.50"), findsOneWidget);
    expect(find.text("Account name"), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("Archive Account"), findsOneWidget);
    expect(find.text("This change can be reverted"), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(BalanceCard).first).dy,
      lessThan(tester.getTopLeft(find.text("Account name")).dy),
    );

    await tester.ensureVisible(find.text("Archive Account"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Archive Account"));
    await tester.pumpAndSettle();

    expect(find.byType(CardCustomizer), findsOneWidget);
    expect(tracker.completed, isFalse);
  });

  testWidgets("confirmed archive request returns true to the parent adapter", (tester) async {
    when(() => bloc.state).thenReturn(_accountState("Savings"));
    final tracker = await _openCustomizer(
      tester,
      bloc,
      onArchive: () async => true,
    );

    await tester.ensureVisible(find.text("Archive Account"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Archive Account"));
    await tester.pumpAndSettle();

    expect(find.byType(CardCustomizer), findsNothing);
    expect(tracker.completed, isTrue);
    expect(tracker.result, isTrue);
  });

  testWidgets("account editing remains available when archival is unsupported", (tester) async {
    when(() => bloc.state).thenReturn(_accountState("Wownero Savings"));
    when(() => bloc.canHide).thenReturn(false);

    await _openCustomizer(tester, bloc);

    expect(find.text("Edit Account"), findsOneWidget);
    expect(find.text("Account name"), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("Wownero Savings"), findsWidgets);
    expect(find.text("Archive Account"), findsNothing);
  });
}
