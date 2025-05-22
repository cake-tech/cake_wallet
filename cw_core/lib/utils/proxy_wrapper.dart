import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:tor/tor.dart';
import 'package:http/io_client.dart' as ioc;

class ProxyWrapper {
  ProxyWrapper();

  Future<ProxySocket> getSocksSocket(bool sslEnabled, String host, int port, {Duration? connectionTimeout}) async {
    return ProxySocket.connect(sslEnabled, ProxyAddress(host: host, port: port), connectionTimeout: connectionTimeout);
  }

  ioc.IOClient getHttpIOClient() {
    final httpClient = ProxyWrapper().getHttpClient();
    return ioc.IOClient(httpClient);
  }

  @Deprecated('Use ProxyWrapper().get/post/put methods instead, and provide proper clearnet and onion uri.')
  HttpClient getHttpClient() {
    final client = HttpClient();

    if (CakeTor.instance.enabled) {
      SocksTCPClient.assignToHttpClient(client, [
        ProxySettings(InternetAddress.loopbackIPv4,
            CakeTor.instance.port,
            password: null,
          ),
      ]);
    } else {
      printV("+++++++ TOR NOT STARTED");
    }

    return client;
  }

  int getPort() => CakeTor.instance.port;

  HttpClient getProxyHttpClient({int? portOverride}) {
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

  Future<HttpClientResponse> makeGet({
    required HttpClient client,
    required Uri uri,
    required Map<String, String>? headers,
  }) async {
    final request = await client.getUrl(uri);
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }
    return await request.close();
  }

  Future<HttpClientResponse> makePost({
    required HttpClient client,
    required Uri uri,
    required Map<String, String>? headers,
    String? body,
  }) async {
    final request = await client.postUrl(uri);
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }
    if (body != null) {
      request.add(utf8.encode(body));
    }
    await request.flush();
    return await request.close();
  }

  Future<HttpClientResponse> makePut({
    required HttpClient client,
    required Uri uri,
    required Map<String, String>? headers,
    String? body,
  }) async {
    final request = await client.putUrl(uri);
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }
    if (body != null) {
      request.add(utf8.encode(body));
    }
    await request.flush();
    return await request.close();
  }

  Future<HttpClientResponse> get({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
  }) async {
    HttpClient? torClient;
    bool torEnabled = CakeTor.instance.started;

    if (CakeTor.instance.started) {
      torEnabled = true;
    } else {
      torEnabled = false;
    }

    // if tor is enabled, try to connect to the onion url first:
    if (torEnabled) {
      try {
        torClient = await getProxyHttpClient(portOverride: portOverride);
      } catch (_) {
        rethrow;
      }

      if (onionUri != null) {
        try {
          return await makeGet(
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
          return await makeGet(
            client: torClient!,
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
            return await makeGet(
              client: HttpClient(),
              uri: clearnetUri,
              headers: headers,
            );
          },
          // createHttpClient: NullOverrides().createHttpClient,
        );
      } catch (_) {
        // we weren't able to get a response:
        rethrow;
      }
    }

    throw Exception("Unable to connect to server");
  }
  

  Future<HttpClientResponse> post({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
    String? body,
    bool allowMitmMoneroBypassSSLCheck = false,
  }) async {
    HttpClient? torClient;
    HttpClient clearnetClient = HttpClient();

    if (allowMitmMoneroBypassSSLCheck) {
      clearnetClient.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    }

    bool torEnabled = CakeTor.instance.started;

    if (torEnabled) {
      try {
        torClient = await getProxyHttpClient(portOverride: portOverride);
      } catch (_) {
        rethrow;
      }
      if (allowMitmMoneroBypassSSLCheck) {
        torClient.badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      }
      if (onionUri != null) {
        try {
          return await makePost(
            client: torClient,
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
          return await makePost(
            client: torClient,
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
            return await makePost(
              client: clearnetClient,
              uri: clearnetUri,
              headers: headers,
              body: body,
            );
          },
          // createHttpClient: NullOverrides().createHttpClient,
        );
      } catch (_) {
        rethrow;
      }
    }

    throw Exception("Unable to connect to server");
  }

  Future<HttpClientResponse> put({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
    String? body,
  }) async {
    HttpClient? torClient;
    bool torEnabled = CakeTor.instance.started;

    if (torEnabled) {
      try {
        torClient = await getProxyHttpClient(portOverride: portOverride);
      } catch (_) {}

      if (onionUri != null) {
        try {
          return await makePut(
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
          return await makePut(
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
            return await makePut(
              client: HttpClient(),
              uri: clearnetUri,
              headers: headers,
              body: body,
            );
          },
          // createHttpClient: NullOverrides().createHttpClient,
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