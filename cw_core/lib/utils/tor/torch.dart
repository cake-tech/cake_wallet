import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/tor/abstract.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:torch_dart/abstract_tor.dart';

class CakeTorTorch implements CakeTorInstance {
  final List<Tor> _torList;

  CakeTorTorch(this._torList);

  static Future<CakeTorTorch?> getInstance() async {
    final list = await Tor.getTorList();
    if (list.isEmpty) {
      return null;
    }
    return CakeTorTorch(list);
  }

  @override
  bool get bootstrapped => isTorRunning;

  @override
  bool get enabled => isTorRunning;

  @override
  int get port => 42142;

  @override
  Future<void> start() async {
    await _runEmbeddedTor();
  }

  @override
  bool started = false;

  static bool isTorRunning = false;

  @override
  Future<void> stop() async {
    started = false;
  }

  Future<void> _runEmbeddedTor() async {
    final dir = await getApplicationCacheDirectory();

    final torList = await Tor.getTorList();
    printV("tor version: ${torList.first.version}");

    if (isTorRunning) {
      started = true;
      printV("Proxy is running");
      return;
    }
    isTorRunning = true;
    started = true;

    printV("Starting embedded tor");
    printV("app docs: $dir");
    final torrc = """
SocksPort $port
Log notice stdout
RunAsDaemon 0
DataDirectory ${p.join(dir.path, "tor-data")}
""";
    final torrcPath = p.join(dir.absolute.path, "torrc");
    File(torrcPath).writeAsStringSync(torrc);

    final tor = _torList.first;
    tor.start(["nonexistent", "-f", torrcPath]);
  }

  @override
  String toString() {
    return """
CakeTorTorch(
  port: $port,
  started: $started,
  bootstrapped: $bootstrapped,
  enabled: $enabled,
  torList:
    - ${_torList.map((e) => e.version).join(",\n    - ")}
)
""";
  }
}