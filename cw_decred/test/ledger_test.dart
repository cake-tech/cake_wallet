import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:cw_decred/ledger.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

void main() {
  group('Utility Functions', () {
    group('uint8ListToHex', () {
      test('converts empty list to empty string', () {
        expect(uint8ListToHex(Uint8List(0)), '');
      });

      test('converts single byte correctly', () {
        expect(uint8ListToHex(Uint8List.fromList([0])), '00');
        expect(uint8ListToHex(Uint8List.fromList([255])), 'ff');
        expect(uint8ListToHex(Uint8List.fromList([16])), '10');
      });

      test('converts multiple bytes correctly', () {
        expect(
          uint8ListToHex(Uint8List.fromList([0xde, 0xad, 0xbe, 0xef])),
          'deadbeef',
        );
      });

      test('pads single digit hex values with zero', () {
        expect(
          uint8ListToHex(Uint8List.fromList([1, 2, 3])),
          '010203',
        );
      });

      test('handles all byte values 0-255', () {
        for (int i = 0; i <= 255; i++) {
          final result = uint8ListToHex(Uint8List.fromList([i]));
          expect(result.length, 2);
          expect(int.parse(result, radix: 16), i);
        }
      });
    });

    group('hexToUint8List', () {
      test('converts empty string to empty list', () {
        expect(hexToUint8List(''), Uint8List(0));
      });

      test('converts valid hex string', () {
        expect(
          hexToUint8List('deadbeef'),
          Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]),
        );
      });

      test('handles uppercase hex', () {
        expect(
          hexToUint8List('DEADBEEF'),
          Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]),
        );
      });

      test('handles mixed case hex', () {
        expect(
          hexToUint8List('DeAdBeEf'),
          Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]),
        );
      });

      test('throws on odd-length string', () {
        expect(
          () => hexToUint8List('abc'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on single character', () {
        expect(
          () => hexToUint8List('a'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('roundtrip with uint8ListToHex', () {
        final original = Uint8List.fromList([1, 2, 3, 255, 0, 128]);
        final hex = uint8ListToHex(original);
        final result = hexToUint8List(hex);
        expect(result, original);
      });

      test('roundtrip with various lengths', () {
        for (int len = 0; len <= 32; len++) {
          final original = Uint8List.fromList(List.generate(len, (i) => i));
          final hex = uint8ListToHex(original);
          final result = hexToUint8List(hex);
          expect(result, original, reason: 'Failed for length $len');
        }
      });
    });

    group('intToLittleEndianBytes', () {
      test('converts 1-byte value', () {
        expect(
          intToLittleEndianBytes(0x42, 1),
          Uint8List.fromList([0x42]),
        );
      });

      test('converts 1-byte zero', () {
        expect(
          intToLittleEndianBytes(0, 1),
          Uint8List.fromList([0]),
        );
      });

      test('converts 1-byte max value', () {
        expect(
          intToLittleEndianBytes(255, 1),
          Uint8List.fromList([255]),
        );
      });

      test('converts 2-byte value in little endian', () {
        expect(
          intToLittleEndianBytes(0x1234, 2),
          Uint8List.fromList([0x34, 0x12]),
        );
      });

      test('converts 2-byte zero', () {
        expect(
          intToLittleEndianBytes(0, 2),
          Uint8List.fromList([0, 0]),
        );
      });

      test('converts 4-byte value in little endian', () {
        expect(
          intToLittleEndianBytes(0x12345678, 4),
          Uint8List.fromList([0x78, 0x56, 0x34, 0x12]),
        );
      });

      test('converts 4-byte sequence number (0xffffffff)', () {
        expect(
          intToLittleEndianBytes(0xffffffff, 4),
          Uint8List.fromList([0xff, 0xff, 0xff, 0xff]),
        );
      });

      test('converts 8-byte value in little endian', () {
        final result = intToLittleEndianBytes(0x0102030405060708, 8);
        expect(result.length, 8);
        expect(result[0], 0x08);
        expect(result[1], 0x07);
        expect(result[6], 0x02);
        expect(result[7], 0x01);
      });

      test('converts 8-byte amount (1 DCR = 100000000 atoms)', () {
        final oneDcr = 100000000;
        final result = intToLittleEndianBytes(oneDcr, 8);
        expect(result.length, 8);
        // 100000000 = 0x05F5E100
        expect(result[0], 0x00);
        expect(result[1], 0xE1);
        expect(result[2], 0xF5);
        expect(result[3], 0x05);
      });

      test('throws on unsupported byte count 3', () {
        expect(
          () => intToLittleEndianBytes(1, 3),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on unsupported byte count 5', () {
        expect(
          () => intToLittleEndianBytes(1, 5),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on unsupported byte count 0', () {
        expect(
          () => intToLittleEndianBytes(1, 0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('strHashToUint8List', () {
      test('converts 64-char txid to reversed bytes', () {
        // Create a predictable txid
        final txid = '0102030405060708091011121314151617181920212223242526272829303132';
        final result = strHashToUint8List(txid);

        expect(result.length, 32);
        // First byte of result should be last byte pair of txid (32 = 0x32)
        expect(result[0], 0x32);
        // Second byte should be second-to-last pair (31 = 0x31)
        expect(result[1], 0x31);
        // Last byte of result should be first byte pair of txid (01 = 0x01)
        expect(result[31], 0x01);
      });

      test('converts all-zeros txid', () {
        final txid = '0' * 64;
        final result = strHashToUint8List(txid);

        expect(result.length, 32);
        expect(result.every((b) => b == 0), true);
      });

      test('converts all-f txid', () {
        final txid = 'f' * 64;
        final result = strHashToUint8List(txid);

        expect(result.length, 32);
        expect(result.every((b) => b == 0xff), true);
      });

      test('throws on too short string (63 chars)', () {
        final short = '0' * 63;
        expect(
          () => strHashToUint8List(short),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on too long string (65 chars)', () {
        final long = '0' * 65;
        expect(
          () => strHashToUint8List(long),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on empty string', () {
        expect(
          () => strHashToUint8List(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles real-world txid format', () {
        // Example Decred txid (reversed for display)
        final txid = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
        final result = strHashToUint8List(txid);

        expect(result.length, 32);
        // Verify it's properly reversed
        expect(result[0], 0xb2); // Last pair 'b2'
        expect(result[31], 0xa1); // First pair 'a1'
      });
    });

    group('serializeTransactionOutputs', () {
      test('returns empty buffer for empty list', () {
        final result = serializeTransactionOutputs([]);
        expect(result, Uint8List(0));
      });

      test('serializes single output correctly', () {
        final outs = [
          {
            'value': 1.5, // 150000000 atoms
            'version': 0,
            'scriptPubKey': {'hex': 'abcd'},
          }
        ];

        final result = serializeTransactionOutputs(outs);

        expect(result.isNotEmpty, true);
        // First byte is varint for count = 1
        expect(result[0], 1);
      });

      test('serializes output with correct amount encoding', () {
        final outs = [
          {
            'value': 1.0, // 100000000 atoms = 0x05F5E100
            'version': 0,
            'scriptPubKey': {'hex': 'aa'},
          }
        ];

        final result = serializeTransactionOutputs(outs);

        // Byte 0: count (1)
        expect(result[0], 1);
        // Bytes 1-8: amount in little endian (100000000)
        expect(result[1], 0x00);
        expect(result[2], 0xE1);
        expect(result[3], 0xF5);
        expect(result[4], 0x05);
      });

      test('serializes multiple outputs', () {
        final outs = [
          {
            'value': 1.0,
            'version': 0,
            'scriptPubKey': {'hex': 'aa'}
          },
          {
            'value': 2.0,
            'version': 0,
            'scriptPubKey': {'hex': 'bb'}
          },
        ];

        final result = serializeTransactionOutputs(outs);
        expect(result[0], 2); // varint count = 2
      });

      test('includes version bytes', () {
        final outs = [
          {
            'value': 0.0,
            'version': 1,
            'scriptPubKey': {'hex': 'aa'},
          }
        ];

        final result = serializeTransactionOutputs(outs);

        // After count (1) and amount (8 bytes), version is 2 bytes little endian
        expect(result[9], 1); // version low byte
        expect(result[10], 0); // version high byte
      });
    });
  });

  group('Data Classes', () {
    group('TrustedInput', () {
      test('constructor sets all fields', () {
        final ti = TrustedInput(
          trustedInput: true,
          value: Uint8List.fromList([1, 2, 3]),
          tree: Uint8List.fromList([0]),
          sequence: Uint8List.fromList([0xff, 0xff, 0xff, 0xff]),
        );

        expect(ti.trustedInput, true);
        expect(ti.value, Uint8List.fromList([1, 2, 3]));
        expect(ti.tree, Uint8List.fromList([0]));
        expect(ti.sequence.length, 4);
      });

      test('can be created with trustedInput false', () {
        final ti = TrustedInput(
          trustedInput: false,
          value: Uint8List(0),
          tree: Uint8List(0),
          sequence: Uint8List(0),
        );

        expect(ti.trustedInput, false);
      });
    });

    group('PubkeyResp', () {
      test('constructor sets all fields', () {
        final resp = PubkeyResp('pubkey123', 'DsAddress...', 'chaincode456');

        expect(resp.pubkey, 'pubkey123');
        expect(resp.address, 'DsAddress...');
        expect(resp.chainCode, 'chaincode456');
      });

      test('fields are mutable', () {
        final resp = PubkeyResp('a', 'b', 'c');
        resp.pubkey = 'newpubkey';
        resp.address = 'newaddress';
        resp.chainCode = 'newchaincode';

        expect(resp.pubkey, 'newpubkey');
        expect(resp.address, 'newaddress');
        expect(resp.chainCode, 'newchaincode');
      });
    });
  });

  group('Ledger Operations', () {
    group('UntrustedHashSignOperation', () {
      test('has correct p1 and p2 values', () {
        final op = UntrustedHashSignOperation(
          "44'/42'/0'/0/0",
          0, // lockTime
          100000, // expiryHeight
          1, // sigHashType (SIGHASH_ALL)
        );

        expect(op.p1, 0x00);
        expect(op.p2, 0x00);
      });

      test('writeInputData produces non-empty bytes', () async {
        final op = UntrustedHashSignOperation(
          "44'/42'/0'/0/0",
          12345,
          67890,
          1,
        );

        final data = await op.writeInputData();

        // Should contain derivation path + locktime(4) + expiry(4) + sighash(1)
        expect(data.length, greaterThan(9));
      });

      test('read modifies first byte to 0x30 and strips last 2 bytes', () async {
        final op = UntrustedHashSignOperation("44'/42'/0'/0/0", 0, 0, 1);
        final reader = ByteDataReader();
        reader.add(Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]));

        final result = await op.read(reader);

        expect(result[0], 0x30);
        expect(result.length, 3); // 5 - 2 = 3
      });

      test('read returns empty for empty input', () async {
        final op = UntrustedHashSignOperation("44'/42'/0'/0/0", 0, 0, 1);
        final reader = ByteDataReader();
        reader.add(Uint8List(0));

        final result = await op.read(reader);

        expect(result, Uint8List(0));
      });

      test('stores derivation path correctly', () {
        final op = UntrustedHashSignOperation(
          "44'/42'/5'/1/10",
          0,
          0,
          1,
        );

        expect(op.derivationPath, "44'/42'/5'/1/10");
      });

      test('stores lockTime correctly', () {
        final op = UntrustedHashSignOperation("44'/42'/0'/0/0", 123456, 0, 1);
        expect(op.lockTime, 123456);
      });

      test('stores expiryHeight correctly', () {
        final op = UntrustedHashSignOperation("44'/42'/0'/0/0", 0, 789012, 1);
        expect(op.expiryHeight, 789012);
      });

      test('stores sigHashType correctly', () {
        final op = UntrustedHashSignOperation("44'/42'/0'/0/0", 0, 0, 0x81);
        expect(op.sigHashType, 0x81);
      });
    });

    group('HashOutputFull', () {
      test('has correct p1 and p2 values', () {
        final op = HashOutputFull(Uint8List.fromList([1, 2, 3]));

        expect(op.p1, 0x80);
        expect(op.p2, 0x00);
      });

      test('writeInputData returns the output script', () async {
        final script = Uint8List.fromList([0x76, 0xa9, 0x14]);
        final op = HashOutputFull(script);

        final data = await op.writeInputData();

        expect(data, script);
      });

      test('writeInputData returns empty for empty script', () async {
        final op = HashOutputFull(Uint8List(0));

        final data = await op.writeInputData();

        expect(data, Uint8List(0));
      });

      test('read returns all remaining bytes', () async {
        final op = HashOutputFull(Uint8List(0));
        final reader = ByteDataReader();
        reader.add(Uint8List.fromList([1, 2, 3, 4, 5]));

        final result = await op.read(reader);

        expect(result, Uint8List.fromList([1, 2, 3, 4, 5]));
      });
    });

    group('UntrustedHashTxInputStartOperation', () {
      test('p1 is 0x00 for first round', () {
        final op = UntrustedHashTxInputStartOperation(
          true,
          true, // firstRound
          Uint8List(0),
        );

        expect(op.p1, 0x00);
      });

      test('p1 is 0x80 for not first round', () {
        final op = UntrustedHashTxInputStartOperation(
          true,
          false, // not firstRound
          Uint8List(0),
        );

        expect(op.p1, 0x80);
      });

      test('p2 is 0x00 for new transaction', () {
        final op = UntrustedHashTxInputStartOperation(
          true, // isNewTransaction
          true,
          Uint8List(0),
        );

        expect(op.p2, 0x00);
      });

      test('p2 is 0x80 for not new transaction', () {
        final op = UntrustedHashTxInputStartOperation(
          false, // not isNewTransaction
          true,
          Uint8List(0),
        );

        expect(op.p2, 0x80);
      });

      test('all combinations of p1 and p2', () {
        // new tx, first round
        var op = UntrustedHashTxInputStartOperation(true, true, Uint8List(0));
        expect(op.p1, 0x00);
        expect(op.p2, 0x00);

        // new tx, not first round
        op = UntrustedHashTxInputStartOperation(true, false, Uint8List(0));
        expect(op.p1, 0x80);
        expect(op.p2, 0x00);

        // not new tx, first round
        op = UntrustedHashTxInputStartOperation(false, true, Uint8List(0));
        expect(op.p1, 0x00);
        expect(op.p2, 0x80);

        // not new tx, not first round
        op = UntrustedHashTxInputStartOperation(false, false, Uint8List(0));
        expect(op.p1, 0x80);
        expect(op.p2, 0x80);
      });

      test('writeInputData returns transaction data', () async {
        final txData = Uint8List.fromList([0x01, 0x02, 0x03]);
        final op = UntrustedHashTxInputStartOperation(true, true, txData);

        final result = await op.writeInputData();

        expect(result, txData);
      });
    });

    group('GetTrustedInputOperation', () {
      test('p1 is 0x00 when indexLookup is provided', () {
        final op = GetTrustedInputOperation(Uint8List(0), 5);
        expect(op.p1, 0x00);
      });

      test('p1 is 0x80 when indexLookup is not provided', () {
        final op = GetTrustedInputOperation(Uint8List(0));
        expect(op.p1, 0x80);
      });

      test('p2 is always 0x00', () {
        expect(GetTrustedInputOperation(Uint8List(0)).p2, 0x00);
        expect(GetTrustedInputOperation(Uint8List(0), 0).p2, 0x00);
        expect(GetTrustedInputOperation(Uint8List(0), 100).p2, 0x00);
      });

      test('writeInputData includes index when provided', () async {
        final op = GetTrustedInputOperation(
          Uint8List.fromList([0xaa, 0xbb]),
          5,
        );

        final data = await op.writeInputData();

        // 4 bytes for index (big endian) + 2 bytes input data
        expect(data.length, 6);
        // Index 5 in big endian at bytes 0-3
        expect(data[0], 0);
        expect(data[1], 0);
        expect(data[2], 0);
        expect(data[3], 5);
        // Input data follows
        expect(data[4], 0xaa);
        expect(data[5], 0xbb);
      });

      test('writeInputData with large index', () async {
        final op = GetTrustedInputOperation(Uint8List(0), 0x01020304);

        final data = await op.writeInputData();

        expect(data[0], 0x01);
        expect(data[1], 0x02);
        expect(data[2], 0x03);
        expect(data[3], 0x04);
      });

      test('writeInputData without index only includes input data', () async {
        final inputData = Uint8List.fromList([1, 2, 3]);
        final op = GetTrustedInputOperation(inputData);

        final data = await op.writeInputData();

        expect(data, inputData);
      });

      test('read strips last 2 bytes from non-empty result', () async {
        final op = GetTrustedInputOperation(Uint8List(0));
        final reader = ByteDataReader();
        reader.add(Uint8List.fromList([1, 2, 3, 4, 5]));

        final result = await op.read(reader);

        expect(result.length, 3); // 5 - 2
        expect(result, Uint8List.fromList([1, 2, 3]));
      });

      test('read returns empty for empty input', () async {
        final op = GetTrustedInputOperation(Uint8List(0));
        final reader = ByteDataReader();
        reader.add(Uint8List(0));

        final result = await op.read(reader);

        expect(result, Uint8List(0));
      });

      test('read returns empty for 2-byte input', () async {
        final op = GetTrustedInputOperation(Uint8List(0));
        final reader = ByteDataReader();
        reader.add(Uint8List.fromList([1, 2]));

        final result = await op.read(reader);

        expect(result, Uint8List(0));
      });
    });

    group('ExtendedPublicKeyOperation', () {
      test('p1 is 0x01 when displayPublicKey is true', () {
        final op = ExtendedPublicKeyOperation(
          displayPublicKey: true,
          derivationPath: "44'/42'/0'",
        );

        expect(op.p1, 0x01);
      });

      test('p1 is 0x00 when displayPublicKey is false', () {
        final op = ExtendedPublicKeyOperation(
          displayPublicKey: false,
          derivationPath: "44'/42'/0'",
        );

        expect(op.p1, 0x00);
      });

      test('p2 is always 0x00 for legacy key type', () {
        final op1 = ExtendedPublicKeyOperation(
          displayPublicKey: false,
          derivationPath: "44'/42'/0'",
        );
        final op2 = ExtendedPublicKeyOperation(
          displayPublicKey: true,
          derivationPath: "44'/42'/1'",
        );

        expect(op1.p2, 0x00);
        expect(op2.p2, 0x00);
      });

      test('stores derivation path', () {
        final op = ExtendedPublicKeyOperation(
          displayPublicKey: false,
          derivationPath: "44'/42'/5'",
        );

        expect(op.derivationPath, "44'/42'/5'");
      });

      test('writeInputData produces correct format', () async {
        final op = ExtendedPublicKeyOperation(
          displayPublicKey: false,
          derivationPath: "44'/42'/0'",
        );

        final data = await op.writeInputData();

        // First byte is path length (3 elements)
        expect(data[0], 3);
        // Followed by 4 bytes per path element = 12 bytes
        expect(data.length, 13);
      });
    });
  });

  group('Derivation Path Formatting', () {
    test('path format for account 0, external chain, index 0', () {
      // Simulating what createInputTx does
      final accountn = 0;
      final branch = 0;
      final index = 0;
      final path = "44'/42'/$accountn'/$branch/$index";

      expect(path, "44'/42'/0'/0/0");
    });

    test('path format for account 1, internal chain, index 5', () {
      final accountn = 1;
      final branch = 1;
      final index = 5;
      final path = "44'/42'/$accountn'/$branch/$index";

      expect(path, "44'/42'/1'/1/5");
    });

    test('change path format for internal branch', () {
      // Simulating what signTransaction does for change
      final accountn = 0;
      final index = 10;
      final changePath = "44'/42'/$accountn'/1/$index";

      expect(changePath, "44'/42'/0'/1/10");
    });
  });

  group('Amount Conversion', () {
    test('1 DCR = 100000000 atoms', () {
      final dcr = 1.0;
      final atoms = (dcr * 100000000).round();
      expect(atoms, 100000000);
    });

    test('0.5 DCR = 50000000 atoms', () {
      final dcr = 0.5;
      final atoms = (dcr * 100000000).round();
      expect(atoms, 50000000);
    });

    test('0.00000001 DCR = 1 atom', () {
      final dcr = 0.00000001;
      final atoms = (dcr * 100000000).round();
      expect(atoms, 1);
    });

    test('0.00013 DCR = 13000 atoms (floating-point precision)', () {
      final dcr = 0.00013;
      final atoms = (dcr * 100000000).round();
      expect(atoms, 13000);
    });

    test('amount serialization for 1 DCR', () {
      final atoms = 100000000;
      final bytes = intToLittleEndianBytes(atoms, 8);

      // 100000000 = 0x05F5E100 in little endian
      expect(bytes[0], 0x00);
      expect(bytes[1], 0xE1);
      expect(bytes[2], 0xF5);
      expect(bytes[3], 0x05);
      expect(bytes[4], 0x00);
      expect(bytes[5], 0x00);
      expect(bytes[6], 0x00);
      expect(bytes[7], 0x00);
    });
  });
}
