import "dart:convert";
import "dart:io";

import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/network_image_cache.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:path/path.dart" as p;

import "../../utils/semantics_helpers.dart";
import "../../utils/testing_network_image_cache.dart";

const _assetPath = "assets/images/2fa.png";
const _svgAssetPath = "assets/images/2fa_warning_dark.svg";

final _imageNodes = find.semantics.byFlag(SemanticsFlag.isImage);

final _labelledNodes = find.semantics.byPredicate(
  (node) => node.label.isNotEmpty,
  describeMatch: (_) => "labelled SemanticsNodes",
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));
  await tester.pump();
}

final _png = base64Decode(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
);

/// Lets the cache's real file I/O progress, then flushes the fake-async zone the widget lives in.
Future<void> _settle(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
}

Finder _fileImage(String path) => find.byWidgetPredicate(
  (widget) =>
      widget is Image && widget.image is FileImage && (widget.image as FileImage).file.path == path,
);

void main() {
  group("asset image", () {
    testWidgets("a null semanticsLabel keeps the image out of the tree", (tester) async {
      await _pump(tester, const CakeImageWidget(imageUrl: _assetPath, width: 24, height: 24));

      expect(_imageNodes, findsNothing);
      expect(_labelledNodes, findsNothing);
      expect(screenReaderStops(tester), isEmpty);
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
      expect(screenReaderStops(tester), hasLength(1));
      expect(
        screenReaderStops(tester).single,
        isSemantics(label: "Two-factor authentication", isImage: true),
      );
    });
  });

  group("svg asset", () {
    testWidgets("a null semanticsLabel keeps the image out of the tree", (tester) async {
      await _pump(tester, const CakeImageWidget(imageUrl: _svgAssetPath, width: 24, height: 24));

      expect(_imageNodes, findsNothing);
      expect(_labelledNodes, findsNothing);
      expect(screenReaderStops(tester), isEmpty);
    });

    testWidgets("a semanticsLabel makes it an announced image", (tester) async {
      await _pump(
        tester,
        const CakeImageWidget(
          imageUrl: _svgAssetPath,
          width: 24,
          height: 24,
          semanticsLabel: "Two-factor authentication",
        ),
      );

      expect(screenReaderStops(tester), hasLength(1));
      expect(
        screenReaderStops(tester).single,
        isSemantics(label: "Two-factor authentication", isImage: true),
      );
    });
  });

  group("error placeholder", () {
    testWidgets("a decorative placeholder contributes nothing", (tester) async {
      await _pump(tester, const CakeImageWidget(width: 24, height: 24));

      expect(_labelledNodes, findsNothing);
      expect(screenReaderStops(tester), isEmpty);
    });

    testWidgets("an empty imageUrl is treated the same way", (tester) async {
      await _pump(tester, const CakeImageWidget(imageUrl: "", width: 24, height: 24));

      expect(_labelledNodes, findsNothing);
      expect(screenReaderStops(tester), isEmpty);
    });

    testWidgets("a labelled placeholder is announced as an image", (tester) async {
      await _pump(
        tester,
        const CakeImageWidget(width: 24, height: 24, semanticsLabel: "Wallet avatar"),
      );

      expect(screenReaderStops(tester), hasLength(1));
      expect(screenReaderStops(tester).single, isSemantics(label: "Wallet avatar", isImage: true));
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

  group("network image", () {
    late NetworkImageCache previous;
    late Directory root;
    late int fetches;

    void useCache(int status, List<int> body) =>
        NetworkImageCache.instance = TestingNetworkImageCache(
          directoryPath: root.path,
          client: MockClient((_) async {
            fetches++;
            return http.Response.bytes(body, status);
          }),
        );

    String cachedPath(String url) => p.join(root.path, NetworkImageCache.fileNameFor(url));

    setUp(() {
      previous = NetworkImageCache.instance;
      root = Directory.systemTemp.createTempSync("cake_image_widget_test");
      fetches = 0;
    });

    tearDown(() {
      NetworkImageCache.instance = previous;
      root.deleteSync(recursive: true);
    });

    testWidgets("downloads once, then renders from disk on the first frame", (tester) async {
      const url = "https://example.com/coins/btc.png";
      useCache(200, _png);

      await _pump(tester, const CakeImageWidget(imageUrl: url, width: 24, height: 24));

      expect(find.byType(CupertinoActivityIndicator), findsOne);

      await _settle(tester, () => _fileImage(cachedPath(url)).evaluate().isNotEmpty);

      expect(_fileImage(cachedPath(url)), findsOne);
      expect(File(cachedPath(url)).readAsBytesSync(), _png);

      await _pump(tester, const SizedBox());
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CakeImageWidget(imageUrl: url, width: 24, height: 24)),
        ),
      );

      expect(_fileImage(cachedPath(url)), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(fetches, 1);
    });

    testWidgets("an svg url is rendered from its cached file", (tester) async {
      const url = "https://example.com/coins/xmr.svg";
      useCache(200, utf8.encode('<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>'));

      await _pump(tester, const CakeImageWidget(imageUrl: url, width: 24, height: 24));
      await _settle(tester, () => find.byType(SvgPicture).evaluate().isNotEmpty);

      expect(find.byType(SvgPicture), findsOne);
      expect(File(cachedPath(url)).existsSync(), isTrue);
    });

    testWidgets("an error response shows the error placeholder", (tester) async {
      const url = "https://example.com/coins/missing.png";
      useCache(404, []);

      await _pump(tester, const CakeImageWidget(imageUrl: url, width: 24, height: 24));
      await _settle(tester, () => find.byIcon(Icons.error_outline).evaluate().isNotEmpty);

      expect(find.byIcon(Icons.error_outline), findsOne);
      expect(File(cachedPath(url)).existsSync(), isFalse);
    });
  });
}
