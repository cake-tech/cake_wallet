import 'package:cw_bitcoin/electrum.dart';

/// Sapling ranges share the wallet socket, and the server can build a multi-MB
/// range silently for longer than a ping takes to time out. The base client
/// then drops the socket and aborts the fetch, so pings pause while a range is
/// held. A dead socket still drops on the first ping after the hold ends.
class PivxElectrumClient extends ElectrumClient {
  DateTime? _holdUntil;

  void holdSocketFor(Duration duration) {
    final until = DateTime.now().add(duration);
    final current = _holdUntil;
    if (current == null || until.isAfter(current)) _holdUntil = until;
  }

  @override
  Future<void> ping() async {
    final until = _holdUntil;
    if (until != null && DateTime.now().isBefore(until)) return;
    return super.ping();
  }
}
