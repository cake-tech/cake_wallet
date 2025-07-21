import 'dart:convert';

import 'package:cake_wallet/nostr/nostr_user.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:nostr_tools/nostr_tools.dart';

class NostrProfileHandler {
  static final Nip05 _nip05 = Nip05();

  static const _fallbackRelays = {
    'wss://relay.damus.io',
    'wss://relay.snort.social',
    'wss://relay.nostr.band',
    'wss://nostr-pub.wellorder.net',
    'wss://nostr.bitcoiner.social'
  };

  static Future<ProfilePointer?> queryProfile(String nip05) async {
    try {
      final profile = await _nip05.queryProfile(nip05);
      return profile?.pubkey != null ? profile : null;
    } catch (e) {
      printV('[nostr] NIP-05 lookup error: $e');
      return null;
    }
  }

  static Future<UserMetadata?> fetchUserMetadata(ProfilePointer profile) async {
    final relays = {
      ...?profile.relays,
      ..._fallbackRelays,
    };

    for (final relayUrl in relays) {
      final meta = await _fetchInfoFromRelay(relayUrl, profile.pubkey, [0]);
      if (meta != null) return meta;
    }
    return null;
  }

  static Future<UserMetadata?> _fetchInfoFromRelay(
    String relayUrl,
    String pubkey,
    List<int> kinds,
  ) async {
    try {
      final relay = RelayApi(relayUrl: relayUrl);
      final stream = await relay.connect();

      relay.sub([
        Filter(kinds: kinds, authors: [pubkey])
      ]);

      await for (var message in stream) {
        if (message.type == 'EVENT') {
          final eventJson = json.decode((message.message as Event).content) as Map<String, dynamic>;
          relay.close();
          return UserMetadata.fromJson(eventJson);
        }
      }
      relay.close();
    } catch (e) {
      printV('[nostr] $relayUrl error: $e');
    }
    return null;
  }
}
