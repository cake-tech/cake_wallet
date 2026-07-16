import 'dart:io';
import 'dart:math';

import 'package:payjoin/http.dart' as pj_http;
import 'package:payjoin/payjoin.dart' as pj;

/// Stateless relay/directory chooser plus the directory OHTTP-key fetch.
///
/// No failure memory is kept between operations: every call re-probes the
/// full configured pools, so a broken relay costs one wasted request per
/// operation instead of poisoning a shared pool for unrelated sessions.
/// Bookkeeping that needs scope (e.g. "every relay has been tried against
/// this directory") lives in local variables of the operation that needs
/// it, passed back in via [Set] parameters, and evaporates when the
/// operation ends.
class MailroomManager {
  MailroomManager({
    required this.relayUrls,
    required this.directoryUrls,
  });

  List<String> relayUrls;
  List<String> directoryUrls;

  void setConfig({
    required List<String> relays,
    required List<String> directories,
  }) {
    relayUrls = relays;
    directoryUrls = directories;
  }

  /// Picks a random relay, optionally excluding relays hosted at
  /// [excludeHost] and/or the members of [exclude].
  ///
  /// When [excludeHost] is given (e.g. the directory the request targets),
  /// relays operated by that host are skipped entirely so a single operator
  /// can't hold both OHTTP roles and link the client to the payjoin payload.
  /// Both exclusions are hard constraints over the configured pool: if
  /// nothing remains, a StateError is thrown. An empty pool is a
  /// configuration problem, not a transient failure, so callers let it
  /// propagate rather than retry.
  String chooseRelay({String? excludeHost, Set<String>? exclude}) {
    var available = relayUrls
        .where((r) => !(exclude?.contains(r) ?? false))
        .toList();
    if (excludeHost != null) {
      available = available
          .where((r) => Uri.parse(r).host != excludeHost)
          .toList();
    }
    if (available.isEmpty) {
      throw StateError('No valid relays available');
    }
    return available[Random.secure().nextInt(available.length)];
  }

  /// Picks a random directory, excluding the members of [exclude].
  ///
  /// Throws a StateError when nothing remains — callers use that to detect
  /// "every directory has been tried" within a single operation.
  String chooseDirectory({Set<String>? exclude}) {
    final available = directoryUrls
        .where((d) => !(exclude?.contains(d) ?? false))
        .toList();
    if (available.isEmpty) {
      throw StateError('No valid directories available');
    }
    return available[Random.secure().nextInt(available.length)];
  }

  /// Fetches OHTTP keys from [directory] by tunneling through relays.
  ///
  /// Failover is relay-first and scoped to this call: every relay gets one
  /// chance (tracked in a local set, so the next pick avoids it for the
  /// rest of THIS fetch only), preferring relays hosted elsewhere than the
  /// directory. Only once the whole pool has been tried against
  /// [directory] does the thrown [StateError] blame the pair — the caller
  /// moves on to the next directory with a completely fresh relay pool.
  Future<pj.OhttpKeys> fetchOhttpKeysFromDirectory(String directory) async {
    final attemptedRelays = <String>{};
    final excludeHost = Uri.parse(directory).host;
    while (true) {
      // StateError here means every host-distinct relay has had its chance
      // against this directory.
      final relay =
          chooseRelay(excludeHost: excludeHost, exclude: attemptedRelays);
      attemptedRelays.add(relay);
      try {
        return await pj_http.fetchOhttpKeys(
          ohttpRelayUrl: relay,
          directoryUrl: directory,
        );
      } on IOException {
        // Transport failure of any kind — socket, TLS handshake, HTTP
        // protocol, timeout. Relay-first: try the next relay within this
        // fetch. If every relay sees the same failure, the directory is
        // burned by pool exhaustion in chooseRelay above.
      }
    }
  }
}
