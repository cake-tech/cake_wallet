import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/core/address_resolver/nostr/nostr_user.dart';
import 'package:nostr_tools/nostr_tools.dart';
import 'dart:async' show Completer, TimeoutException, runZonedGuarded;

class NostrProfileHandler {
  /// Well-known public relays, queried when the author's NIP-05 relay hints
  /// are missing or none of them store the profile metadata event (kind 0).
  /// Ordered by measured kind-0 coverage for a broad set of popular profiles.
  static const fallbackRelays = <String>[
    'wss://relay.nos.social',
    'wss://nos.lol',
    'wss://offchain.pub',
    'wss://relay.damus.io',
    'wss://relay.nostr.band',
    'wss://purplepag.es',
    'wss://relay.primal.net',
  ];

  static final Nip05 _nip05 = Nip05();

  static Future<ProfilePointer?> queryProfile(String nip05Address) async {
    final profile = await _nip05.queryProfile(nip05Address);
    if (profile?.pubkey != null) {
      return profile;
    }
    return null;
  }

  static Future<UserMetadata?> processRelays(ProfilePointer profile) async {
    const int metaKind = 0;

    // Author-declared relays first, then well-known public relays.
    final seen = <String>{};
    final relays = <String>[
      ...?(profile.relays ?? const <String>[]),
      ...fallbackRelays,
    ].where((String relayUrl) => seen.add(relayUrl)).toList();

    // Query in parallel and finish as soon as the first relay returns the
    // metadata. _fetchInfoFromRelay swallows all errors and always completes,
    // so the whole step is bounded by _relayTimeout.
    final completer = Completer<UserMetadata?>();
    var remaining = relays.length;

    for (final relayUrl in relays) {
      _fetchInfoFromRelay(relayUrl, profile.pubkey, [metaKind]).then((data) {
        if (completer.isCompleted) return;
        if (data != null) {
          completer.complete(data);
        } else {
          remaining--;
          if (remaining == 0) completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  static const Duration _relayTimeout = Duration(seconds: 3);

  static Future<UserMetadata?> _fetchInfoFromRelay(
      String relayUrl, String userPubKey, List<int> kinds) async {
    // sanitize so obvious junk (like '#') doesn't reach connect()
    final clean = _sanitizeRelay(relayUrl);
    if (clean.isEmpty) return null;

    final result = Completer<UserMetadata?>();

    runZonedGuarded(() async {
      try {
        final relay = RelayApi(relayUrl: clean);

        final stream = await relay.connect().timeout(
          _relayTimeout,
          onTimeout: () {
            relay.close();
            throw TimeoutException('Relay connect timeout');
          },
        );

        relay.sub([
          Filter(kinds: kinds, authors: [userPubKey])
        ]);

        final sub = stream.listen((msg) {
          if (msg.type == 'EVENT' && !result.isCompleted) {
            try {
              final event = msg.message as Event;
              final jsonMap = json.decode(event.content) as Map<String, dynamic>;
              result.complete(UserMetadata.fromJson(jsonMap));
            } catch (_) {
              if (!result.isCompleted) result.complete(null);
            }
          }
        }, onError: (_) {
          if (!result.isCompleted) result.complete(null);
        }, onDone: () {
          if (!result.isCompleted) result.complete(null);
        });

        final value = await result.future.timeout(_relayTimeout, onTimeout: () => null);
        await sub.cancel();
        relay.close();
        if (!result.isCompleted) result.complete(value);
      } catch (_) {
        if (!result.isCompleted) result.complete(null);
      }
    }, (error, stack) {
      // swallow ALL async errors from the websocket layer (including "was not upgraded to websocket")
      if (!result.isCompleted) result.complete(null);
    });

    return result.future;
  }

  static String _sanitizeRelay(String url) {
    url = url.replaceFirst(RegExp(r'^https?://'), 'wss://');
    final uri = Uri.parse(url);
    return Uri(
      scheme: uri.scheme.isEmpty ? 'wss' : uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : 443,
    ).toString();
  }
}
