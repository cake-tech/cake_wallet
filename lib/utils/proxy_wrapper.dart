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

  // Method to get or create the Tor instance
  Future<HttpClient> getProxyInstance() async {
    if (!started) {
      started = true;
      _client = HttpClient();

      // Assign connection factory.
      SocksTCPClient.assignToHttpClient(_client!, [
        ProxySettings(
          InternetAddress.loopbackIPv4,
          Tor.instance.port,
          password: null,
        ),
      ]);
    }
    return _client!;
  }
}
