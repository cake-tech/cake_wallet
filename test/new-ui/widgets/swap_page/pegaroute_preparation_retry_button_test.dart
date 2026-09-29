import 'dart:async';

import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_preparation_retry.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/pegaroute_preparation_retry_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _page({
  required Future<PegaroutePreparationRetryAction?> Function() readAction,
  required Future<void> Function() onRetry,
}) =>
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [S.delegate],
      home: Scaffold(
        body: PegaroutePreparationRetryButton(readAction: readAction, onRetry: onRetry),
      ),
    );

void main() {
  for (final entry in {
    PegaroutePreparationRetryAction.retryPreparation: 'Retry preparation',
    PegaroutePreparationRetryAction.checkApproval: 'Check approval',
    PegaroutePreparationRetryAction.continuePreparation: 'Continue',
  }.entries) {
    testWidgets('${entry.value} is accessible and rechecks eligibility before preparation',
        (tester) async {
      final events = <String>[];
      await tester.pumpWidget(_page(
        readAction: () async {
          events.add('read');
          return entry.key;
        },
        onRetry: () async => events.add('prepare'),
      ));
      await tester.pumpAndSettle();
      expect(events, ['read']);
      expect(find.text(entry.value), findsOneWidget);
      await tester.tap(find.text(entry.value));
      await tester.pumpAndSettle();
      expect(events, ['read', 'read', 'prepare']);
    });
  }

  for (final unavailable in [false, true]) {
    testWidgets('no retry on ${unavailable ? 'unavailable evidence' : 'ineligible state'}',
        (tester) async {
      var preparations = 0;
      await tester.pumpWidget(_page(
        readAction: () async {
          if (unavailable) throw StateError('Database unavailable');
          return null;
        },
        onRetry: () async => preparations++,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(NewPrimaryButton), findsNothing);
      expect(preparations, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final unavailable in [false, true]) {
    testWidgets('stale action cannot retry when evidence changes (unavailable=$unavailable)',
        (tester) async {
      var reads = 0;
      var preparations = 0;
      await tester.pumpWidget(_page(
        readAction: () async {
          if (++reads == 1) return PegaroutePreparationRetryAction.retryPreparation;
          if (unavailable) throw StateError('Database unavailable');
          return null; // e.g. another screen began funding, or expiry elapsed.
        },
        onRetry: () async => preparations++,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry preparation'));
      await tester.pumpAndSettle();
      expect(preparations, 0);
      expect(find.byType(NewPrimaryButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('repeated taps cannot overlap preparation or approval checks', (tester) async {
    var reads = 0;
    var preparations = 0;
    final check = Completer<PegaroutePreparationRetryAction?>();
    final prepare = Completer<void>();
    await tester.pumpWidget(_page(
      readAction: () async {
        if (++reads == 1) return PegaroutePreparationRetryAction.checkApproval;
        return check.future;
      },
      onRetry: () async {
        preparations++;
        await prepare.future;
      },
    ));
    await tester.pumpAndSettle();
    final button = tester.widget<NewPrimaryButton>(find.byType(NewPrimaryButton));
    button.onPressed();
    button.onPressed(); // Even a stale callback cannot bypass the in-flight guard.
    await tester.pump();
    expect(reads, 2);
    expect(preparations, 0);
    expect(tester.widget<NewPrimaryButton>(find.byType(NewPrimaryButton)).disabled, true);
    check.complete(PegaroutePreparationRetryAction.checkApproval);
    await tester.pump();
    button.onPressed();
    expect(preparations, 1);
    expect(reads, 2);
    prepare.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<NewPrimaryButton>(find.byType(NewPrimaryButton)).disabled, false);
  });

  testWidgets('closing during the eligibility recheck cannot start preparation', (tester) async {
    var reads = 0;
    var preparations = 0;
    final check = Completer<PegaroutePreparationRetryAction?>();
    await tester.pumpWidget(_page(
      readAction: () async {
        if (++reads == 1) return PegaroutePreparationRetryAction.checkApproval;
        return check.future;
      },
      onRetry: () async => preparations++,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check approval'));
    await tester.pumpWidget(const SizedBox.shrink());
    check.complete(PegaroutePreparationRetryAction.checkApproval);
    await tester.pumpAndSettle();
    expect(preparations, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completion after closing does not update disposed UI', (tester) async {
    final prepare = Completer<void>();
    await tester.pumpWidget(_page(
      readAction: () async => PegaroutePreparationRetryAction.continuePreparation,
      onRetry: () => prepare.future,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    prepare.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
