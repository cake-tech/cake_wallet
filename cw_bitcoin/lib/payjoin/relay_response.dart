import 'dart:typed_data';

import 'package:payjoin/payjoin.dart' as pj;

/// Normalized wrapper for an OHTTP-relayed request/response pair returned by
/// the mailroom. Used by both sender and receiver workers to carry the bytes
/// received from the relay alongside the OHTTP context needed to decrypt any
/// subsequent state-machine response.
class PayjoinRelayResponse {
  PayjoinRelayResponse({
    required this.bodyBytes,
    required this.ohttpCtx,
    required this.requestUrl,
  });

  final Uint8List bodyBytes;
  final pj.ClientResponse ohttpCtx;
  final String requestUrl;
}
