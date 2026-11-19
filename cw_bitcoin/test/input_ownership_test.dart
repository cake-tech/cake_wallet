import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/input_ownership.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transactionHasOwnedInput', () {
    final priv = ECPrivate.random();
    final pub = priv.getPublic();
    final pubkeyHex = pub.toHex();
    const spentAmount = 1000;

    for (final network in SEGWIT_SUPPORTED_NETWORKS) {
      group('on ${network.value}', () {
        final ownedP2wpkh = pub.toP2wpkhAddress().toAddress(network);
        final ownedP2pkh = pub.toP2pkhAddress().toAddress(network);
        final ownedP2shP2wpkh = pub.toP2wpkhInP2sh().toAddress(network);
        final p2pkhScriptCode = pub.toP2pkhAddress().toScriptPubKey();

        TxOutput buildOutput() =>
            TxOutput(amount: BigInt.from(spentAmount), scriptPubKey: Script(script: ['OP_RETURN']));

        BtcTransaction txWithWitness(List<String> stack) => BtcTransaction(
              inputs: [TxInput(txId: '11' * 32, txIndex: 0)],
              outputs: [buildOutput()],
              witnesses: [TxWitnessInput(stack: stack)],
              hasSegwit: true,
            );

        BtcTransaction txWithScriptSig(List<String> pushes) {
          final input = TxInput(txId: '11' * 32, txIndex: 0, scriptSig: Script(script: pushes));
          return BtcTransaction(inputs: [input], outputs: [buildOutput()], hasSegwit: false);
        }

        // Real BIP143 witness signature for a P2WPKH/P2SH-P2WPKH spend of this input.
        final segwitDigest = txWithWitness([]).getTransactionSegwitDigit(
          txInIndex: 0,
          script: p2pkhScriptCode,
          amount: BigInt.from(spentAmount),
        );
        final witnessSigHex = priv.signInput(segwitDigest);

        // Real legacy signature for a P2PKH scriptSig spend of this input.
        final legacyDigest =
            txWithScriptSig([]).getTransactionDigest(txInIndex: 0, script: p2pkhScriptCode);
        final scriptSigHex = priv.signInput(legacyDigest);

        test('detects owned P2WPKH input via witness pubkey', () {
          final tx = txWithWitness([witnessSigHex, pubkeyHex]);
          expect(transactionHasOwnedInput(tx, {ownedP2wpkh}, network), true);
        });

        test('detects owned P2SH-P2WPKH input via witness pubkey', () {
          final tx = txWithWitness([witnessSigHex, pubkeyHex]);
          expect(transactionHasOwnedInput(tx, {ownedP2shP2wpkh}, network), true);
        });

        test('returns false when witness pubkey does not match any owned address', () {
          final tx = txWithWitness([witnessSigHex, pubkeyHex]);
          expect(
            transactionHasOwnedInput(tx, {'bc1qsomeotheraddressnotours00000000000'}, network),
            false,
          );
        });

        test('detects owned P2PKH input via scriptSig pubkey', () {
          final tx = txWithScriptSig([scriptSigHex, pubkeyHex]);
          expect(transactionHasOwnedInput(tx, {ownedP2pkh}, network), true);
        });

        test('returns false when legacy pubkey does not match any owned address', () {
          final tx = txWithScriptSig([scriptSigHex, pubkeyHex]);
          expect(
            transactionHasOwnedInput(tx, {'bc1qsomeotheraddressnotours00000000000'}, network),
            false,
          );
        });

        test('returns null (unknown) for taproot key-path witness (sig only)', () {
          final tx = txWithWitness([witnessSigHex]);
          expect(transactionHasOwnedInput(tx, {ownedP2wpkh}, network), null);
        });

        group('bare P2WSH 1-of-1', () {
          final ownedP2wsh = pub.toP2wshAddress().toAddress(network);
          final witnessScriptHex = pub.toP2wshRedeemScript().toHex();

          final p2wshDigest = txWithWitness([]).getTransactionSegwitDigit(
            txInIndex: 0,
            script: pub.toP2wshRedeemScript(),
            amount: BigInt.from(spentAmount),
          );
          final p2wshSigHex = priv.signInput(p2wshDigest);

          test('detects owned P2WSH input via embedded witness-script pubkey', () {
            final tx = txWithWitness(['', p2wshSigHex, witnessScriptHex]);
            expect(transactionHasOwnedInput(tx, {ownedP2wsh}, network), true);
          });

          test('returns false when P2WSH pubkey does not match any owned address', () {
            final tx = txWithWitness(['', p2wshSigHex, witnessScriptHex]);
            expect(
              transactionHasOwnedInput(tx, {'bc1qsomeotheraddressnotours00000000000'}, network),
              false,
            );
          });
        });
      });
    }
  });

  group('transactionHasOwnedInput on networks without segwit support', () {
    final priv = ECPrivate.random();
    final pub = priv.getPublic();
    final pubkeyHex = pub.toHex();

    BtcTransaction txWithScriptSig(List<String> pushes) {
      final input = TxInput(txId: '11' * 32, txIndex: 0, scriptSig: Script(script: pushes));
      final output =
          TxOutput(amount: BigInt.from(1000), scriptPubKey: Script(script: ['OP_RETURN']));
      return BtcTransaction(inputs: [input], outputs: [output], hasSegwit: false);
    }

    for (final network in SEGWIT_NOT_SUPPORTED_NETWORKS) {
      final ownedP2pkh = pub.toP2pkhAddress().toAddress(network);
      final p2pkhScriptCode = pub.toP2pkhAddress().toScriptPubKey();
      final digest =
          txWithScriptSig([]).getTransactionDigest(txInIndex: 0, script: p2pkhScriptCode);
      final sigHex = priv.signInput(digest);

      final tx = txWithScriptSig([sigHex, pubkeyHex]);

      test('detects owned P2PKH input on ${network.value} (no p2wpkh support)', () {
        expect(transactionHasOwnedInput(tx, {ownedP2pkh}, network), true);
      });

      test('returns false when legacy pubkey does not match any owned address', () {
        expect(
          transactionHasOwnedInput(tx, {'bc1qsomeotheraddressnotours00000000000'}, network),
          false,
        );
      });
    }
  });
}
