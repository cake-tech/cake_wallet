import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:cake_wallet/utils/network_image_cache.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:path/path.dart" as p;

import "testing_network_image_cache.dart";

const _url = "https://example.com/icons/btc.svg";
const _mb = 1024 * 1024;

void main() {
  late Directory root;
  late Directory cacheDir;
  late List<Uri> fetched;

  NetworkImageCache cacheWith(Future<http.Response> Function(http.Request request) handler) =>
      TestingNetworkImageCache(
        directoryPath: cacheDir.path,
        client: MockClient((request) {
          fetched.add(request.url);
          return handler(request);
        }),
      );

  NetworkImageCache bytesCache([List<int> bytes = const [1, 2, 3]]) =>
      cacheWith((_) async => http.Response.bytes(bytes, 200));

  File seed(String name, int bytes, {required Duration age}) {
    final file = File(p.join(cacheDir.path, name))..createSync(recursive: true);
    file.openSync(mode: FileMode.write)
      ..truncateSync(bytes)
      ..closeSync();
    file.setLastModifiedSync(DateTime.now().subtract(age));
    return file;
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync("network_image_cache_test");
    cacheDir = Directory(p.join(root.path, NetworkImageCache.directoryName));
    fetched = [];
  });

  tearDown(() => root.deleteSync(recursive: true));

  test("names the cached file after the sha256 of the url", () async {
    final file = await bytesCache().getFile(_url);

    expect(
      file?.path,
      p.join(cacheDir.path, "ab98cafc7e8340aa06dfc1c05dcaa53475686c21bdf979ac86882052872510e8"),
    );
    expect(file?.readAsBytesSync(), [1, 2, 3]);
  });

  test("serves a later lookup from disk, also from a fresh instance", () async {
    await bytesCache().getFile(_url);
    final file = await bytesCache().getFile(_url);

    expect(fetched, [Uri.parse(_url)]);
    expect(file?.readAsBytesSync(), [1, 2, 3]);
  });

  test("concurrent lookups share one download", () async {
    final gate = Completer<void>();
    final cache = cacheWith((_) async {
      await gate.future;
      return http.Response.bytes([9], 200);
    });

    final first = cache.getFile(_url);
    final second = cache.getFile(_url);
    gate.complete();

    expect((await first)?.path, isNotNull);
    expect((await first)?.path, (await second)?.path);
    expect(fetched, hasLength(1));
  });

  test("an error status returns null, caches nothing and is retried on the next lookup", () async {
    var status = 404;
    final cache = cacheWith((_) async => http.Response.bytes([7], status));

    expect(await cache.getFile(_url), isNull);
    expect(cacheDir.existsSync() ? cacheDir.listSync() : <FileSystemEntity>[], isEmpty);

    status = 200;

    expect((await cache.getFile(_url))?.readAsBytesSync(), [7]);
    expect(fetched, hasLength(2));
  });

  test("a network error returns null instead of throwing", () async {
    final cache = cacheWith((_) async => throw const SocketException("offline"));

    expect(await cache.getFile(_url), isNull);
  });

  test("an image of exactly 8 MB is cached", () async {
    final cache = bytesCache(Uint8List(NetworkImageCache.maxImageBytes));

    expect((await cache.getFile(_url))?.lengthSync(), NetworkImageCache.maxImageBytes);
  });

  test("an image whose Content-Length is over 8 MB is rejected", () async {
    final cache = bytesCache(Uint8List(NetworkImageCache.maxImageBytes + 1));

    expect(await cache.getFile(_url), isNull);
    expect(cache.cachedFileSync(_url), isNull);
  });

  test("an image without a Content-Length is cut off once it passes 8 MB", () async {
    var sent = 0;
    final cache = TestingNetworkImageCache(
      directoryPath: cacheDir.path,
      client: MockClient.streaming(
        (_, _) async => http.StreamedResponse(
          Stream.periodic(Duration.zero, (_) {
            sent += _mb;
            return Uint8List(_mb);
          }).take(100),
          200,
        ),
      ),
    );

    expect(await cache.getFile(_url), isNull);
    expect(sent, lessThan(20 * _mb));
    expect(cache.cachedFileSync(_url), isNull);
  });

  test("cachedFileSync finds a file another instance cached", () async {
    await bytesCache().getFile(_url);
    final cache = bytesCache();

    expect(cache.cachedFileSync(_url)?.readAsBytesSync(), [1, 2, 3]);
    expect(cache.cachedFileSync("https://example.com/other.png"), isNull);
  });

  test("removeFromCache drops a single entry", () async {
    final cache = bytesCache();
    await cache.getFile(_url);
    await cache.getFile("https://example.com/other.png");

    await cache.removeFromCache(_url);
    await cache.removeFromCache("https://example.com/never-cached.png");

    expect(cache.cachedFileSync(_url), isNull);
    expect(cache.cachedFileSync("https://example.com/other.png"), isNotNull);
  });

  test("size sums the cached files and clear empties the cache", () async {
    final cache = bytesCache(List.filled(1500, 0));

    expect(await cache.size(), 0);

    await cache.getFile(_url);
    await cache.getFile("https://example.com/other.png");

    expect(await cache.size(), 3000);

    await cache.clear();

    expect(await cache.size(), 0);
    expect(cacheDir.existsSync(), isFalse);

    await cache.getFile(_url);

    expect(await cache.size(), 1500);
  });

  test("a download past 128 MB removes the oldest files until the cache is below it", () async {
    final oldest = seed("a", 2 * _mb, age: const Duration(hours: 4));
    final older = seed("b", 2 * _mb, age: const Duration(hours: 3));
    final old = seed("c", 2 * _mb, age: const Duration(hours: 2));
    final big = seed("d", 122 * _mb, age: const Duration(hours: 1));
    final cache = bytesCache(Uint8List(5 * _mb));

    expect(await cache.size(), NetworkImageCache.maxCacheBytes);

    final first = await cache.getFile(_url);

    expect([oldest, older, old].where((file) => file.existsSync()), isEmpty);
    expect(big.existsSync(), isTrue);
    expect(first?.existsSync(), isTrue);
    expect(await cache.size(), 127 * _mb);

    final second = await cache.getFile("https://example.com/icons/eth.svg");

    expect(big.existsSync(), isFalse);
    expect(first?.existsSync(), isTrue);
    expect(second?.existsSync(), isTrue);
    expect(await cache.size(), 10 * _mb);
  });
}
