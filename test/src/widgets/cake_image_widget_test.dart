import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/remote_image_cache.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:vector_graphics/vector_graphics.dart";

class _LocalServerOverrides extends HttpOverrides {
  _LocalServerOverrides(this.port);

  final int port;

  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)
    ..connectionFactory =
        (uri, proxyHost, proxyPort) => Socket.startConnect(InternetAddress.loopbackIPv4, port);
}

// A 1x1 transparent PNG
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

const _svg = '<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24">'
    '<rect width="24" height="24" fill="#FF0000"/></svg>';

void main() {
  late HttpServer server;
  late Map<String, List<int>> bodies;
  late List<String> requestedPaths;
  late Completer<void> slowResponses;
  late int slowInFlight;
  late int maxSlowInFlight;

  setUpAll(() async {
    CakeTor.instance = CakeTorDisabled();

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      requestedPaths.add(path);
      if (path.startsWith("/slow/")) {
        slowInFlight++;
        maxSlowInFlight = slowInFlight > maxSlowInFlight ? slowInFlight : maxSlowInFlight;
        await slowResponses.future;
        slowInFlight--;
      }

      final body = bodies[path] ?? (path.startsWith("/slow/") ? _png : null);
      if (body == null) {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        request.response.add(body);
      }
      await request.response.close();
    });
    HttpOverrides.global = _LocalServerOverrides(server.port);
  });

  tearDownAll(() async {
    HttpOverrides.global = null;
    await server.close(force: true);
  });

  setUp(() {
    requestedPaths = [];
    slowResponses = Completer<void>();
    slowInFlight = 0;
    maxSlowInFlight = 0;
    bodies = {
      "/icon.png": _png,
      "/icon-without-suffix": _svg.codeUnits,
      "/too-big": [..._png, ...List.filled(RemoteImageCache.maxBytes, 0)],
      "/page": "<html><body>not an image</body></html>".codeUnits,
    };
  });

  Future<void> pumpRemote(WidgetTester tester, Widget widget, String url) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: Center(child: widget)));
      await RemoteImageCache.load(url).bytesFuture;
    });
    await tester.pump();
  }

  testWidgets("an https URL is fetched through the shared loader and drawn from memory",
      (tester) async {
    const url = "https://icons.example/icon.png";

    await pumpRemote(tester, const CakeImageWidget(imageUrl: url, width: 24, height: 24), url);

    expect(requestedPaths, ["/icon.png"]);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
    expect(image.fit, BoxFit.cover);
  });

  testWidgets("an SVG body renders as SVG even without the .svg suffix", (tester) async {
    const url = "https://icons.example/icon-without-suffix";

    await pumpRemote(tester, const CakeImageWidget(imageUrl: url, width: 24, height: 24), url);

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.bytesLoader, isA<SvgBytesLoader>());
    expect(find.byType(Image), findsNothing);
  });

  testWidgets("a body over the size cap falls back to the error widget", (tester) async {
    const url = "https://icons.example/too-big";

    await pumpRemote(
      tester,
      const CakeImageWidget(imageUrl: url, width: 24, height: 24, errorWidget: Text("failed")),
      url,
    );

    expect(requestedPaths, ["/too-big"]);
    expect(find.text("failed"), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets("a body that is not an image falls back to the error widget", (tester) async {
    const url = "https://icons.example/page";

    await pumpRemote(
      tester,
      const CakeImageWidget(imageUrl: url, width: 24, height: 24, errorWidget: Text("failed")),
      url,
    );

    expect(find.text("failed"), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets("a failed load shows the fallback letter instead of the placeholder", (tester) async {
    const url = "https://icons.example/page";

    await pumpRemote(
      tester,
      const CakeImageWidget(imageUrl: url, width: 24, height: 24, fallbackName: " ink"),
      url,
    );

    expect(find.text("I"), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets("a failed URL is not fetched again when the widget is built again", (tester) async {
    const url = "https://icons.example/missing";

    await pumpRemote(
      tester,
      const CakeImageWidget(imageUrl: url, width: 24, height: 24, fallbackName: "Ink"),
      url,
    );
    await pumpRemote(
      tester,
      CakeImageWidget(key: UniqueKey(), imageUrl: url, width: 24, height: 24, fallbackName: "Ink"),
      url,
    );

    expect(requestedPaths, ["/missing"]);
    expect(find.text("I"), findsOneWidget);
  });

  test("no more than maxConcurrentDownloads fetches run at once, the rest wait for a slot",
      () async {
    final images = [
      for (int i = 0; i < 10; i++) RemoteImageCache.load("https://icons.example/slow/$i"),
    ];

    while (requestedPaths.length < RemoteImageCache.maxConcurrentDownloads) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(requestedPaths, hasLength(RemoteImageCache.maxConcurrentDownloads));

    slowResponses.complete();
    final bytes = await Future.wait(images.map((image) => image.bytesFuture));

    expect(bytes, everyElement(isNotNull));
    expect(requestedPaths, hasLength(10));
    expect(maxSlowInFlight, RemoteImageCache.maxConcurrentDownloads);
  });

  testWidgets("outlineColor draws a border over the image, and none is drawn by default",
      (tester) async {
    BoxDecoration? outlineOf(WidgetTester tester) => tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.foregroundDecoration)
        .whereType<BoxDecoration>()
        .firstOrNull;

    await tester.pumpWidget(
      const MaterialApp(
        home: CakeImageWidget(imageUrl: "assets/new-ui/crypto_full_icons/base.svg", width: 48),
      ),
    );
    expect(outlineOf(tester), isNull);
    expect(find.byType(ClipRRect), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: CakeImageWidget(
          imageUrl: "assets/new-ui/crypto_full_icons/base.svg",
          width: 48,
          isRoundedSquare: true,
          outlineColor: Colors.red,
        ),
      ),
    );
    final outline = outlineOf(tester)!;
    expect(outline.border, Border.all(color: Colors.red, width: 2));
    expect(outline.borderRadius, BorderRadius.circular(14));
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets("asset paths load from the bundle, never through the remote loader", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            CakeImageWidget(imageUrl: "assets/new-ui/crypto_full_icons/base.svg", width: 24),
            CakeImageWidget(imageUrl: "assets/images/ada_icon.png", width: 24),
          ],
        ),
      ),
    );

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      svg.bytesLoader,
      isA<AssetBytesLoader>().having(
        (loader) => loader.assetName,
        "assetName",
        "assets/new-ui/crypto_full_icons/base.svg.vec",
      ),
    );
    expect(svg.fit, BoxFit.contain);

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(image.fit, isNull);
    expect(image.filterQuality, FilterQuality.medium);

    expect(find.byType(FutureBuilder<Uint8List?>), findsNothing);
    expect(requestedPaths, isEmpty);
  });
}
