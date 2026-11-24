import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cw_core/utils/proxy_logger/abstract.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One file of the router model package and the SHA-256 it must have.
class AskCakeRouterFile {
  const AskCakeRouterFile(this.path, this.sha256, this.bytes);

  final String path;
  final String sha256;
  final int bytes;
}

/// Where the trained router model lives on this device, and how it gets there.
///
/// The model (about 129 MB) is too large to ship inside the app, so it is
/// fetched once, after the user agrees, from [baseUrl] and kept in Application
/// Support. Every file is checked against a hash compiled into the app before
/// it is used: the model decides which screen a request opens, so a tampered
/// copy must never load. A developer copy in Documents/askcake_bench is used
/// by debug builds, and by builds that have no download source; a release
/// build with a source always uses the verified download.
class AskCakeRouterStore {
  AskCakeRouterStore({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  /// Folder URL that serves the files of [files] under [version]/[packageName].mlpackage/.
  /// Can be pointed elsewhere at build time with --dart-define=ASK_CAKE_ROUTER_URL=...
  static const _defaultBaseUrl =
      String.fromEnvironment('ASK_CAKE_ROUTER_URL', defaultValue: 'https://assets.cakelabs.com/ask-cake/router/');

  /// The same files on an onion service, used while the wallet's Tor is on, so
  /// the download reaches the files directly instead of through a CDN that may
  /// turn Tor exits away. Hashes are checked exactly as for [baseUrl].
  static const _onionBaseUrl = String.fromEnvironment('ASK_CAKE_ROUTER_ONION_URL',
      defaultValue: 'http://6vlnam7ypu5acwgffryjgclxrdf7jbmuyawbhu6hyidjnzzasgdlk7yd.onion/ask-cake/router/');

  static const packageName = 'smollm2-135m-p8';

  /// Changes whenever the model does, so an app update fetches the new one.
  static const version = 'r9c';

  static const files = [
    AskCakeRouterFile('Manifest.json', 'e022281fb6c212ff8b27d7b71736408f405081022232c830f2b390a3fccd66e1', 617),
    AskCakeRouterFile('Data/com.apple.CoreML/model.mlmodel',
        '6eb6442abf229b1aecda72f9ccb41474a8324c5662b400da337a4808fc8b67b3', 571392),
    AskCakeRouterFile('Data/com.apple.CoreML/weights/weight.bin',
        '0449a2b56414c82bb92df8607ff46c826880e4b9d16e5f6b85906e4a2eb3e52d', 134855680),
  ];

  final String baseUrl;

  bool get canDownload => baseUrl.isNotEmpty;

  /// True while the wallet's Tor is on: the download then goes through it and is several times slower.
  bool get overTor => ProxyWrapper().requestNetwork() == RequestNetwork.tor;

  static int get downloadBytes => files.fold(0, (sum, file) => sum + file.bytes);

  Future<Directory> _downloaded() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/askcake/router-$version/$packageName.mlpackage');
  }

  /// Path of a usable model package, or null when none is on the device yet.
  Future<String?> locate() async {
    final documents = await getApplicationDocumentsDirectory();
    final developer = Directory('${documents.path}/askcake_bench/$packageName.mlpackage');
    final useDeveloperCopy = kDebugMode || !canDownload;
    if (useDeveloperCopy && File('${developer.path}/${files.last.path}').existsSync()) return developer.path;
    final downloaded = await _downloaded();
    if (File('${downloaded.path}/.complete').existsSync()) return downloaded.path;
    return null;
  }

  /// Fetches and verifies the model. Returns its path, or throws [AskCakeRouterDownloadException].
  /// [onProgress] receives a fraction from 0 to 1.
  Future<String> download({void Function(double fraction)? onProgress}) async {
    if (!canDownload) throw const AskCakeRouterDownloadException('noSource');
    final target = await _downloaded();
    final total = downloadBytes;
    var done = 0;
    final client = ProxyWrapper().getHttpClient();
    final overTor = this.overTor;
    if (kDebugMode) debugPrint('ASKCAKE DOWNLOAD overTor=$overTor');
    try {
      for (final file in files) {
        final destination = File('${target.path}/${file.path}');
        if (destination.existsSync() && await _hash(destination) == file.sha256) {
          done += file.bytes;
          onProgress?.call(done / total);
          continue;
        }
        await destination.parent.create(recursive: true);
        final partial = File('${destination.path}.part');
        final path = '$version/$packageName.mlpackage/${file.path}';
        var response = await _fetch(client, overTor && _onionBaseUrl.isNotEmpty ? _onionBaseUrl : baseUrl, path);
        // The onion is a single host: if it cannot be reached, the usual address
        // is tried, still through Tor because the client itself is.
        if (response == null || response.statusCode != 200) {
          if (overTor && _onionBaseUrl.isNotEmpty) {
            await response?.drain<void>().catchError((_) {});
            response = await _fetch(client, baseUrl, path);
          }
        }
        if (response == null) throw const AskCakeRouterDownloadException('network');
        if (response.statusCode != 200) {
          throw AskCakeRouterDownloadException('http${response.statusCode}');
        }
        final digestSink = _DigestSink();
        final hasher = sha256.startChunkedConversion(digestSink);
        final sink = partial.openWrite();
        try {
          await for (final chunk in response) {
            hasher.add(chunk);
            sink.add(chunk);
            done += chunk.length;
            onProgress?.call((done / total).clamp(0, 1));
          }
        } finally {
          await sink.close();
        }
        hasher.close();
        if (digestSink.value.toString() != file.sha256) {
          await partial.delete();
          throw const AskCakeRouterDownloadException('checksum');
        }
        await partial.rename(destination.path);
      }
      await File('${target.path}/.complete').writeAsString(jsonEncode({'version': version}));
      await _removeOlderVersions(target.parent);
      return target.path;
    } on SocketException {
      throw const AskCakeRouterDownloadException('network');
    } on HttpException {
      throw const AskCakeRouterDownloadException('network');
    } finally {
      client.close(force: true);
    }
  }

  /// One file request; null when the host could not be reached at all.
  Future<HttpClientResponse?> _fetch(HttpClient client, String base, String path) async {
    final root = base.endsWith('/') ? base : '$base/';
    try {
      final request = await client.getUrl(Uri.parse('$root$path'));
      return await request.close();
    } on SocketException {
      return null;
    } on HttpException {
      return null;
    }
  }

  /// Removes the downloaded model, so the next open downloads it again (test page).
  Future<void> deleteDownloaded() async {
    final root = (await _downloaded()).parent;
    if (root.existsSync()) await root.delete(recursive: true);
  }

  Future<String> _hash(File file) async => (await sha256.bind(file.openRead()).first).toString();

  Future<void> _removeOlderVersions(Directory current) async {
    final root = current.parent;
    if (!root.existsSync()) return;
    for (final entry in root.listSync()) {
      final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (entry is Directory && name.startsWith('router-') && entry.path != current.path) {
        await entry.delete(recursive: true);
      }
    }
  }
}

class AskCakeRouterDownloadException implements Exception {
  const AskCakeRouterDownloadException(this.code);

  /// noSource, network, checksum or http<status>.
  final String code;

  @override
  String toString() => 'AskCakeRouterDownloadException($code)';
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
