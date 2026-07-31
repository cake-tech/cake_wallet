import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/copy_wrapper.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

const _copyable = ClipboardData(text: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq");

/// Long enough to outlive the 600ms `tester.longPress` pump window -- a shorter
/// flash would be reverted inside it, before the test could observe it -- yet
/// short enough that every test can drain the revert timer.
const _flash = Duration(milliseconds: 800);

/// The stops a screen reader would actually visit, in traversal order.
List<SemanticsNode> _stops(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal().toList();

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

/// Lets the async copy path (`shouldShowCopied`) settle, then drains the timer
/// that flips the state back so the test does not end with one pending.
Future<void> _settleCopy(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() {
    S.current = const S();
  });

  setUp(() {
    // Swallow Clipboard.setData and HapticFeedback.vibrate.
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

      expect(_stops(tester), hasLength(1));
      expect(
        _stops(tester).single,
        containsSemantics(
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

      // Both captions are painted, but they merge into the single copy node.
      expect(find.text("Address"), findsOneWidget);
      expect(find.text("Bitcoin"), findsOneWidget);
      expect(_stops(tester), hasLength(1));
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

      expect(_stops(tester).single, containsSemantics(label: "Address", isLiveRegion: false));

      await tester.tap(find.text("Address"));
      await _settleCopy(tester);

      expect(
        _stops(tester).single,
        containsSemantics(label: S.current.copied, isLiveRegion: true),
      );

      // Drain the revert timer.
      await tester.pump(_flash * 2);
      expect(_stops(tester).single, containsSemantics(label: "Address", isLiveRegion: false));
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
      expect(_stops(tester).single, containsSemantics(label: "Address", isButton: false));
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
        _stops(tester).single,
        containsSemantics(
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

      // The control is the only node, and it owns the action itself.
      expect(_stops(tester), hasLength(1));
      expect(_actionableNodes, findsNothing);
      expect(
        _stops(tester).single,
        containsSemantics(
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
        _stops(tester).single,
        containsSemantics(label: S.current.copy, isEnabled: false, hasTapAction: false),
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
        _stops(tester).single,
        containsSemantics(label: S.current.copied, isLiveRegion: true),
      );

      await tester.pump(_flash * 2);
      expect(_stops(tester).single, containsSemantics(label: S.current.copy, isLiveRegion: false));
    });
  });
}
