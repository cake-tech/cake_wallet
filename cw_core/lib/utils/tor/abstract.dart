import 'dart:io';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/tor/android.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:cw_core/utils/tor/tails.dart';

abstract class CakeTorInstance {
  bool get started;

  int get port => -1;

  bool get enabled => false;

  bool get bootstrapped => false;

  Future<void> start();
  Future<void> stop();

  static CakeTorInstance getInstance() {
    if (Platform.isAndroid) {
      return CakeTorAndroid();
    }
    if (Platform.isLinux) {
      try {
        final os = File("/etc/os-release").readAsLinesSync();
        for (var line in os) {
          if (!line.startsWith("ID=")) continue;
          if (!line.contains("tails")) continue;
          return CakeTorTails();
        }
      } catch (e) {
        printV("Failed to identify linux version - /etc/os-release missing");
      }
    }
    return CakeTorDisabled();
  }
}