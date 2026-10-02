import 'dart:io';
import 'dart:math';

import 'package:payjoin/http.dart' as pj_http;
import 'package:payjoin/payjoin.dart' as pj;

class MailroomManager {
  MailroomManager({
    required this.relayUrls,
    required this.directoryUrls,
  });

  List<String> relayUrls;
  List<String> directoryUrls;
  final List<String> _failedRelays = [];
  final List<String> _failedDirectories = [];

  void setConfig({
    required List<String> relays,
    required List<String> directories,
  }) {
    relayUrls = relays;
    directoryUrls = directories;
    _failedRelays.clear();
    _failedDirectories.clear();
  }

  String chooseRelay() {
    final available =
        relayUrls.where((r) => !_failedRelays.contains(r)).toList();
    if (available.isEmpty) {
      throw StateError('No valid relays available');
    }
    return available[Random.secure().nextInt(available.length)];
  }

  String chooseDirectory() {
    final available =
        directoryUrls.where((d) => !_failedDirectories.contains(d)).toList();
    if (available.isEmpty) {
      throw StateError('No valid directories available');
    }
    return available[Random.secure().nextInt(available.length)];
  }

  void addFailedRelay(String relay) => _failedRelays.add(relay);

  void addFailedDirectory(String directory) => _failedDirectories.add(directory);

  void clearFailedRelays() => _failedRelays.clear();

  /// Fetches OHTTP keys from [directory] by tunneling through relays.
  ///
  /// Tries relays in random order, marking each failed relay and moving to the
  /// next. If the directory itself returns a non-2xx status it is marked as
  /// failed and the error is rethrown so the caller can choose another
  /// directory.
  Future<pj.OhttpKeys> fetchOhttpKeysFromDirectory(String directory) async {
    final attemptedRelays = <String>{};
    while (true) {
      final relay = chooseRelay();
      if (!attemptedRelays.add(relay)) {
        throw Exception('All relays failed for directory $directory');
      }
      try {
        return await pj_http.fetchOhttpKeys(
          ohttpRelayUrl: relay,
          directoryUrl: directory,
        );
      } on SocketException {
        addFailedRelay(relay);
      } on HttpException catch (e) {
        if (e.message.contains('HTTP ')) {
          addFailedDirectory(directory);
          rethrow;
        }
        addFailedRelay(relay);
      }
    }
  }
}
