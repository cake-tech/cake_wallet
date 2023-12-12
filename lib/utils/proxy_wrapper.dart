import 'dart:io';

import 'package:socks5_proxy/socks.dart';
import 'package:tor/tor.dart';

class ProxyWrapper {
  // Private constructor
  ProxyWrapper._privateConstructor();

  // Static private instance of Tor
  static final ProxyWrapper _instance = ProxyWrapper._privateConstructor();

  HttpClient? _client;

  bool started = false;

  // Factory method to get the singleton instance of TorSingleton
  static ProxyWrapper get instance => _instance;

  static int get port => Tor.instance.port;

  static bool get enabled => Tor.instance.enabled;


  // Method to get or create the Tor instance
  Future<HttpClient> getProxyInstance({int? portOverride}) async {
    if (!started) {
      started = true;
      _client = HttpClient();

      // Assign connection factory.
      SocksTCPClient.assignToHttpClient(_client!, [
        ProxySettings(
          InternetAddress.loopbackIPv4,
          portOverride ?? Tor.instance.port,
          password: null,
        ),
      ]);
    }
    return _client!;
  }
}
