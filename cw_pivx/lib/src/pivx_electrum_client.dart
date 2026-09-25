import 'package:cw_bitcoin/electrum.dart';

/// Sapling ranges share the wallet socket, and the server can build a multi-MB
/// range silently for longer than a ping takes to time out. The base client
/// then drops the socket and aborts the fetch, so pings pause while a range is
/// held. A dead socket still drops on the first ping after the hold ends.
class PivxElectrumClient extends ElectrumClient {
  DateTime? _holdUntil;

  void holdSocketFor(Duration duration) {
    // connect() detaches the socket before the failed range's cleanup re-arms
    // the hold; with no socket there is nothing to hold.
    if (socket == null) return;
    final until = DateTime.now().add(duration);
    final current = _holdUntil;
    if (current == null || until.isAfter(current)) _holdUntil = until;
  }

  // A hold protects a range on the old socket, which connect() fails. Left in
  // place it skips the first keep-alive ping, the only thing that moves the new
  // socket off connecting, and the wallet does not retry connecting.
  @override
  Future<void> connect({required String host, required int port}) {
    _holdUntil = null;
    return super.connect(host: host, port: port);
  }

  @override
  Future<void> ping() async {
    final until = _holdUntil;
    if (until != null && DateTime.now().isBefore(until)) return;
    return super.ping();
  }
}
