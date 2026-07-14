import 'dart:io';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:cw_core/utils/tor/socks.dart';
import 'package:cw_core/utils/tor/torch.dart';

abstract class CakeTorInstance {
  bool get started;

  int get port => -1;

  bool get enabled => false;

  bool get bootstrapped => false;

  Future<void> start();
  Future<void> stop();

  static Future<CakeTorInstance> getInstance() async {
    if (Platform.isLinux) {
      try {
        String? socksServer;
        if (Platform.environment["SOCKS_SERVER"] != null) {
          socksServer = Platform.environment["SOCKS_SERVER"]!;
        }
        if (Platform.environment["SOCKS_PROXY"] != null) {
          socksServer = Platform.environment["SOCKS_PROXY"]!;
        }
        if (socksServer != null) {
          final uri = Uri.tryParse(socksServer);
          if (uri != null) {
            return CakeTorSocks(uri.port);
          } else {
            final uri = Uri.tryParse("socks5://$socksServer");
            if (uri != null) {
              return CakeTorSocks(uri.port);
            }
          }
        }
      } catch (e) {
        printV(
          "Failed to identify linux version - no SOCKS_SERVER variable found or malformed",
        );
      }
    }
    try {
      final torch = await CakeTorTorch.getInstance();
      if (torch != null) {
        return torch;
      }
    } catch (e) {
      printV("Failed to initialize torch: $e");
    }
    return CakeTorDisabled();
  }

  String toString() {
    return """
CakeTorInstance(
  port: $port,
  started: $started,
  bootstrapped: $bootstrapped,
  enabled: $enabled,
)
""";
  }
}