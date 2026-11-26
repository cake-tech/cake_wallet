import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:crypto/crypto.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:flutter/foundation.dart";
// import needed for the Request and Client classes.
// it's not insecure, it's just type annotation.
// ...don't use it for anything else though. please.
import "package:http/http.dart" as very_insecure_http_do_not_use;
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";


class NetworkImageCache {
  NetworkImageCache({String? directoryPath})
    : _directoryPath = directoryPath;

  static NetworkImageCache instance = NetworkImageCache();

  static const directoryName = "network_image_cache";
  static const maxImageBytes = 8 * 1024 * 1024;
  static const maxCacheBytes = 128 * 1024 * 1024;
  static const _fetchTimeout = Duration(seconds: 30);

  @visibleForOverriding
  very_insecure_http_do_not_use.Client createClient() => ProxyWrapper().getHttpIOClient();

  final _downloads = <String, Future<File>>{};
  String? _directoryPath;
  int? _size;

  static String fileNameFor(String url) => sha256.convert(utf8.encode(url)).toString();

  Future<String> _path() async =>
      _directoryPath ??= p.join((await getApplicationCacheDirectory()).path, directoryName);

  File _fileIn(String directoryPath, String url) => File(p.join(directoryPath, fileNameFor(url)));

  File? cachedFileSync(String url) {
    if (_directoryPath == null) {
      return null;
    }
    final file = _fileIn(_directoryPath!, url);
    return file.existsSync() ? file : null;
  }

  Future<File?> getFile(String url) async {
    try {
      final file = _fileIn(await _path(), url);
      if (file.existsSync()) {
        return file;
      }
      return await (_downloads[url] ??= _download(url, file).whenComplete(() {
        _downloads.remove(url);
      }));
    } catch (e) {
      printV("NetworkImageCache: failed to load $url: $e");
      return null;
    }
  }

  Future<File> _download(String url, File file) async {
    final bytes = await _fetch(Uri.parse(url));
    await file.parent.create(recursive: true);
    final partial = File("${file.path}.part");
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
    await _trimToLimit(bytes.length);
    return file;
  }

  Future<Uint8List> _fetch(Uri uri) async {
    final client = createClient();
    try {
      return await _readImage(client, uri).timeout(_fetchTimeout);
    } finally {
      client.close();
    }
  }

  Future<Uint8List> _readImage(very_insecure_http_do_not_use.Client client, Uri uri) async {
    final response = await client.send(very_insecure_http_do_not_use.Request("GET", uri));
    if (response.statusCode != 200) {
      throw HttpException("Image request failed with status ${response.statusCode}", uri: uri);
    }
    if ((response.contentLength ?? 0) > maxImageBytes) {
      throw HttpException("Image is larger than $maxImageBytes bytes", uri: uri);
    }

    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      bytes.add(chunk);
      if (bytes.length > maxImageBytes) {
        throw HttpException("Image is larger than $maxImageBytes bytes", uri: uri);
      }
    }
    if (bytes.isEmpty) {
      throw HttpException("Image response was empty", uri: uri);
    }
    return bytes.takeBytes();
  }

  Future<void> _trimToLimit(int addedBytes) async {
    _size = _size == null ? await size() : _size! + addedBytes;
    if (_size! > maxCacheBytes) {
      await _removeOldest();
    }
  }

  Future<void> _removeOldest() async {
    final files = <({File file, FileStat stat})>[];
    await for (final entity in Directory(await _path()).list()) {
      if (entity is File) {
        files.add((file: entity, stat: entity.statSync()));
      }
    }
    files.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));

    var total = files.fold(0, (sum, entry) => sum + entry.stat.size);
    for (final (:file, :stat) in files) {
      if (total < maxCacheBytes) {
        break;
      }
      try {
        await file.delete();
      } on FileSystemException catch (_) {}
      total -= stat.size;
    }
    _size = total;
  }

  Future<void> removeFromCache(String url) async {
    try {
      await _fileIn(await _path(), url).delete();
    } on FileSystemException catch (_) {}
    _size = null;
  }

  Future<int> size() async {
    final directory = Directory(await _path());
    if (!directory.existsSync()) {
      return 0;
    }

    var total = 0;
    await for (final entity in directory.list()) {
      if (entity is File) {
        total += await entity.length().catchError((Object _) => 0);
      }
    }
    return total;
  }

  Future<void> clear() async {
    final directory = Directory(await _path());
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
    _size = 0;
  }
}
