import 'dart:io';

import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/settings/tor_connection.dart';
import 'package:socks5_proxy/socks.dart';
import 'package:tor/tor.dart';

class ProxyWrapper {
  // Private constructor
  ProxyWrapper._privateConstructor(this.settingsStore);

  // Static private instance of Tor
  static final ProxyWrapper _instance = ProxyWrapper._privateConstructor();

  final SettingsStore settingsStore;

  HttpClient? _torClient;

  // Factory method to get the singleton instance of TorSingleton
  static ProxyWrapper get instance => _instance;

  static int get port => Tor.instance.port;

  static bool get enabled => Tor.instance.enabled;

  bool started = false;
  bool torEnabled = false;
  bool torOnly = false;

  // Method to get or create the Tor instance
  Future<HttpClient> getProxyInstance({int? portOverride}) async {
    if (!started) {
      started = true;
      _torClient = HttpClient();

      // Assign connection factory.
      SocksTCPClient.assignToHttpClient(_torClient!, [
        ProxySettings(
          InternetAddress.loopbackIPv4,
          portOverride ?? Tor.instance.port,
          password: null,
        ),
      ]);
    }

    return _torClient!;
  }

  Future<HttpClientResponse> get(Uri uri, {Map<String, String>? headers, int? portOverride}) async {
    HttpClient? client;
    if (settingsStore.torConnectionMode == TorConnectionMode.onionOnly ||
        settingsStore.torConnectionMode == TorConnectionMode.enabled) {
      client = await getProxyInstance(portOverride: portOverride);
    } else {
      client = HttpClient();
    }

    if (settingsStore.torConnectionMode == TorConnectionMode.onionOnly) {
      if (!uri.path.contains(".onion")) {
        throw Exception("Cannot connect to clearnet");
      }
    }

    HttpClientResponse? response;

    try {
      final request = await client.getUrl(uri);
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.add(key, value);
        });
      }
      response = await request.close();
    } catch (e) {
      if (!torOnly && torEnabled) {
        // try again without tor:
        client = HttpClient();
        final request = await client.getUrl(uri);
        if (headers != null) {
          headers.forEach((key, value) {
            request.headers.add(key, value);
          });
        }
        response = await request.close();
      }
    }

    return response!;
  }

  Future<HttpClientResponse> post(Uri uri,
      {Map<String, String>? headers, int? portOverride}) async {
    HttpClient? client;
    if (settingsStore.torConnectionMode == TorConnectionMode.onionOnly ||
        settingsStore.torConnectionMode == TorConnectionMode.enabled) {
      client = await getProxyInstance(portOverride: portOverride);
    } else {
      client = HttpClient();
    }

    if (settingsStore.torConnectionMode == TorConnectionMode.onionOnly) {
      if (!uri.path.contains(".onion")) {
        throw Exception("Cannot connect to clearnet");
      }
    }

    HttpClientResponse? response;

    try {
      final request = await client.postUrl(uri);
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.add(key, value);
        });
      }
      response = await request.close();
    } catch (e) {
      if (!torOnly && torEnabled) {
        // try again without tor:
        client = HttpClient();
        final request = await client.postUrl(uri);
        if (headers != null) {
          headers.forEach((key, value) {
            request.headers.add(key, value);
          });
        }
        response = await request.close();
      }
    }

    return response!;
  }
}
