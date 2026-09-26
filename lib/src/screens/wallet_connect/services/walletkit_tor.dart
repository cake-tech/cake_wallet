import 'dart:async';

import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:reown_core/relay_client/websocket/i_http_client.dart';
import 'package:reown_core/relay_client/websocket/i_websocket_handler.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';

/// Returns whether WalletConnect traffic has to go through Tor.
typedef TorRequired = bool Function();

const _torStartTimeout = Duration(seconds: 60);

bool get _isTorReady => CakeTor.instance!.started && CakeTor.instance!.port != -1;

/// Blocks until Tor is usable when the user requires it, so that nothing leaks
/// over clearnet while Tor is still starting up.
Future<void> _ensureTorReady(TorRequired torRequired) async {
  if (!torRequired() || _isTorReady) {
    return;
  }

  final deadline = DateTime.now().add(_torStartTimeout);
  while (!_isTorReady) {
    if (DateTime.now().isAfter(deadline)) {
      throw const ReownCoreError(
        code: -1,
        message: 'Tor is enabled but not running, refusing to connect over clearnet',
      );
    }
    await Future.delayed(const Duration(milliseconds: 250));
  }
}

/// Reown HTTP client (verify, echo and events APIs) that routes through [ProxyWrapper].
class WalletKitHttpClient extends IHttpClient {
  const WalletKitHttpClient(this._torRequired);

  final TorRequired _torRequired;

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    await _ensureTorReady(_torRequired);
    return ProxyWrapper().get(clearnetUri: url, headers: headers);
  }

  @override
  Future<Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    await _ensureTorReady(_torRequired);
    return ProxyWrapper().post(clearnetUri: url, headers: headers, body: body as String?);
  }

  @override
  Future<Response> delete(Uri url, {Map<String, String>? headers}) async {
    await _ensureTorReady(_torRequired);
    return ProxyWrapper().delete(clearnetUri: url, headers: headers);
  }
}

/// Reown relay WebSocket handler that connects through the Tor SOCKS proxy when
/// Tor is running. Mirrors reown_core's default `WebSocketHandler`.
class WalletKitWebSocketHandler implements IWebSocketHandler {
  WalletKitWebSocketHandler(this._torRequired);

  final TorRequired _torRequired;

  String? _url;
  @override
  String? get url => _url;

  IOWebSocketChannel? _socket;

  @override
  int? get closeCode => _socket?.closeCode;
  @override
  String? get closeReason => _socket?.closeReason;

  StreamChannel<String>? _channel;
  @override
  StreamChannel<String>? get channel => _channel;

  @override
  Future<void> get ready => _socket!.ready;

  @override
  Future<void> setup({required String url}) async {
    _url = url;

    await close();
  }

  @override
  Future<void> connect() async {
    await _ensureTorReady(_torRequired);

    try {
      var uri = Uri.parse('$url&useOnCloseEvent=true');
      // Dart reports port 0 for ws/wss URIs without an explicit port. HttpClient
      // maps 0 to the default port, but the SOCKS connection factory passes it
      // through as-is and Tor refuses to connect to port 0.
      if (!uri.hasPort) {
        uri = uri.replace(port: uri.isScheme('wss') ? 443 : 80);
      }
      _socket = IOWebSocketChannel.connect(
        uri,
        // ignore: deprecated_member_use
        customClient: ProxyWrapper().getHttpClient(),
      );
    } catch (e) {
      throw ReownCoreError(
        code: -1,
        message: 'No internet connection: ${e.toString()}',
      );
    }

    // Split the socket into broadcast streams so the channel supports multiple
    // listeners, same as the default handler.
    final inputController = StreamController<String>.broadcast(sync: true);
    final outputController = StreamController<String>.broadcast(sync: true);

    _socket!.stream.cast<String>().listen(
          inputController.add,
          onError: (Object error) => inputController.addError(error),
          onDone: inputController.close,
        );

    outputController.stream.listen(
      (data) => _socket!.sink.add(data),
      onError: (Object error) => _socket?.sink.addError(error),
      onDone: () => _socket?.sink.close(),
    );

    _channel = StreamChannel(inputController.stream, outputController.sink);

    await _socket!.ready;
  }

  @override
  Future<void> close() async {
    try {
      if (_socket != null) {
        await _socket?.sink.close();
      }
    } catch (_) {}
    _socket = null;
  }

  @override
  String toString() {
    return 'WalletKitWebSocketHandler{url: $url, _socket: $_socket, _channel: $_channel}';
  }
}
