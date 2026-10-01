import "dart:async";
import "dart:typed_data";

import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

class RemoteImage {
  RemoteImage._(this.bytesFuture);

  final Future<Uint8List?> bytesFuture;

  Uint8List? bytes;

  DateTime? _failedAt;
}

class RemoteImageCache {
  static const maxBytes = 5 * 1024 * 1024;
  static const maxConcurrentDownloads = 6;

  static const _maxEntries = 200;
  static const _timeout = Duration(seconds: 30);
  static const _failureRetryDelay = Duration(minutes: 5);

  static final _entries = <String, RemoteImage>{};
  static final _failures = <String, RemoteImage>{};

  static final _waitingDownloads = <Completer<void>>[];
  static int _activeDownloads = 0;

  static bool isRemote(String url) => url.startsWith("https://") || url.startsWith("http://");

  static RemoteImage load(String url) {
    final cached = _entries.remove(url);
    if (cached != null) {
      _entries[url] = cached;
      return cached;
    }

    final failed = _failures[url];
    if (failed != null) {
      if (DateTime.now().difference(failed._failedAt!) < _failureRetryDelay) {
        return failed;
      }

      _failures.remove(url);
    }

    if (_entries.length >= _maxEntries) {
      _entries.remove(_entries.keys.first);
    }

    final image = _entries[url] = RemoteImage._(_download(url));
    unawaited(
      image.bytesFuture.then((bytes) {
        image.bytes = bytes;
        if (bytes != null) {
          return;
        }

        if (identical(_entries[url], image)) {
          _entries.remove(url);
        }

        _rememberFailure(url, image);
      }),
    );

    return image;
  }

  static void _rememberFailure(String url, RemoteImage image) {
    _failures.remove(url);
    if (_failures.length >= _maxEntries) {
      _failures.remove(_failures.keys.first);
    }

    _failures[url] = image.._failedAt = DateTime.now();
  }

  static Future<Uint8List?> _download(String url) async {
    await _takeDownloadSlot();
    try {
      final response = await ProxyWrapper().get(clearnetUri: Uri.parse(url)).timeout(_timeout);

      if (response.statusCode != 200) {
        printV("Remote image $url answered ${response.statusCode}");
        return null;
      }

      final bytes = response.bodyBytes;
      if (bytes.length > maxBytes || !(_isRaster(bytes) || isSvg(bytes))) {
        printV("Remote image $url is not an image or is over $maxBytes bytes");
        return null;
      }

      return bytes;
    } catch (e) {
      printV("Failed to load remote image $url: $e");
      return null;
    } finally {
      _releaseDownloadSlot();
    }
  }

  static Future<void> _takeDownloadSlot() async {
    if (_activeDownloads < maxConcurrentDownloads) {
      _activeDownloads++;
      return;
    }

    final slot = Completer<void>();
    _waitingDownloads.add(slot);
    await slot.future;
  }

  // Newest first, so the rows on screen after a fling load before the rows scrolled past
  static void _releaseDownloadSlot() {
    if (_waitingDownloads.isEmpty) {
      _activeDownloads--;
      return;
    }

    _waitingDownloads.removeLast().complete();
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) =>
      bytes.length >= signature.length &&
      Iterable<int>.generate(signature.length).every((i) => bytes[i] == signature[i]);

  // PNG, JPEG, GIF, WebP (RIFF) and ICO signatures
  static bool _isRaster(Uint8List bytes) =>
      _startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47]) ||
      _startsWith(bytes, const [0xFF, 0xD8, 0xFF]) ||
      _startsWith(bytes, const [0x47, 0x49, 0x46, 0x38]) ||
      _startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) ||
      _startsWith(bytes, const [0x00, 0x00, 0x01, 0x00]);

  static bool isSvg(Uint8List bytes) {
    final head = String.fromCharCodes(bytes.take(1024)).toLowerCase();
    return head.contains("<svg") && !head.contains("<html");
  }
}
