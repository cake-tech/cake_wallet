import 'dart:convert';
import 'dart:io';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/tor/abstract.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tor_binary/tor_binary_platform_interface.dart';

class CakeTorAndroid implements CakeTorInstance {
  @override
  bool get bootstrapped => _proc != null;

  @override
  bool get enabled => _proc != null;

  @override
  int get port => 42142;

  @override
  Future<void> start() async {
    await _runEmbeddedTor();
  }

  @override
  bool get started => _proc != null;

  @override
  Future<void> stop() async {
    _proc?.kill();
    await _proc?.exitCode;
    _proc = null;
  }

  static Process? _proc;

  Future<void> _runEmbeddedTor() async {
    final dir = await getApplicationCacheDirectory();

    final torBinPath = p.join((await TorBinaryPlatform.instance.getBinaryPath())!, "libtor.so");
    printV("torPath: $torBinPath");

    if (started) {
      printV("Proxy is running");
      return;
    }

    printV("Starting embedded tor");
    printV("app docs: $dir");
    final torrc = """
SocksPort $port
Log notice file ${p.join(dir.path, "tor.log")}
RunAsDaemon 0
DataDirectory ${p.join(dir.path, "tor-data")}
""";
    final torrcPath = p.join(dir.absolute.path, "torrc");
    File(torrcPath).writeAsStringSync(torrc);

    if (_proc != null) {
      try {
        _proc?.kill();
        await _proc?.exitCode;
        _proc = null;
      } catch (e) {
        printV(e);
      }
    }
    printV("path: $torBinPath -f $torrcPath");
    _proc = await Process.start(torBinPath, ["-f", torrcPath]);
    _proc?.stdout.transform(utf8.decoder).forEach(printV);
    _proc?.stderr.transform(utf8.decoder).forEach(printV);
  }

  @override
  String toString() {
    return """
CakeTorAndroid(
  port: $port,
  started: $started,
  bootstrapped: $bootstrapped,
  enabled: $enabled,
  proc: $_proc,
)
""";
  }
}