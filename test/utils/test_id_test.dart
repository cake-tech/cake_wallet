import "package:cake_wallet/utils/test_id.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "semantics_helpers.dart";

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  group("TestId.fromKey", () {
    test("accepts ValueKey<String> test keys", () {
      expect(
        TestId.fromKey(const ValueKey("home_page_receive_button_key")),
        "home_page_receive_button_key",
      );
      expect(TestId.fromKey(const Key("line_tab_switcher_0_key")), "line_tab_switcher_0_key");
    });

    test("rejects keys that are not test keys", () {
      expect(TestId.fromKey(null), isNull);
      expect(TestId.fromKey(const ValueKey(42)), isNull);
      expect(TestId.fromKey(UniqueKey()), isNull);
      expect(TestId.fromKey(GlobalKey()), isNull);
      expect(TestId.fromKey(const ValueKey("0.00012 BTC 1")), isNull);
      expect(TestId.fromKey(const ValueKey("Satoshi")), isNull);
      expect(TestId.fromKey(const ValueKey("/settings/display")), isNull);
      expect(TestId.fromKey(const ValueKey("home_page_receive_button")), isNull);
      expect(TestId.fromKey(const ValueKey("Home_page_receive_button_key")), isNull);
      expect(TestId.fromKey(const ValueKey("home page_key")), isNull);
    });

    test("accepts a lowercase seed word, so only the lint keeps user data out", () {
      const seedWord = "abandon";
      expect(
        TestId.fromKey(const ValueKey("seed_verification_option_${seedWord}_button_key")),
        "seed_verification_option_abandon_button_key",
      );
    });
  });

  group("TestId.merge", () {
    test("returns the child unchanged without an id", () {
      const child = SizedBox();
      expect(TestId.merge(null, child: child), same(child));
      expect(TestId.container(null, child: child), same(child));
    });

    testWidgets("folds a framework button into one node with id, label and role", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          TestId.merge(
            "merge_button_key",
            child: TextButton(onPressed: () {}, child: const Text("Go")),
          ),
        ),
      );

      expect(find.bySemanticsIdentifier("merge_button_key"), findsOneWidget);
      expect(
        platformNodesWithId(tester, "merge_button_key").single,
        isSemantics(label: "Go", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets("an identifier inside ExcludeSemantics is dropped", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(ExcludeSemantics(child: TestId.merge("excluded_key", child: const Text("hidden")))),
      );

      expect(find.bySemanticsIdentifier("excluded_key"), findsNothing);
      handle.dispose();
    });
  });

  group("TestId.container", () {
    testWidgets("keeps explicit children as their own nodes", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          TestId.container(
            "card_key",
            explicitChildNodes: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Savings"),
                TestId.merge(
                  "card_send_button_key",
                  child: TextButton(onPressed: () {}, child: const Text("Send")),
                ),
              ],
            ),
          ),
        ),
      );

      expect(platformNodesWithId(tester, "card_key"), hasLength(1));
      expect(
        platformNodesWithId(tester, "card_send_button_key").single,
        isSemantics(label: "Send", isButton: true),
      );
      handle.dispose();
    });
  });
}
