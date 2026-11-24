import 'dart:convert';

import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_electrumx_client.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_models.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const name = 'd/testls';
  const servers = [
    NamecoinElectrumServer('one.test', 50002),
    NamecoinElectrumServer('two.test', 50002),
    NamecoinElectrumServer('three.test', 50002),
    NamecoinElectrumServer('four.test', 50002),
  ];

  NamecoinElectrumXClient client(Map<String, _Reply> replies) => NamecoinElectrumXClient(
        transport: _FakeTransport(replies),
        servers: servers.where((server) => replies.containsKey(server.host)).toList(),
      );

  test('returns a value agreed by the unique leading server group', () async {
    final resolver = client({
      'one.test': _Reply.value(name: name, value: 'first'),
      'two.test': _Reply.value(name: name, value: 'first'),
      'three.test': _Reply.value(name: name, value: 'other'),
    });

    final result = await resolver.resolve(name);
    expect(result?.value, 'first');
    expect(result?.txid, 'tx-first');
    expect(result?.height, 100);
    expect(result?.expiresIn, 35900);
  });

  test('rejects a tie even when every server returns a valid value', () async {
    final resolver = client({
      'one.test': _Reply.value(name: name, value: 'first'),
      'two.test': _Reply.value(name: name, value: 'first'),
      'three.test': _Reply.value(name: name, value: 'other'),
      'four.test': _Reply.value(name: name, value: 'other'),
    });

    expect(resolver.resolve(name), throwsA(isA<NamecoinResolutionException>()));
  });

  test('does not accept a single server or all unavailable servers', () async {
    final one = client({'one.test': _Reply.value(name: name, value: 'first')});
    expect(one.resolve(name), throwsA(isA<NamecoinResolutionException>()));

    final unavailable = client({'one.test': _Reply.error(), 'two.test': _Reply.error()});
    expect(unavailable.resolve(name), throwsA(isA<NamecoinResolutionException>()));
  });

  test('requires agreement on txid, height, and value, not just the value', () async {
    final resolver = client({
      'one.test': _Reply.value(name: name, value: 'same', txid: 'one'),
      'two.test': _Reply.value(name: name, value: 'same', txid: 'two'),
    });

    expect(resolver.resolve(name), throwsA(isA<NamecoinResolutionException>()));
  });

  test('returns null only when not-found is the unique leading consensus', () async {
    final resolver = client({'one.test': _Reply.notFound(), 'two.test': _Reply.notFound()});
    expect(await resolver.resolve(name), isNull);
  });

  test('fails closed when found and not-found responses tie', () async {
    final resolver = client({
      'one.test': _Reply.value(name: name, value: 'first'),
      'two.test': _Reply.notFound(),
    });

    expect(resolver.resolve(name), throwsA(isA<NamecoinResolutionException>()));
  });

  test('rejects an expired name and ignores unconfirmed-only history', () async {
    final expired = client({
      'one.test': _Reply.value(name: name, value: 'old', tipHeight: 36100),
      'two.test': _Reply.value(name: name, value: 'old', tipHeight: 36100),
    });
    expect(expired.resolve(name), throwsA(isA<NamecoinExpiredException>()));

    final unconfirmed = client({
      'one.test': _Reply.notFound(history: [
        {'tx_hash': 'mempool', 'height': 0},
      ]),
      'two.test': _Reply.notFound(history: [
        {'tx_hash': 'mempool', 'height': -1},
      ]),
    });
    expect(await unconfirmed.resolve(name), isNull);
  });

  test('treats malformed transactions and tips as failed server attempts', () async {
    final malformed = client({
      'one.test': _Reply(transaction: {'vout': []}),
      'two.test': _Reply(tipHeight: null),
    });

    expect(malformed.resolve(name), throwsA(isA<NamecoinResolutionException>()));
  });

  test('uses the Namecoin script index and requests verbose transactions', () async {
    final transport = _FakeTransport({
      'one.test': _Reply.value(name: name, value: 'first'),
      'two.test': _Reply.value(name: name, value: 'first'),
    });
    final resolver = NamecoinElectrumXClient(
      transport: transport,
      servers: [servers[0], servers[1]],
    );

    await resolver.resolve(name);
    for (final session in transport.sessions) {
      expect(session.methods, [
        'server.version',
        'blockchain.scripthash.get_history',
        'blockchain.transaction.get',
        'blockchain.headers.subscribe',
      ]);
      expect(session.calls[1].params, [
        'b519574e96740a4b3627674a0708e71a73e654a95117fc828b8e177a0579ab42',
      ]);
      expect(session.calls[2].params, ['tx-first', true]);
    }
  });
}

class _Reply {
  _Reply({
    this.history = const [
      {'tx_hash': 'tx-first', 'height': 100},
    ],
    Map<String, dynamic>? transaction,
    this.tipHeight = 200,
    this.error,
  }) : transaction = transaction ?? _transaction('53${_push('d/testls')}${_push('first')}6d756a');

  factory _Reply.value({
    required String name,
    required String value,
    String? txid,
    int height = 100,
    int tipHeight = 200,
  }) =>
      _Reply(
        history: [
          {'tx_hash': txid ?? 'tx-$value', 'height': height},
        ],
        transaction: _transaction('53${_push(name)}${_push(value)}6d756a'),
        tipHeight: tipHeight,
      );

  factory _Reply.notFound({List<Map<String, dynamic>> history = const []}) =>
      _Reply(history: history);

  factory _Reply.error() => _Reply(error: 'connection failed');

  final List<Map<String, dynamic>> history;
  final Map<String, dynamic> transaction;
  final int? tipHeight;
  final String? error;
}

class _FakeTransport implements NamecoinRpcTransport {
  _FakeTransport(this.replies);

  final Map<String, _Reply> replies;
  final sessions = <_FakeSession>[];

  @override
  Future<T> query<T>(
    NamecoinElectrumServer server,
    Future<T> Function(NamecoinRpcSession session) action,
  ) {
    final reply = replies[server.host];
    if (reply == null) throw StateError('Unexpected server: ${server.host}');
    final session = _FakeSession(reply);
    sessions.add(session);
    return action(session);
  }
}

class _FakeSession implements NamecoinRpcSession {
  _FakeSession(this.reply);

  final _Reply reply;
  final calls = <({String method, List<Object> params})>[];

  List<String> get methods => calls.map((call) => call.method).toList();

  @override
  Future<dynamic> call(String method, [List<Object> params = const []]) async {
    calls.add((method: method, params: params));
    if (reply.error != null) throw NamecoinRpcException(reply.error!);

    switch (method) {
      case 'server.version':
        return ['test', '1.4.3'];
      case 'blockchain.scripthash.get_history':
        return reply.history;
      case 'blockchain.transaction.get':
        return reply.transaction;
      case 'blockchain.headers.subscribe':
        return reply.tipHeight == null ? null : {'height': reply.tipHeight};
      default:
        throw StateError('Unexpected RPC: $method');
    }
  }
}

Map<String, dynamic> _transaction(String scriptHex) => {
      'vout': [
        {
          'scriptPubKey': {'hex': scriptHex},
        },
      ],
    };

String _push(String value) {
  final bytes = utf8.encode(value);
  return '${bytes.length.toRadixString(16).padLeft(2, '0')}${hex.encode(bytes)}';
}
