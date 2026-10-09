import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mimics ElectrumX 2.0.0: if the first request on a connection isn't
/// server.version it answers with an error and closes the socket. This is what
/// electrum1.cipig.net does, and what caused the endless SOCKET CLOSED loop.
class _VersionOnlyServer {
  final _server = Completer<ServerSocket>();
  final methodsSeen = <String>[];

  Future<int> start() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.complete(server);
    server.listen((socket) {
      var handshakeDone = false;
      socket.listen((data) {
        for (final line in utf8.decode(data).split('\n')) {
          if (line.trim().isEmpty) continue;
          final request = json.decode(line) as Map<String, dynamic>;
          final method = request['method'] as String;
          methodsSeen.add(method);
          final id = request['id'];
          if (!handshakeDone && method != 'server.version') {
            socket.write(json.encode({
                  'jsonrpc': '2.0',
                  'error': {'code': 1, 'message': 'use server.version to identify client'},
                  'id': id,
                }) +
                '\n');
            socket.destroy();
            return;
          }
          handshakeDone = true;
          socket.write(json.encode({
                'jsonrpc': '2.0',
                'result': method == 'server.version' ? ['ElectrumX 2.0.0', '1.4'] : null,
                'id': id,
              }) +
              '\n');
        }
      });
    });
    return server.port;
  }
}

void main() {
  setUp(() => CakeTor.instance = CakeTorDisabled());

  test('connect() performs the server.version handshake first', () async {
    final server = _VersionOnlyServer();
    final port = await server.start();

    final client = ElectrumClient();
    final statuses = <ConnectionStatus>[];
    client.onConnectionStatusChange = statuses.add;

    await client.connectToUri(
      Uri(scheme: 'tcp', host: '127.0.0.1', port: port),
      useSSL: false,
    );

    // The first request on the wire must be the handshake; a version-only
    // server closes the socket otherwise (the SOCKET CLOSED loop).
    expect(server.methodsSeen.first, 'server.version');

    // And a normal request afterwards must not trip the server's guard.
    await client.ping();
    expect(client.isConnected, isTrue);
    expect(statuses, isNot(contains(ConnectionStatus.disconnected)));

    await client.close();
  });
}
