import 'package:cake_wallet/core/address_resolver/nostr/nostr_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NostrProfileHandler.fallbackRelays', () {
    test('is non-empty and contains no duplicates', () {
      expect(NostrProfileHandler.fallbackRelays, isNotEmpty);
      expect(
        NostrProfileHandler.fallbackRelays.toSet().length,
        NostrProfileHandler.fallbackRelays.length,
      );
    });

    test('leads with relays measured to cover popular profiles', () {
      expect(
        NostrProfileHandler.fallbackRelays.first,
        'wss://relay.nos.social',
      );
      expect(NostrProfileHandler.fallbackRelays, contains('wss://nos.lol'));
      expect(NostrProfileHandler.fallbackRelays, contains('wss://offchain.pub'));
      expect(NostrProfileHandler.fallbackRelays, contains('wss://relay.primal.net'));
    });
  });
}
