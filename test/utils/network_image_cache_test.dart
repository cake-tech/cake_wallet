import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:cake_wallet/utils/network_image_cache.dart";
import "package:flutter_test/flutter_test.dart";
import "package:path/path.dart" as p;

const _url = "https://example.com/icons/btc.svg";

void main() {
  late Directory root;
  late Directory cacheDir;
  late List<Uri> fetched;

  NetworkImageCache cacheWith(Future<Uint8List> Function(Uri uri) fetch) => NetworkImageCache(
    directoryPath: cacheDir.path,
    fetch: (uri) {
      fetched.add(uri);
      return fetch(uri);
    },
  );

  NetworkImageCache bytesCache([List<int> bytes = const [1, 2, 3]]) =>
      cacheWith((_) async => Uint8List.fromList(bytes));

  setUp(() {
    root = Directory.systemTemp.createTempSync("network_image_cache_test");
    cacheDir = Directory(p.join(root.path, NetworkImageCache.directoryName));
    fetched = [];
  });

  tearDown(() => root.deleteSync(recursive: true));

  test("names the cached file after the sha256 of the url", () async {
    final file = await bytesCache().getFile(_url);

    expect(
      file.path,
      p.join(cacheDir.path, "ab98cafc7e8340aa06dfc1c05dcaa53475686c21bdf979ac86882052872510e8"),
    );
    expect(file.readAsBytesSync(), [1, 2, 3]);
  });

  test("serves a later lookup from disk, also from a fresh instance", () async {
    await bytesCache().getFile(_url);
    final file = await bytesCache().getFile(_url);

    expect(fetched, [Uri.parse(_url)]);
    expect(file.readAsBytesSync(), [1, 2, 3]);
  });

  test("concurrent lookups share one download", () async {
    final gate = Completer<Uint8List>();
    final cache = cacheWith((_) => gate.future);

    final first = cache.getFile(_url);
    final second = cache.getFile(_url);
    gate.complete(Uint8List.fromList([9]));

    expect((await first).path, (await second).path);
    expect(fetched, hasLength(1));
  });

  test("a failed download caches nothing and is retried on the next lookup", () async {
    var fail = true;
    final cache = cacheWith((uri) async {
      if (fail) {
        throw HttpException("nope", uri: uri);
      }
      return Uint8List.fromList([7]);
    });

    await expectLater(cache.getFile(_url), throwsA(isA<HttpException>()));
    expect(cacheDir.existsSync() ? cacheDir.listSync() : <FileSystemEntity>[], isEmpty);

    fail = false;
    expect((await cache.getFile(_url)).readAsBytesSync(), [7]);
    expect(fetched, hasLength(2));
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
}
