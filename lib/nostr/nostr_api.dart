import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/nostr/nostr_user.dart';
import 'package:nostr_tools/nostr_tools.dart';
import 'dart:async' show Completer, TimeoutException, runZonedGuarded;

class NostrProfileHandler {
  static final relayToDomainMap = {
    'relay.snort.social': 'snort.social',
  };

  static final Nip05 _nip05 = Nip05();

  static Future<ProfilePointer?> queryProfile(String nip05Address) async {
    final profile = await _nip05.queryProfile(nip05Address);
    if (profile?.pubkey != null && profile?.relays?.isNotEmpty == true) {
      return profile;
    }
    return null;
  }

  static Future<UserMetadata?> processRelays(
    ProfilePointer profile,
    String nip05Address,
  ) async {
    final userDomain = _extractDomain(nip05Address);
    const int metaKind = 0;

    // Domain-matched relays first
    for (final String relayUrl in profile.relays ?? []) {
      final relayDomain =
          relayToDomainMap[_getDomainFromRelayUrl(relayUrl)] ?? _getDomainFromRelayUrl(relayUrl);

      if (relayDomain == userDomain) {
        final data = await _fetchInfoFromRelay(relayUrl, profile.pubkey, [metaKind]);
        if (data != null) return data;
      }
    }

    // Then try every remaining relay
    for (final String relayUrl in profile.relays ?? []) {
      final data = await _fetchInfoFromRelay(relayUrl, profile.pubkey, [metaKind]);
      if (data != null) return data;
    }

    // Nothing found
    return null;
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

  static String _extractDomain(String nip05) => nip05.split('@').last;

  static String _getDomainFromRelayUrl(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }
}
