import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:crypto/crypto.dart";
import "package:cw_core/root_dir.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:path/path.dart" as p;


class NetworkImageCache {
  NetworkImageCache({String? directoryPath, Future<Uint8List> Function(Uri)? fetch})
    : _directoryPath = directoryPath,
      _fetch = fetch ?? _fetchWithProxy;

  static NetworkImageCache instance = NetworkImageCache();

  static const directoryName = "network_image_cache";
  static const _fetchTimeout = Duration(seconds: 30);

  final Future<Uint8List> Function(Uri) _fetch;


  final _downloads = <String, Future<File>>{};
  String? _directoryPath;

  static Future<Uint8List> _fetchWithProxy(Uri uri) async {
    final response = await ProxyWrapper().get(clearnetUri: uri).timeout(_fetchTimeout);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw HttpException("Image request failed with status ${response.statusCode}", uri: uri);
    }
    return response.bodyBytes;
  }

  static String fileNameFor(String url) => sha256.convert(utf8.encode(url)).toString();

  Future<String> _path() async =>
      _directoryPath ??= p.join((await getAppDir()).path, directoryName);

  File _fileIn(String directoryPath, String url) => File(p.join(directoryPath, fileNameFor(url)));

  File? cachedFileSync(String url) {
    if (_directoryPath == null) {
      return null;
    }
    final file = _fileIn(_directoryPath!, url);
    return file.existsSync() ? file : null;
  }

  Future<File> getFile(String url) async {
    final file = _fileIn(await _path(), url);
    if (file.existsSync()) {
      return file;
    }
    return _downloads[url] ??= _download(url, file).whenComplete(() {
      _downloads.remove(url);
    });
  }

  Future<File> _download(String url, File file) async {
    final bytes = await _fetch(Uri.parse(url));
    await file.parent.create(recursive: true);
    final partial = File("${file.path}.part");
    await partial.writeAsBytes(bytes, flush: true);
    return partial.rename(file.path);
  }

  Future<void> removeFromCache(String url) async {
    try {
      await _fileIn(await _path(), url).delete();
    } on FileSystemException catch (_) {}
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
  }
}

