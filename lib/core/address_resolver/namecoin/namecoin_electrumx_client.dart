import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_models.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_script.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

abstract interface class NamecoinRpcTransport {
  Future<T> query<T>(
    NamecoinElectrumServer server,
    Future<T> Function(NamecoinRpcSession session) action,
  );
}

abstract interface class NamecoinRpcSession {
  Future<dynamic> call(String method, [List<Object> params = const []]);
}

class ProxyNamecoinRpcTransport implements NamecoinRpcTransport {
  ProxyNamecoinRpcTransport({
    this.connectionTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 10),
  });

  final Duration connectionTimeout;
  final Duration requestTimeout;

  @override
  Future<T> query<T>(
    NamecoinElectrumServer server,
    Future<T> Function(NamecoinRpcSession session) action,
  ) async {
    final socket = await ProxyWrapper().getSocksSocket(
      server.useSsl,
      server.host,
      server.port,
      connectionTimeout: connectionTimeout,
    );
    final session = _ProxyNamecoinRpcSession(socket, requestTimeout);

    try {
      return await action(session);
    } finally {
      await session.close();
    }
  }
}

class _ProxyNamecoinRpcSession implements NamecoinRpcSession {
  _ProxyNamecoinRpcSession(this._socket, this.requestTimeout) {
    _subscription = _socket.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  static const _maxBufferedResponse = 4 * 1024 * 1024;

  final ProxySocket _socket;
  final Duration requestTimeout;
  final List<int> _buffer = <int>[];
  late final StreamSubscription<List<int>> _subscription;
  Completer<dynamic>? _pending;
  int _nextId = 0;
  Object? _terminalError;

  @override
  Future<dynamic> call(String method, [List<Object> params = const []]) {
    if (_terminalError != null) return Future.error(_terminalError!);
    if (_pending != null) {
      return Future.error(
        const NamecoinRpcException('Concurrent ElectrumX requests are not supported'),
      );
    }

    final id = ++_nextId;
    final completer = Completer<dynamic>();
    _pending = completer;
    final request = json.encode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params});

    try {
      _socket.write('$request\n');
    } catch (error) {
      _pending = null;
      return Future.error(error);
    }

    return completer.future.timeout(requestTimeout).whenComplete(() {
      if (identical(_pending, completer)) _pending = null;
    });
  }

  void _onData(Uint8List event) {
    _buffer.addAll(event);
    if (_buffer.length > _maxBufferedResponse) {
      _fail(const NamecoinRpcException('ElectrumX response exceeded the size limit'));
      return;
    }

    var newline = _buffer.indexOf(0x0a);
    while (newline >= 0) {
      final lineBytes = _buffer.sublist(0, newline);
      _buffer.removeRange(0, newline + 1);

      final String line;
      try {
        line = utf8.decode(lineBytes).trim();
      } on FormatException {
        _fail(const NamecoinRpcException('ElectrumX response was not valid UTF-8'));
        return;
      }

      if (line.isNotEmpty) _handleLine(line);
      newline = _buffer.indexOf(0x0a);
    }
  }

  void _handleLine(String line) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;

    try {
      final dynamic decoded = json.decode(line);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['id']?.toString() != _nextId.toString()) return;

      final error = decoded['error'];
      if (error != null) {
        final message = error is Map<String, dynamic> ? error['message'] : error;
        pending.completeError(NamecoinRpcException(message?.toString() ?? 'ElectrumX RPC error'));
        return;
      }

      pending.complete(decoded['result']);
    } on FormatException catch (error) {
      pending.completeError(NamecoinRpcException('Invalid ElectrumX JSON response: $error'));
    }
  }

  void _onError(Object error) => _fail(error);

  void _onDone() => _fail(const NamecoinRpcException('ElectrumX connection closed'));

  void _fail(Object error) {
    _terminalError = error;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.completeError(error);
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _socket.close();
    _socket.destroy();
  }
}

class NamecoinElectrumXClient {
  NamecoinElectrumXClient({
    NamecoinRpcTransport? transport,
    this.servers = defaultNamecoinElectrumServers,
    this.lookupTimeout = const Duration(seconds: 110),
  }) : transport = transport ?? ProxyNamecoinRpcTransport();

  final NamecoinRpcTransport transport;
  final List<NamecoinElectrumServer> servers;
  final Duration lookupTimeout;

  Future<NamecoinLookup?> resolve(String name) async {
    final attempts = await Future.wait(
      servers.map((server) => _attempt(server, name)),
    ).timeout(lookupTimeout);
    final successful = attempts.whereType<_ServerSuccess>().toList();

    final groups = <String, List<_ServerSuccess>>{};
    for (final result in successful) {
      groups.putIfAbsent(result.consensusKey, () => []).add(result);
    }

    final orderedGroups = groups.values.toList()..sort((a, b) => b.length.compareTo(a.length));
    if (orderedGroups.isEmpty ||
        orderedGroups.first.length < 2 ||
        (orderedGroups.length > 1 && orderedGroups[0].length == orderedGroups[1].length)) {
      throw const NamecoinResolutionException(
        'ElectrumX servers did not agree on a current Namecoin value',
      );
    }

    final winner = orderedGroups.first;
    final expired = winner.first.expired;
    if (expired != null) throw expired;
    return winner.first.lookup;
  }

  Future<_ServerAttempt> _attempt(NamecoinElectrumServer server, String name) async {
    try {
      final lookup = await lookupOnServer(server, name);
      return _ServerSuccess(lookup: lookup);
    } on NamecoinExpiredException catch (error) {
      return _ServerSuccess(expired: error);
    } catch (error) {
      printV('[namecoin] ${server.label} lookup failed: $error');
      return _ServerFailure(error);
    }
  }

  Future<NamecoinLookup?> lookupOnServer(NamecoinElectrumServer server, String name) {
    return transport.query(server, (session) async {
      await session.call('server.version', ['CakeWalletNamecoin/1.0', '1.4.3']);
      final historyResult = await session.call('blockchain.scripthash.get_history', [
        NamecoinScript.scriptHash(name),
      ]);
      final history = _parseHistory(historyResult);
      if (history.isEmpty) return null;

      final confirmed = history.where((entry) => entry.height > 0).toList();
      if (confirmed.isEmpty) return null;
      final latest = confirmed.last;

      final transactionResult = await session.call('blockchain.transaction.get', [
        latest.txid,
        true,
      ]);
      if (transactionResult is! Map<String, dynamic>) {
        throw const NamecoinRpcException('ElectrumX returned a non-verbose name transaction');
      }
      final nameValue = NamecoinScript.fromVerboseTransaction(transactionResult, name);
      if (nameValue == null) {
        throw const NamecoinRpcException('Name transaction did not contain the requested name');
      }

      final tipResult = await session.call('blockchain.headers.subscribe');
      final tipHeight = _parseTipHeight(tipResult);
      if (tipHeight == null || latest.height > tipHeight + 1) {
        throw const NamecoinRpcException('ElectrumX returned an invalid chain tip');
      }

      final expiresIn = NamecoinScript.nameExpireDepth - (tipHeight - latest.height);
      if (expiresIn <= 0) throw NamecoinExpiredException(name);

      return NamecoinLookup(
        name: name,
        value: nameValue.value,
        txid: latest.txid,
        height: latest.height,
        expiresIn: expiresIn,
      );
    });
  }

  List<_NameHistoryEntry> _parseHistory(dynamic result) {
    if (result is! List) throw const NamecoinRpcException('Invalid name history response');
    final entries = <_NameHistoryEntry>[];

    for (final item in result) {
      if (item is! Map<String, dynamic>) continue;
      final txid = item['tx_hash'];
      final height = item['height'];
      if (txid is String && height is int) entries.add(_NameHistoryEntry(txid, height));
    }

    final confirmed = entries.where((entry) => entry.height > 0).toList()
      ..sort((a, b) => a.height.compareTo(b.height));
    final unconfirmed = entries.where((entry) => entry.height <= 0);
    return [...confirmed, ...unconfirmed];
  }

  int? _parseTipHeight(dynamic result) {
    if (result is Map<String, dynamic> && result['height'] is int) return result['height'] as int;
    if (result is List && result.isNotEmpty) return _parseTipHeight(result.last);
    return null;
  }
}

class _NameHistoryEntry {
  const _NameHistoryEntry(this.txid, this.height);

  final String txid;
  final int height;
}

sealed class _ServerAttempt {}

class _ServerFailure implements _ServerAttempt {
  const _ServerFailure(this.error);

  final Object error;
}

class _ServerSuccess implements _ServerAttempt {
  _ServerSuccess({this.lookup, this.expired});

  final NamecoinLookup? lookup;
  final NamecoinExpiredException? expired;

  String get consensusKey {
    if (expired != null) return 'expired';
    final value = lookup;
    if (value == null) return 'not-found';
    return 'found:${value.name}:${value.txid}:${value.height}:${value.value}';
  }
}
