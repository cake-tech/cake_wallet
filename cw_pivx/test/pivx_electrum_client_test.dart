import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:cw_pivx/src/pivx_electrum_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a range hold does not survive a reconnect', () async {
    CakeTor.instance = CakeTorDisabled();
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((s) => utf8.decoder
            .bind(s)
            .transform(const LineSplitter())
            .listen((line) {
          final id = (json.decode(line) as Map)['id'];
          if (id != 'range') s.write('${json.encode({'id': id, 'result': null})}\n');
        }));

    final client = PivxElectrumClient()..useSSL = false;
    final statuses = <ConnectionStatus>[];
    client.onConnectionStatusChange = statuses.add;
    await client.connect(host: '127.0.0.1', port: server.port);

    // A range in flight holds the socket; its cleanup re-arms the hold when
    // connect() fails it, as getBlockRangeResult's finally does.
    final range = Completer<dynamic>();
    client.tasks['range'] = SocketTask(completer: range, isSubscription: false);
    client.holdSocketFor(const Duration(minutes: 1));
    unawaited(range.future
        .catchError((Object _) => null)
        .whenComplete(() => client.holdSocketFor(const Duration(minutes: 1))));

    await client.connect(host: '127.0.0.1', port: server.port);
    await client.ping();
    expect(statuses.last, ConnectionStatus.connected);

    await client.close();
    await server.close();
  });
}
