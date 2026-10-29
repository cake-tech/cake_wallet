import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/copy_wrapper.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

import "../../utils/semantics_helpers.dart";

const _copyable = ClipboardData(text: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq");

const _flash = Duration(milliseconds: 800);

final _actionableNodes = find.semantics.byPredicate(
  (node) => node.getSemanticsData().customSemanticsActionIds?.isNotEmpty ?? false,
  describeMatch: (_) => "SemanticsNodes with custom actions",
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale("en", ""),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _settleCopy(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() {
    S.current = const S();
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group("builder mode with something to copy", () {
    testWidgets("exposes one merged button node carrying a copy action", (tester) async {
      await _pump(
        tester,
        CopyWrapper(
          data: _copyable,
          duration: _flash,
          builder: (_, copied) => Text(copied ? S.current.copied : "Address"),
        ),
      );

      expect(screenReaderStops(tester), hasLength(1));
      expect(
        screenReaderStops(tester).single,
        isSemantics(
          label: "Address",
          hint: S.current.copy,
          isButton: true,
          customActions: <CustomSemanticsAction>[CustomSemanticsAction(label: S.current.copy)],
        ),
      );
    });

    testWidgets("the content does not become a second, unactionable node", (tester) async {
      await _pump(
        tester,
        CopyWrapper(
          data: _copyable,
          duration: _flash,
          builder: (_, copied) => Column(
            children: [Text(copied ? S.current.copied : "Address"), const Text("Bitcoin")],
          ),
        ),
      );

      expect(find.text("Address"), findsOneWidget);
      expect(find.text("Bitcoin"), findsOneWidget);
      expect(screenReaderStops(tester), hasLength(1));
      expect(_actionableNodes, findsOne);
    });

    testWidgets("a tap copies, flipping the label and marking a live region", (tester) async {
      await _pump(
        tester,
        CopyWrapper(
          data: _copyable,
          duration: _flash,
          builder: (_, copied) => Text(copied ? S.current.copied : "Address"),
        ),
      );

      expect(screenReaderStops(tester).single, isSemantics(label: "Address", isLiveRegion: false));

      await tester.tap(find.text("Address"));
      await _settleCopy(tester);

      expect(
        screenReaderStops(tester).single,
        isSemantics(label: S.current.copied, isLiveRegion: true),
      );

      await tester.pump(_flash * 2);
      expect(screenReaderStops(tester).single, isSemantics(label: "Address", isLiveRegion: false));
    });
  });

  group("builder mode with nothing to copy", () {
    testWidgets("returns the child with no actionable node at all", (tester) async {
      await _pump(
        tester,
        CopyWrapper(duration: _flash, builder: (_, copied) => const Text("Address")),
      );

      expect(find.text("Address"), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
      expect(_actionableNodes, findsNothing);
      expect(find.semantics.byFlag(SemanticsFlag.isButton), findsNothing);
      expect(screenReaderStops(tester).single, isSemantics(label: "Address", isButton: false));
    });

    testWidgets("offers no copy hint either", (tester) async {
      await _pump(
        tester,
        CopyWrapper(duration: _flash, builder: (_, copied) => const Text("Address")),
      );

      expect(find.semantics.byHint(S.current.copy), findsNothing);
    });
  });

  group("requireLongPress", () {
    testWidgets("swaps the hint and stops claiming to be a button", (tester) async {
      await _pump(
        tester,
        CopyWrapper(
          data: _copyable,
          duration: _flash,
          requireLongPress: true,
          builder: (_, copied) => Text(copied ? S.current.copied : "Seed phrase"),
        ),
      );

      expect(
        screenReaderStops(tester).single,
        isSemantics(
          label: "Seed phrase",
          hint: S.current.long_press_to_copy,
          isButton: false,
          customActions: <CustomSemanticsAction>[CustomSemanticsAction(label: S.current.copy)],
        ),
      );
    });

    testWidgets("a long press copies, a plain tap does not", (tester) async {
      await _pump(
        tester,
        CopyWrapper(
          data: _copyable,
          duration: _flash,
          requireLongPress: true,
          builder: (_, copied) => Text(copied ? S.current.copied : "Seed phrase"),
        ),
      );

      await tester.tap(find.text("Seed phrase"));
      await _settleCopy(tester);
      expect(find.text(S.current.copied), findsNothing);

      await tester.longPress(find.text("Seed phrase"));
      await _settleCopy(tester);
      expect(find.text(S.current.copied), findsOneWidget);

      await tester.pump(_flash * 2);
    });
  });

  group("controlBuilder mode", () {
    testWidgets("stacks no extra gesture or action on the caller's control", (tester) async {
      await _pump(
        tester,
        CopyWrapper(
          data: _copyable,
          duration: _flash,
          controlBuilder: (_, copied, onCopy) => TextButton(
            onPressed: onCopy,
            child: Text(copied ? S.current.copied : S.current.copy),
          ),
        ),
      );

      expect(screenReaderStops(tester), hasLength(1));
      expect(_actionableNodes, findsNothing);
      expect(
        screenReaderStops(tester).single,
        isSemantics(
          label: S.current.copy,
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
          isLiveRegion: false,
        ),
      );
    });

    testWidgets("hands the control a null onCopy when there is nothing to copy", (tester) async {
      await _pump(
        tester,
        CopyWrapper(
          duration: _flash,
          controlBuilder: (_, copied, onCopy) => TextButton(
            onPressed: onCopy,
            child: Text(copied ? S.current.copied : S.current.copy),
          ),
        ),
      );

      expect(
        screenReaderStops(tester).single,
        isSemantics(label: S.current.copy, isEnabled: false, hasTapAction: false),
      );
    });

    testWidgets("marks the control a live region once copied", (tester) async {
      await _pump(
        tester,
        CopyWrapper(
          data: _copyable,
          duration: _flash,
          controlBuilder: (_, copied, onCopy) => TextButton(
            onPressed: onCopy,
            child: Text(copied ? S.current.copied : S.current.copy),
          ),
        ),
      );

      await tester.tap(find.text(S.current.copy));
      await _settleCopy(tester);

      expect(
        screenReaderStops(tester).single,
        isSemantics(label: S.current.copied, isLiveRegion: true),
      );

      await tester.pump(_flash * 2);
      expect(
        screenReaderStops(tester).single,
        isSemantics(label: S.current.copy, isLiveRegion: false),
      );
    });
  });
}
