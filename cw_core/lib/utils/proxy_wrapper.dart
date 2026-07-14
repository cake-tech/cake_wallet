import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cw_core/utils/proxy_logger/abstract.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:cw_core/utils/tor/abstract.dart';
import 'package:http/http.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:http/io_client.dart' as ioc;

class ProxyWrapper {
  static final ProxyWrapper _proxyWrapper = ProxyWrapper._internal();
  static ProxyLogger? logger;

  factory ProxyWrapper() {
    return _proxyWrapper;
  }
  
  ProxyWrapper._internal();
  Future<ProxySocket> getSocksSocket(bool sslEnabled, String host, int port, {Duration? connectionTimeout}) async {
    logger?.log(
      uri: Uri(
        scheme: sslEnabled ? "https" : "http",
        host: host,
        port: port,
      ),
      method: RequestMethod.newProxySocket,
      body: Uint8List(0),
      response: null,
      network: requestNetwork(),
      error: null
    );
    return ProxySocket.connect(sslEnabled, ProxyAddress(host: host, port: port), connectionTimeout: connectionTimeout);
  }

  RequestNetwork requestNetwork() {
    return CakeTor.instance!.started ? RequestNetwork.tor : RequestNetwork.clearnet;
  }

  ioc.IOClient getHttpIOClient({int? portOverride, bool internal = false}) {
    if (!internal) {
      logger?.log(
        uri: null,
        method: RequestMethod.newHttpIOClient,
        body: Uint8List(0),
        response: null,
        network: requestNetwork(),
        error: null,
      );
    }
    // ignore: deprecated_member_use_from_same_package
    final httpClient = ProxyWrapper().getHttpClient(portOverride: portOverride, internal: true);
    return ioc.IOClient(httpClient);
  }

  int getPort() => CakeTor.instance!.port;

  @Deprecated('Use ProxyWrapper().get/post/put methods instead, and provide proper clearnet and onion uri.')
  HttpClient getHttpClient({int? portOverride, bool internal = false}) {
    if (!internal) {
      logger?.log(
        uri: null,
        method: RequestMethod.newProxySocket,
        body: Uint8List(0),
        response: null,
        network: requestNetwork(),
        error: null
      );
    }
    if (CakeTor.instance!.started) {
      // Assign connection factory.
      final client = HttpClient();
      SocksTCPClient.assignToHttpClient(client, [
        ProxySettings(
          InternetAddress.loopbackIPv4,
          CakeTor.instance!.port,
          password: null,
        ),
      ]);
      return client;
    } else {
      return HttpClient();
    }
  }



  Future<Response> _make({
    required RequestMethod method,
    required ioc.IOClient client,
    required Uri uri,
    required Map<String, String>? headers,
    String? body,
  }) async {
    Object? error;
    Response? resp;
    try {
      switch (method) {
        case RequestMethod.get:
          resp = await client.get(
            uri,
            headers: headers,
          );
          break;
        case RequestMethod.delete:
          resp = await client.delete(
            uri,
            headers: headers,
            body: body,
          );
          break;
        case RequestMethod.post:
          resp = await client.post(
            uri,
            headers: headers,
            body: body,
          );
          break;
        case RequestMethod.put:
          resp = await client.put(
            uri,
            headers: headers,
            body: body,
          );
          break;
        case RequestMethod.newHttpClient:
        case RequestMethod.newHttpIOClient:
        case RequestMethod.newProxySocket:
          throw UnimplementedError();
      }
      return resp;
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      logger?.log(
        uri: uri,
        method: RequestMethod.get,
        body: utf8.encode(body ?? ''),
        response: resp,
        network: requestNetwork(),
        error: error?.toString(),
      );
    }
  }

  Future<Response> get({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
  }) async {
    ioc.IOClient? torClient;
    bool torEnabled = CakeTor.instance!.started;

    if (CakeTor.instance!.started) {
      torEnabled = true;
    } else {
      torEnabled = false;
    }

    // if tor is enabled, try to connect to the onion url first:
    if (torEnabled) {
      try {
        // ignore: deprecated_member_use_from_same_package
        torClient = await getHttpIOClient(portOverride: portOverride, internal: true);
      } catch (_) {
        rethrow;
      }

      if (onionUri != null) {
        try {
          return await _make(
            method: RequestMethod.get,
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
          return await _make(
            method: RequestMethod.get,
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
            return await _make(
              method: RequestMethod.get,
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
    HttpClient cleatnetHttpClient = HttpClient();
    if (allowMitmMoneroBypassSSLCheck) {
      cleatnetHttpClient.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    }

    ioc.IOClient clearnetClient = ioc.IOClient(cleatnetHttpClient);


    bool torEnabled = CakeTor.instance!.started;

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
          return await _make(
            method: RequestMethod.post,
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
          return await _make(
            method: RequestMethod.post,
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
            return await _make(
              method: RequestMethod.post,
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
    bool torEnabled = CakeTor.instance!.started;

    if (torEnabled) {
      try {
        // ignore: deprecated_member_use_from_same_package
        torClient = await getHttpIOClient(portOverride: portOverride, internal: true);
      } catch (_) {}

      if (onionUri != null) {
        try {
          return await _make(
            method: RequestMethod.put,
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
          return await _make(
            method: RequestMethod.put,
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
            return await _make(
              method: RequestMethod.put,
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
    bool torEnabled = CakeTor.instance!.started;

    if (CakeTor.instance!.started) {
      torEnabled = true;
    } else {
      torEnabled = false;
    }

    // if tor is enabled, try to connect to the onion url first:
    if (torEnabled) {
      try {
        // ignore: deprecated_member_use_from_same_package
        torClient = await getHttpIOClient(portOverride: portOverride, internal: true);
      } catch (_) {
        rethrow;
      }

      if (onionUri != null) {
        try {
          return await _make(
            method: RequestMethod.delete,
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
          return await _make(
            method: RequestMethod.delete,
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
            return await _make(
              method: RequestMethod.delete,
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
  static CakeTorInstance? instance;
}
