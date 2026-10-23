import "dart:async";
import "dart:convert";
import "dart:io";

import "package:cw_bitcoin/electrum.dart";
import "package:cw_core/utils/proxy_socket/abstract.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/utils/tor/socks.dart";
import "package:flutter_test/flutter_test.dart";

/// Electrum server stand-in that answers every request with a null result.
class _FakeServer {
  _FakeServer._(this.server);

  final ServerSocket server;
  final clients = <Socket>[];

  /// [closeDelay]: after the client closes its side, wait this long before closing ours.
  static Future<_FakeServer> start({Duration closeDelay = Duration.zero}) async {
    final fake = _FakeServer._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));
    fake.server.listen((c) {
      fake.clients.add(c);
      c.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          final id = (json.decode(line) as Map)["id"];
          c.write('{"jsonrpc":"2.0","result":null,"id":${json.encode(id)}}\n');
        },
        onDone: () => Future.delayed(closeDelay, () => c.destroy()),
        onError: (_) {},
      );
    });
    return fake;
  }

  Uri get uri => Uri.parse("tcp://127.0.0.1:${server.port}");
}

Future<int> _refusedPort() async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = s.port;
  await s.close();
  return port;
}

/// SOCKS5 stand-in for Tor. [connectReply] null = never answer CONNECT, as Tor does while it has
/// no circuit. On 0x00 the stream is piped to 127.0.0.1:[pipeToPort] after [replyDelay].
/// [closed] gets one future per accepted client, completing when that client goes away.
Future<ServerSocket> _fakeTor({
  int? connectReply,
  int? pipeToPort,
  Duration replyDelay = Duration.zero,
  List<Future<void>>? closed,
}) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((c) {
    final gone = Completer<void>();
    closed?.add(gone.future);
    var stage = 0;
    Socket? upstream;
    c.listen(
      (data) async {
        if (stage == 0) {
          stage = 1;
          c.add([0x05, 0x00]);
        } else if (stage == 1) {
          stage = 2;
          if (connectReply == null) {
            return;
          }
          await Future.delayed(replyDelay);
          c.add([0x05, connectReply, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
          if (connectReply == 0x00 && pipeToPort != null) {
            upstream = await Socket.connect(InternetAddress.loopbackIPv4, pipeToPort);
            upstream!.listen(c.add, onDone: () => c.destroy(), onError: (_) {});
          }
        } else {
          upstream?.add(data);
        }
      },
      onError: (_) {},
      onDone: () {
        upstream?.destroy();
        if (!gone.isCompleted) {
          gone.complete();
        }
      },
    );
  });
  return server;
}

ElectrumClient _client(List<ConnectionStatus> log) =>
    ElectrumClient()..onConnectionStatusChange = log.add;

void main() {
  setUp(() => CakeTor.instance = CakeTorDisabled());

  test("a refused connection is reported as failed", () async {
    final log = <ConnectionStatus>[];
    final client = _client(log);

    await client.connectToUri(Uri.parse("tcp://127.0.0.1:${await _refusedPort()}"), useSSL: false);

    expect(log, [ConnectionStatus.connecting, ConnectionStatus.failed]);
  });

  test(
    "a TLS handshake that never finishes fails at the clearnet deadline",
    () async {
      final silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      silent.listen((c) => c.listen((_) {}, onError: (_) {}));
      final log = <ConnectionStatus>[];
      final client = _client(log);
      final stopwatch = Stopwatch()..start();

      await client.connectToUri(Uri.parse("ssl://127.0.0.1:${silent.port}"), useSSL: true);

      expect(log, [ConnectionStatus.connecting, ConnectionStatus.failed]);
      expect(stopwatch.elapsed, greaterThanOrEqualTo(ProxySocket.clearnetConnectDeadline));
      expect(
        stopwatch.elapsed,
        lessThan(ProxySocket.clearnetConnectDeadline + const Duration(seconds: 3)),
      );
      await silent.close();
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test(
    "Tor never answering CONNECT fails at the Tor deadline and closes the proxy socket",
    () async {
      final closed = <Future<void>>[];
      final tor = await _fakeTor(closed: closed);
      CakeTor.instance = CakeTorSocks(tor.port);
      final log = <ConnectionStatus>[];
      final client = _client(log);
      final stopwatch = Stopwatch()..start();

      await client.connectToUri(Uri.parse("tcp://example.onion:50001"), useSSL: false);

      expect(log, [ConnectionStatus.connecting, ConnectionStatus.failed]);
      expect(stopwatch.elapsed, greaterThanOrEqualTo(ProxySocket.torConnectDeadline));
      expect(
        stopwatch.elapsed,
        lessThan(ProxySocket.torConnectDeadline + const Duration(seconds: 3)),
      );
      await closed.single.timeout(const Duration(seconds: 3));
      await tor.close();
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test("Tor refusing CONNECT is reported as failed", () async {
    final tor = await _fakeTor(connectReply: 0x04);
    CakeTor.instance = CakeTorSocks(tor.port);
    final log = <ConnectionStatus>[];
    final client = _client(log);

    await client.connectToUri(Uri.parse("tcp://example.onion:50001"), useSSL: false);

    expect(log, [ConnectionStatus.connecting, ConnectionStatus.failed]);
    await tor.close();
  });

  test(
    "after the server drops the connection, the keep-alive does not report connected",
    () async {
      final server = await _FakeServer.start();
      final log = <ConnectionStatus>[];
      final client = _client(log);
      await client.connectToUri(server.uri, useSSL: false);
      await Future.delayed(const Duration(seconds: 6));
      expect(log.last, ConnectionStatus.connected);

      for (final c in server.clients) {
        c.destroy();
      }
      await server.server.close();
      await Future.delayed(const Duration(seconds: 11)); // two keep-alive ticks

      expect(log, [
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
        ConnectionStatus.disconnected,
      ]);
      expect(client.isConnected, isFalse);
      await client.close();
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test(
    "reconnecting: the old socket closing late does not tear down the new one",
    () async {
      final a = await _FakeServer.start(closeDelay: const Duration(milliseconds: 500));
      final b = await _FakeServer.start();
      final log = <ConnectionStatus>[];
      final client = _client(log);
      await client.connectToUri(a.uri, useSSL: false);
      await Future.delayed(const Duration(seconds: 6));

      // The wallet's 5 s retry reconnects like this, without close().
      await client.connectToUri(b.uri, useSSL: false);
      await Future.delayed(const Duration(seconds: 6)); // A closes after 500 ms; B gets pinged

      expect(client.isConnected, isTrue);
      expect(log.skip(2), [ConnectionStatus.connecting, ConnectionStatus.connected]);
      await client.close();
      await a.server.close();
      await b.server.close();
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test(
    "a connect superseded by a newer one does not install its late socket",
    () async {
      final target = await _FakeServer.start();
      final slowClosed = <Future<void>>[];
      final slowTor = await _fakeTor(
        connectReply: 0x00,
        pipeToPort: target.server.port,
        replyDelay: const Duration(seconds: 2),
        closed: slowClosed,
      );
      final fastTor = await _fakeTor(connectReply: 0x00, pipeToPort: target.server.port);
      final log = <ConnectionStatus>[];
      final client = _client(log);

      CakeTor.instance = CakeTorSocks(slowTor.port);
      unawaited(client.connectToUri(Uri.parse("tcp://old-node.onion:50001"), useSSL: false));
      await Future.delayed(const Duration(milliseconds: 300));
      CakeTor.instance = CakeTorSocks(fastTor.port);
      await client.connectToUri(Uri.parse("tcp://new-node.onion:50001"), useSSL: false);
      final current = client.socket;
      await Future.delayed(const Duration(seconds: 7)); // the old attempt completes at ~2 s

      expect(identical(client.socket, current), isTrue);
      expect(client.isConnected, isTrue);
      expect(log, [
        ConnectionStatus.connecting,
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
      ]);
      await slowClosed.single.timeout(const Duration(seconds: 3)); // the late socket was destroyed
      await client.close();
      await slowTor.close();
      await fastTor.close();
      await target.server.close();
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test(
    "close() during a connect: the late socket is not installed",
    () async {
      final target = await _FakeServer.start();
      final tor = await _fakeTor(
        connectReply: 0x00,
        pipeToPort: target.server.port,
        replyDelay: const Duration(seconds: 2),
      );
      CakeTor.instance = CakeTorSocks(tor.port);
      final client = _client([]);

      unawaited(client.connectToUri(Uri.parse("tcp://node.onion:50001"), useSSL: false));
      await Future.delayed(const Duration(milliseconds: 300));
      await client.close();
      await Future.delayed(const Duration(seconds: 4)); // the connect completes at ~2 s

      expect(client.socket, isNull);
      await tor.close();
      await target.server.close();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
