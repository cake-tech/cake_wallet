import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/nostr/nostr_user.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:nostr_tools/nostr_tools.dart';

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
    try {
      final relay = RelayApi(relayUrl: _sanitizeRelay(relayUrl));

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

      final completer = Completer<UserMetadata?>();

      final sub = stream.listen((msg) {
        if (msg.type == 'EVENT' && !completer.isCompleted) {
          final event = msg.message as Event;
          final jsonMap = json.decode(event.content) as Map<String, dynamic>;
          completer.complete(UserMetadata.fromJson(jsonMap));
        }
      }, onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      }, onDone: () {
        if (!completer.isCompleted) completer.complete(null);
      });

      final result = await completer.future.timeout(_relayTimeout, onTimeout: () => null);

      await sub.cancel();
      relay.close();
      return result;
    } catch (e) {
      printV('[!] Error with relay $relayUrl: $e');
      return null;
    }
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
