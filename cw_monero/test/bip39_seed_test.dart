import 'package:cw_monero/bip39_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Exodus Style bip39", () {
    group("Test Wallet 1", () {
      final bip39Seed = 'meadow tip best belt boss eyebrow control affair eternal piece very shiver';
      final expectedLegacySeed0 = "tasked eight afraid laboratory tail feline rift reinvest vane cafe bailed foggy dormant paper jigsaw king hazard suture king dapper dummy jolted dating dwindling king";
      final expectedLegacySeed1 = "palace pairing axes mohawk rekindle excess awful juvenile shipped talent nibs efficient dapper biggest swung fight pact innocent emerge issued titans affair nearby noises emerge";

      test("Get legacy Seed from bip39", () {
        final legacySeed = getLegacySeedFromBip39(bip39Seed);
        expect(legacySeed, expectedLegacySeed0);
      });

      test("Get legacy Seed from bip39 with account index", () {
        final legacySeed = getLegacySeedFromBip39(bip39Seed, accountIndex: 1);
        expect(legacySeed, expectedLegacySeed1);
      });
    });

    group("Test Wallet 2", () {
      final bip39Seed = "color ranch color remove subway public water embrace before begin liberty fault";
      final expectedLegacySeed0 = "somewhere problems gauze gigantic intended foxes upcoming saved waffle pipeline lurk bogeys empty wipeout abbey italics novelty tucks rafts elite lunar obnoxious awful bugs elite";
      final expectedLegacySeed1 = "playful toxic wildly eluded mesh fainted february mugged maps repent vigilant hitched seventh threaten clue fetches sample diet number alkaline future cottage tuition vegan alkaline";

      test("Get legacy Seed from bip39", () {
        final legacySeed = getLegacySeedFromBip39(bip39Seed);
        expect(legacySeed, expectedLegacySeed0);
      });

      test("Get legacy Seed from bip39 with account index", () {
        final legacySeed = getLegacySeedFromBip39(bip39Seed, accountIndex: 1);
        expect(legacySeed, expectedLegacySeed1);
      });
    });

  });
}
