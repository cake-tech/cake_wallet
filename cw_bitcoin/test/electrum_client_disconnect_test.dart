import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  // Regression: a dropped/half-open socket must not leave an in-flight `call`
  // hanging forever. That dangling completer previously wedged PIVX shielded
  // sync: the sync task never returned, its in-progress guard stayed set, and
  // no further sync ran until the app was restarted with a fresh client.
  test('failPendingRequests errors in-flight calls and keeps subscriptions', () {
    final client = ElectrumClient();

    final request = Completer<dynamic>();
    final subscription = BehaviorSubject<dynamic>();
    client.tasks['1'] = SocketTask(completer: request, isSubscription: false);
    client.tasks['blockchain.headers.subscribe'] =
        SocketTask(subject: subscription, isSubscription: true);

    // Swallow the delivered error so it isn't an unhandled async error.
    final requestFuture = request.future.catchError((Object _) => null);

    client.failPendingRequests();

    expect(request.isCompleted, isTrue);
    // In-flight request is dropped from the registry, subscription survives.
    expect(client.tasks.containsKey('1'), isFalse);
    expect(client.tasks.containsKey('blockchain.headers.subscribe'), isTrue);

    return requestFuture; // completes (with the swallowed error) → no hang
  });

  // Wiring: an explicit close() (node switching / reconnect teardown) must
  // unblock in-flight requests even if the socket never fires onDone; otherwise
  // _tasks.clear() orphans the completer and the awaiting caller hangs forever.
  test('close() fails pending in-flight requests before clearing tasks',
      () async {
    final client = ElectrumClient();
    final request = Completer<dynamic>();
    client.tasks['7'] = SocketTask(completer: request, isSubscription: false);

    final requestFuture = request.future.catchError((Object _) => null);
    await client.close();

    expect(request.isCompleted, isTrue);
    expect(client.tasks.containsKey('7'), isFalse);
    await requestFuture; // resolves (with swallowed error) → proves no hang
  });

  _halfOpenPingTest();

  test('a redial started by the disconnect listener keeps its status', () async {
    CakeTor.instance = CakeTorDisabled(); // plain TCP, no proxy
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((s) => s.destroy()); // drop every client: onDone fires
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final closedPort = probe.port;
    await probe.close();

    final client = ElectrumClient()..useSSL = false;
    final statuses = <ConnectionStatus>[];
    var redialed = false;
    client.onConnectionStatusChange = (status) {
      statuses.add(status);
      // Wallets reconnect from this listener; the redial runs inside the call.
      if (status == ConnectionStatus.disconnected && !redialed) {
        redialed = true;
        client.connect(host: '127.0.0.1', port: closedPort);
      }
    };

    await client.connect(host: '127.0.0.1', port: server.port);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Without the guard the outer disconnected overwrote connecting, so the
    // failed redial never reported failed and the retry loop stalled.
    expect(redialed, isTrue);
    expect(statuses, contains(ConnectionStatus.failed));
    await server.close();
    await client.close();
  });

  test('replies split across packets and mid character parse once', () async {
    CakeTor.instance = CakeTorDisabled();
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((s) async {
      final bytes =
          utf8.encode('{"id":"1","result":"pié"}\n{"id":"2","result":2}\n');
      // Split inside the first reply and inside the two-byte é.
      for (final cut in [[0, 10], [10, 23], [23, bytes.length]]) {
        s.add(bytes.sublist(cut[0], cut[1]));
        await s.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });

    final client = ElectrumClient()..useSSL = false;
    final first = Completer<dynamic>();
    final second = Completer<dynamic>();
    await client.connect(host: '127.0.0.1', port: server.port);
    client.tasks['1'] = SocketTask(completer: first, isSubscription: false);
    client.tasks['2'] = SocketTask(completer: second, isSubscription: false);

    expect(await first.future.timeout(const Duration(seconds: 2)), 'pié');
    expect(await second.future.timeout(const Duration(seconds: 2)), 2);
    await client.close();
    await server.close();
  });

  test('a ping that outlives a reconnect leaves the new socket alone',
      () async {
    final client = ElectrumClient();
    final statuses = <ConnectionStatus>[];
    client.onConnectionStatusChange = statuses.add;
    client.socket = _SilentSocket();

    final ping = client.ping(); // old socket, will time out
    final replacement = _SilentSocket();
    client.socket = replacement; // reconnect lands mid-ping
    await ping;

    expect(identical(client.socket, replacement), isTrue);
    expect(statuses, isNot(contains(ConnectionStatus.disconnected)));
  });
}

// A failed ping on a still-open socket flags disconnected and leaves the
// socket and its in-flight calls alone: a slow reply must not be aborted. The
// wallet's reconnect fails them if the socket is really dead.
void _halfOpenPingTest() {
  test('ping timeout on a silent socket keeps the socket and pending calls',
      () async {
    final client = ElectrumClient();
    final statuses = <ConnectionStatus>[];
    client.onConnectionStatusChange = statuses.add;
    final silent = _SilentSocket();
    client.socket = silent;
    final request = Completer<dynamic>();
    client.tasks['9'] = SocketTask(completer: request, isSubscription: false);

    await client.ping();

    expect(statuses.last, ConnectionStatus.disconnected);
    expect(request.isCompleted, isFalse);
    expect(identical(client.socket, silent), isTrue);

    // The alive timer keeps firing; a ping with no socket must not read as a
    // pong and report connected, or the wallet never reconnects.
    client.socket = null;
    await client.ping();
    expect(statuses.last, ConnectionStatus.disconnected);
  });
}

// Accepts writes and never answers, like a socket whose reply is queued behind
// a 2MB range response.
class _SilentSocket implements ProxySocket {
  @override
  bool get isClosed => false;
  @override
  ProxyAddress get address => ProxyAddress(host: 'localhost', port: 1);
  @override
  Future<void> close() async {}
  @override
  void destroy() {}
  @override
  void write(String data) {}
  @override
  StreamSubscription<List<int>> listen(Function(Uint8List event) onData,
          {Function(Object error)? onError,
          Function()? onDone,
          bool cancelOnError = true}) =>
      const Stream<List<int>>.empty().listen(null);
}
