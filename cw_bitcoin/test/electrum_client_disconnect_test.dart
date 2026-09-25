import 'dart:async';
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

  // Regression: PIVX Sapling waves put megabytes ahead of server.ping on the
  // one socket. The ping timed out, the client destroyed the socket under the
  // running fetch, and shield sync looped at the same height.
  test('ping timeout keeps the socket while bytes are still arriving',
      () async {
    final client = ElectrumClient();
    final statuses = <ConnectionStatus>[];
    client.onConnectionStatusChange = statuses.add;
    client.socket = _SilentSocket();

    final ping = client.ping(); // no reply: callWithTimeout gives up after 5s
    await Future<void>.delayed(const Duration(seconds: 3));
    client.markSocketData(); // response bytes still landing mid-wait
    await ping;

    expect(statuses, isNot(contains(ConnectionStatus.disconnected)));
    expect(client.socket, isNotNull);
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

// Regression: a half-open socket still reports isConnected, so a failed ping
// used to flag disconnected without failing in-flight calls.
void _halfOpenPingTest() {
  test('ping timeout on a silent socket fails pending calls and drops it',
      () async {
    final client = ElectrumClient();
    final statuses = <ConnectionStatus>[];
    client.onConnectionStatusChange = statuses.add;
    client.socket = _SilentSocket();
    final request = Completer<dynamic>();
    client.tasks['9'] = SocketTask(completer: request, isSubscription: false);
    final requestFuture = request.future.catchError((Object _) => null);

    await client.ping();

    expect(request.isCompleted, isTrue);
    expect(client.socket, isNull);
    await requestFuture;

    // The alive timer keeps firing; a ping with no socket must not read as a
    // pong and report connected, or the wallet never reconnects.
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
