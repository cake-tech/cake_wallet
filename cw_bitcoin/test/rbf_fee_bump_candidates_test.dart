import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:test/test.dart';

const _address = 'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx';
const _txA = 'aa';
const _txB = 'bb';

BitcoinUnspent _coin({
  String hash = _txB,
  int vout = 0,
  int? confirmations = 3,
  bool isSending = true,
  bool isFrozen = false,
}) {
  final record = BitcoinAddressRecord(
    _address,
    index: 0,
    type: SegwitAddresType.p2wpkh,
    network: BitcoinNetwork.testnet,
  );
  final coin = BitcoinUnspent(record, hash, 10000, vout);
  coin.confirmations = confirmations;
  coin.isSending = isSending;
  coin.isFrozen = isFrozen;
  return coin;
}

void main() {
  group('rbfFeeBumpCandidates', () {
    test('keeps confirmed, sendable, unfrozen coins', () {
      final coin = _coin();
      final result = rbfFeeBumpCandidates(unspent: [coin], originalOutpoints: const {});
      expect(result, [coin]);
    });

    test('drops unconfirmed coins, since BIP125 rejects new unconfirmed inputs in a replacement', () {
      final result = rbfFeeBumpCandidates(
        unspent: [_coin(confirmations: 0)],
        originalOutpoints: const {},
      );
      expect(result, isEmpty);
    });

    test('treats a coin with unknown confirmations as unconfirmed instead of throwing', () {
      final result = rbfFeeBumpCandidates(
        unspent: [_coin(confirmations: null)],
        originalOutpoints: const {},
      );
      expect(result, isEmpty);
    });

    test('drops frozen coins and coins marked not sending', () {
      final result = rbfFeeBumpCandidates(
        unspent: [
          _coin(vout: 0, isFrozen: true),
          _coin(vout: 1, isSending: false),
        ],
        originalOutpoints: const {},
      );
      expect(result, isEmpty);
    });

    test('drops the replaced transaction own inputs so they are never added twice', () {
      final ownInput = _coin(hash: _txA, vout: 1);
      final otherCoin = _coin(hash: _txB, vout: 0);
      final result = rbfFeeBumpCandidates(
        unspent: [ownInput, otherCoin],
        originalOutpoints: {'$_txA:1'},
      );
      expect(result, [otherCoin]);
    });

    test('matches original inputs by both hash and vout', () {
      final sameHashOtherVout = _coin(hash: _txA, vout: 0);
      final result = rbfFeeBumpCandidates(
        unspent: [sameHashOtherVout],
        originalOutpoints: {'$_txA:1'},
      );
      expect(result, [sameHashOtherVout]);
    });

    test('returns nothing when no coin qualifies', () {
      final result = rbfFeeBumpCandidates(
        unspent: [_coin(confirmations: 0), _coin(vout: 1, isFrozen: true)],
        originalOutpoints: const {},
      );
      expect(result, isEmpty);
    });
  });
}
