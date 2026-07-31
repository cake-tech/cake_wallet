import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

/// A raster asset declared in pubspec.yaml. The asset-SVG branch of
/// [CakeImageWidget] goes through `vector_graphics` and a generated `.vec`
/// sidecar that is not produced for widget tests, so it is not covered here.
const _assetPath = "assets/images/2fa.png";

final _imageNodes = find.semantics.byFlag(SemanticsFlag.isImage);

final _labelledNodes = find.semantics.byPredicate(
  (node) => node.label.isNotEmpty,
  describeMatch: (_) => "labelled SemanticsNodes",
);

/// The stops a screen reader would actually visit, in traversal order.
List<SemanticsNode> _stops(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal().toList();

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));
  await tester.pump();
}

void main() {
  group("asset image", () {
    testWidgets("a null semanticsLabel keeps the image out of the tree", (tester) async {
      await _pump(tester, const CakeImageWidget(imageUrl: _assetPath, width: 24, height: 24));

      expect(_imageNodes, findsNothing);
      expect(_labelledNodes, findsNothing);
      expect(_stops(tester), isEmpty);
    });

    testWidgets("a semanticsLabel makes it an announced image", (tester) async {
      await _pump(
        tester,
        const CakeImageWidget(
          imageUrl: _assetPath,
          width: 24,
          height: 24,
          semanticsLabel: "Two-factor authentication",
        ),
      );

      expect(find.semantics.byLabel("Two-factor authentication"), findsOne);
      expect(_stops(tester), hasLength(1));
      expect(
        _stops(tester).single,
        containsSemantics(label: "Two-factor authentication", isImage: true),
      );
    });
  });

  group("error placeholder", () {
    testWidgets("a decorative placeholder contributes nothing", (tester) async {
      await _pump(tester, const CakeImageWidget(width: 24, height: 24));

      expect(_labelledNodes, findsNothing);
      expect(_stops(tester), isEmpty);
    });

    testWidgets("an empty imageUrl is treated the same way", (tester) async {
      await _pump(tester, const CakeImageWidget(imageUrl: "", width: 24, height: 24));

      expect(_labelledNodes, findsNothing);
      expect(_stops(tester), isEmpty);
    });

    testWidgets("a labelled placeholder is announced as an image", (tester) async {
      await _pump(
        tester,
        const CakeImageWidget(width: 24, height: 24, semanticsLabel: "Wallet avatar"),
      );

      expect(_stops(tester), hasLength(1));
      expect(_stops(tester).single, containsSemantics(label: "Wallet avatar", isImage: true));
    });

    testWidgets("a caller-supplied errorWidget owns its own semantics", (tester) async {
      await _pump(
        tester,
        const CakeImageWidget(width: 24, height: 24, errorWidget: Text("BTC")),
      );

      expect(find.semantics.byLabel("BTC"), findsOne);
      expect(_imageNodes, findsNothing);
    });
  });
}
