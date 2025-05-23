import 'dart:async';
import 'dart:io';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:http/http.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:tor/tor.dart';
import 'package:http/io_client.dart' as ioc;

class ProxyWrapper {
  static final ProxyWrapper _proxyWrapper = ProxyWrapper._internal();
  
  factory ProxyWrapper() {
    return _proxyWrapper;
  }
  
  ProxyWrapper._internal();
  Future<ProxySocket> getSocksSocket(bool sslEnabled, String host, int port, {Duration? connectionTimeout}) async {
    return ProxySocket.connect(sslEnabled, ProxyAddress(host: host, port: port), connectionTimeout: connectionTimeout);
  }

  ioc.IOClient getHttpIOClient({int? portOverride}) {
    // ignore: deprecated_member_use_from_same_package
    final httpClient = ProxyWrapper().getHttpClient(portOverride: portOverride);
    return ioc.IOClient(httpClient);
  }

  int getPort() => CakeTor.instance.port;

  @Deprecated('Use ProxyWrapper().get/post/put methods instead, and provide proper clearnet and onion uri.')
  HttpClient getHttpClient({int? portOverride}) {
    final torClient = HttpClient();

    if (CakeTor.instance.started) {
      // Assign connection factory.
      SocksTCPClient.assignToHttpClient(torClient, [
        ProxySettings(
          InternetAddress.loopbackIPv4,
          portOverride ?? getPort(),
          password: null,
        ),
      ]);
    }

    return torClient;
  }

  Future<Response> _makeGet({
    required ioc.IOClient client,
    required Uri uri,
    required Map<String, String>? headers,
  }) async {
    final request = await client.get(
      uri,
      headers: headers,
    );
    return request;
  }

  Future<Response> _makePost({
    required ioc.IOClient client,
    required Uri uri,
    required Map<String, String>? headers,
    String? body,
  }) async {
    final request = await client.post(
      uri,
      headers: headers,
      body: body,
    );
    return request;
  }

  Future<Response> _makePut({
    required ioc.IOClient client,
    required Uri uri,
    required Map<String, String>? headers,
    String? body,
  }) async {
    final request = await client.put(
      uri,
      headers: headers,
      body: body,
    );
    return request;
  }

    Future<Response> _makeDelete({
    required ioc.IOClient client,
    required Uri uri,
    required Map<String, String>? headers,
    String? body,
  }) async {
    final request = await client.delete(
      uri,
      headers: headers,
      body: body,
    );
    return request;
  }

  Future<Response> get({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
  }) async {
    ioc.IOClient? torClient;
    bool torEnabled = CakeTor.instance.started;

    if (CakeTor.instance.started) {
      torEnabled = true;
    } else {
      torEnabled = false;
    }

    // if tor is enabled, try to connect to the onion url first:
    if (torEnabled) {
      try {
        // ignore: deprecated_member_use_from_same_package
        torClient = await getHttpIOClient(portOverride: portOverride);
      } catch (_) {
        rethrow;
      }

      if (onionUri != null) {
        try {
          return await _makeGet(
            client: torClient,
            uri: onionUri,
            headers: headers,
          );
        } catch (_) {
          rethrow;
        }
      }

      if (clearnetUri != null) {
        try {
          return await _makeGet(
            client: torClient,
            uri: clearnetUri,
            headers: headers,
          );
        } catch (_) {
          rethrow;
        }
      }
    }

    if (clearnetUri != null) {
      try {
        return HttpOverrides.runZoned(
          () async {
            return await _makeGet(
              client: ioc.IOClient(),
              uri: clearnetUri,
              headers: headers,
            );
          },
        );
      } catch (_) {
        // we weren't able to get a response:
        rethrow;
      }
    }

    throw Exception("Unable to connect to server");
  }
  

  Future<Response> post({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
    String? body,
    bool allowMitmMoneroBypassSSLCheck = false,
  }) async {
    HttpClient? torHttpClient;
    ioc.IOClient? torClient;
    HttpClient cleatnetHttpClient = HttpClient();
    if (allowMitmMoneroBypassSSLCheck) {
      cleatnetHttpClient.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    }

    ioc.IOClient clearnetClient = ioc.IOClient(cleatnetHttpClient);


    bool torEnabled = CakeTor.instance.started;

    if (torEnabled) {
      try {
        // ignore: deprecated_member_use_from_same_package
        torHttpClient = await getHttpClient(portOverride: portOverride);
      } catch (_) {
        rethrow;
      }
      if (allowMitmMoneroBypassSSLCheck) {
        torHttpClient.badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      }
      if (onionUri != null) {
        try {
          return await _makePost(
            client: ioc.IOClient(torHttpClient),
            uri: onionUri,
            headers: headers,
            body: body,
          );
        } catch (_) {
          rethrow;
        }
      }

      if (clearnetUri != null) {
        try {
          return await _makePost(
            client: ioc.IOClient(torHttpClient),
            uri: clearnetUri,
            headers: headers,
            body: body,
          );
        } catch (_) {
          rethrow;
        }
      }
    }

    if (clearnetUri != null) {
      try {
        return HttpOverrides.runZoned(
          () async {
            return await _makePost(
              client: clearnetClient,
              uri: clearnetUri,
              headers: headers,
              body: body,
            );
          },
        );
      } catch (_) {
        rethrow;
      }
    }

    throw Exception("Unable to connect to server");
  }

  Future<Response> put({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
    String? body,
  }) async {
    ioc.IOClient? torClient;
    bool torEnabled = CakeTor.instance.started;

    if (torEnabled) {
      try {
        // ignore: deprecated_member_use_from_same_package
        torClient = await getHttpIOClient(portOverride: portOverride);
      } catch (_) {}

      if (onionUri != null) {
        try {
          return await _makePut(
            client: torClient!,
            uri: onionUri,
            headers: headers,
            body: body,
          );
        } catch (_) {
          rethrow;
        }
      }

      if (clearnetUri != null) {
        try {
          return await _makePut(
            client: torClient!,
            uri: clearnetUri,
            headers: headers,
            body: body,
          );
        } catch (_) {
          rethrow;
        }
      }
    }

    if (clearnetUri != null) {
      try {
        return HttpOverrides.runZoned(
          () async {
            return await _makePut(
              client: ioc.IOClient(),
              uri: clearnetUri,
              headers: headers,
              body: body,
            );
          },
        );
      } catch (_) {
        // we weren't able to get a response:
        rethrow;
      }
    }

    throw Exception("Unable to connect to server");
  }

  Future<Response> delete({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
  }) async {
    ioc.IOClient? torClient;
    bool torEnabled = CakeTor.instance.started;

    if (CakeTor.instance.started) {
      torEnabled = true;
    } else {
      torEnabled = false;
    }

    // if tor is enabled, try to connect to the onion url first:
    if (torEnabled) {
      try {
        // ignore: deprecated_member_use_from_same_package
        torClient = await getHttpIOClient(portOverride: portOverride);
      } catch (_) {
        rethrow;
      }

      if (onionUri != null) {
        try {
          return await _makeDelete(
            client: torClient,
            uri: onionUri,
            headers: headers,
          );
        } catch (_) {
          rethrow;
        }
      }

      if (clearnetUri != null) {
        try {
          return await _makeDelete(
            client: torClient,
            uri: clearnetUri,
            headers: headers,
          );
        } catch (_) {
          rethrow;
        }
      }
    }

    if (clearnetUri != null) {
      try {
        return HttpOverrides.runZoned(
          () async {
            return await _makeDelete(
              client: ioc.IOClient(),
              uri: clearnetUri,
              headers: headers,
            );
          },
        );
      } catch (_) {
        // we weren't able to get a response:
        rethrow;
      }
    }

    throw Exception("Unable to connect to server");
  }
}


class CakeTor {
  static final Tor instance = Tor.instance;
}