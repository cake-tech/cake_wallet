import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:cw_pivx/src/pivx_electrum_client.dart';
import 'package:cw_pivx/src/sapling/pivx_sapling_electrumx.dart';
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
    // connect() fails it, as getBlockRangeResult's whenComplete does.
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

  test('a range reply still downloading is not a stall', () async {
    CakeTor.instance = CakeTorDisabled();
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((s) => utf8.decoder
            .bind(s)
            .transform(const LineSplitter())
            .listen((line) async {
          final request = json.decode(line) as Map;
          if (request['method'] != 'blockchain.sapling.get_block_range') {
            s.write('${json.encode({'id': request['id'], 'result': null})}\n');
            return;
          }
          // Chunks 300ms apart: the reply ends at 900ms, past a 500ms clock
          // started at send, but never 500ms after the previous chunk.
          final reply = '${json.encode({
                'id': request['id'],
                'result': {
                  'start_height': 100,
                  'end_height': 100,
                  'complete': true,
                  'blocks': <dynamic>[],
                },
              })}\n';
          final third = reply.length ~/ 3;
          for (final chunk in [
            reply.substring(0, third),
            reply.substring(third, 2 * third),
            reply.substring(2 * third),
          ]) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            s.write(chunk);
            await s.flush();
          }
        }));

    final client = PivxElectrumClient()..useSSL = false;
    await client.connect(host: '127.0.0.1', port: server.port);
    await client.ping();
    final sapling = PIVXSaplingElectrumX(
        electrumClient: client,
        rangeStallTimeout: const Duration(milliseconds: 500));

    final reached = await sapling.syncBlocks(
      fromHeight: 100,
      toHeight: 100,
      batchSize: 1,
      parallelBatches: 1,
      onBatch: (_) async {},
    );

    expect(reached, isTrue);
    await client.close();
    await server.close();
  });
}
