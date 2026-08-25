import 'dart:async';

import 'package:cw_bitcoin/electrum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  // Regression: a dropped/half-open socket must not leave an in-flight `call`
  // hanging forever. That dangling completer previously wedged PIVX shielded
  // sync — the sync task never returned, its in-progress guard stayed set, and
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

  test('failPendingRequests is safe with no pending tasks', () {
    final client = ElectrumClient();
    expect(client.failPendingRequests, returnsNormally);
  });

  // Wiring: an explicit close() (node switching / reconnect teardown) must
  // unblock in-flight requests even if the socket never fires onDone — otherwise
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
}
