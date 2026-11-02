import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/tron_token.dart';
import 'package:cw_tron/tron_abi.dart';
import 'package:cw_tron/tron_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_chain/on_chain.dart';

class _Rpc with TronServiceProvider {
  _Rpc({this.tokenTransaction, this.genesis = mainnetGenesis});
  static const mainnetGenesis =
      '00000000000000001ebf88508a03865c71d452e25f4d51194196a1d22b6653dc';
  final TransactionRaw? tokenTransaction;
  final String genesis;

  @override
  String get url => 'https://example.invalid';

  @override
  Future<Map<String, dynamic>> get(TronRequestDetails params, [Duration? timeout]) =>
      post(params, timeout);

  @override
  Future<Map<String, dynamic>> post(TronRequestDetails params, [Duration? timeout]) async {
    if (params.method.uri == 'wallet/getnowblock') {
      return {
        'blockID': '00',
        'block_header': {
          'raw_data': {
            'number': 100,
            'version': 1,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        }
      };
    }
    if (params.method.uri == 'wallet/getblockbynum') {
      return {'blockID': genesis};
    }
    if (params.method.uri == 'wallet/triggerconstantcontract' && tokenTransaction != null) {
      return {
        'result': {'result': true},
        'transaction': {
          'ret': [<String, dynamic>{}],
          'raw_data': tokenTransaction!.toJson()
        },
        'energy_used': 0,
      };
    }
    throw StateError('Unexpected RPC request: ${params.method.uri}');
  }
}

(Uint8List, Uint8List) _decodeEnvelope(Uint8List bytes) {
  var offset = 0;
  Uint8List field(int tag) {
    expect(bytes[offset++], tag);
    var length = 0;
    var shift = 0;
    int byte;
    do {
      byte = bytes[offset++];
      length |= (byte & 0x7f) << shift;
      shift += 7;
    } while ((byte & 0x80) != 0);
    final result = Uint8List.fromList(bytes.sublist(offset, offset + length));
    offset += length;
    return result;
  }

  final raw = field(0x0a);
  final signature = field(0x12);
  expect(offset, bytes.length);
  return (raw, signature);
}

void main() {
  final key = TronPrivateKey('01'.padLeft(64, '0'));
  final otherKey = TronPrivateKey('02'.padLeft(64, '0'));
  final owner = key.publicKey().toAddress();
  final recipient = otherKey.publicKey().toAddress();
  final trx = Money(BigInt.from(1000000), CryptoCurrency.trx);
  final usdt = TronToken(
    name: 'Tether USD',
    symbol: 'USDT',
    contractAddress: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
    decimal: 6,
  );

  TransactionRaw rawFor(
    TronBaseContract value, {
    List<int>? memo,
    int? permission,
    BigInt? expiration,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TransactionRaw(
      refBlockBytes: [1, 2],
      refBlockHash: List.filled(8, 3),
      timestamp: BigInt.from(now),
      expiration: expiration ?? BigInt.from(now + 600000),
      feeLimit: BigInt.from(1000000),
      data: memo,
      contract: [
        TransactionContract(
          type: value.contractType,
          parameter: Any(typeUrl: value.typeURL, value: value),
          permissionId: permission,
        ),
      ],
    );
  }

  TransferContract transfer({TronAddress? from, TronAddress? to, BigInt? amount}) =>
      TransferContract(
        ownerAddress: from ?? owner,
        toAddress: to ?? recipient,
        amount: amount ?? trx.amount,
      );

  Uint8List ledgerSignature(TronPrivateKey signer, Uint8List bytes) {
    final signature = Uint8List.fromList(signer.sign(bytes));
    signature[64] -= 27;
    return signature;
  }

  group('prepared Ledger transactions', () {
    test('software TRX preparation, signing and broadcasting remain compatible', () async {
      Uint8List? broadcast;
      final client = TronClient(
        provider: TronProvider(_Rpc()),
        broadcast: (bytes) async {
          broadcast = bytes;
          return 'accepted';
        },
      );
      final pending = await client.signTransaction(
        ownerPrivKey: key,
        toAddress: recipient.toAddress(),
        amount: trx,
        tronBalance: BigInt.from(10000000),
        sendAll: false,
      );
      await pending.commit();
      final (raw, actualSignature) = _decodeEnvelope(broadcast!);
      expect(actualSignature.last, anyOf(27, 28));
      expect(actualSignature, key.sign(raw));
    });

    test('software TRC-20 preparation, signing and broadcasting remain compatible', () async {
      final amount = Money(BigInt.from(5000000), usdt);
      final data = ContractABI.fromJson(trc20Abi, isTron: true)
          .functionFromName('transfer')
          .encodeHex([recipient, amount.amount]);
      final raw = rawFor(TriggerSmartContract(
        ownerAddress: owner,
        contractAddress: TronAddress(usdt.contractAddress),
        data: BytesUtils.fromHexString(data),
      ));
      Uint8List? broadcast;
      final client = TronClient(
        provider: TronProvider(_Rpc(tokenTransaction: raw)),
        broadcast: (bytes) async {
          broadcast = bytes;
          return 'accepted';
        },
      );
      final pending = await client.signTransaction(
        ownerPrivKey: key,
        toAddress: recipient.toAddress(),
        amount: amount,
        tronBalance: BigInt.from(10000000),
        sendAll: false,
      );
      await pending.commit();
      final (actualRaw, actualSignature) = _decodeEnvelope(broadcast!);
      expect(actualSignature, key.sign(actualRaw));
    });

    test('prepares, signs and broadcasts a mainnet Ledger USDT transfer', () async {
      final amount = Money(BigInt.from(5000000), usdt);
      final data = ContractABI.fromJson(trc20Abi, isTron: true)
          .functionFromName('transfer')
          .encodeHex([recipient, amount.amount]);
      final raw = rawFor(TriggerSmartContract(
        ownerAddress: owner,
        contractAddress: TronAddress(usdt.contractAddress),
        data: BytesUtils.fromHexString(data),
      ));
      Uint8List? broadcast;
      final client = TronClient(
        provider: TronProvider(_Rpc(tokenTransaction: raw)),
        broadcast: (bytes) async {
          broadcast = bytes;
          return 'accepted';
        },
      );
      final prepared = await client.prepareTransaction(
        ownerAddress: owner,
        toAddress: recipient.toAddress(),
        amount: amount,
        tronBalance: BigInt.from(10000000),
        sendAll: false,
        isHardware: true,
      );
      final signature = ledgerSignature(key, prepared.rawData);
      await client.createPendingTransaction(prepared, signature).commit();
      final (actualRaw, actualSignature) = _decodeEnvelope(broadcast!);
      expect(actualRaw, prepared.rawData);
      expect(actualSignature, signature);
    });

    test('rejects USDT on a non-mainnet node before requesting a transaction', () async {
      final client = TronClient(provider: TronProvider(_Rpc(genesis: 'wrong-network')));
      await expectLater(
        client.prepareTransaction(
          ownerAddress: owner,
          toAddress: recipient.toAddress(),
          amount: Money(BigInt.one, usdt),
          tronBalance: BigInt.from(10000000),
          sendAll: false,
          isHardware: true,
        ),
        throwsUnsupportedError,
      );
    });

    test('signs and broadcasts exactly the prepared raw bytes', () async {
      Uint8List? broadcast;
      final client = TronClient(
        broadcast: (bytes) async {
          broadcast = bytes;
          return 'accepted';
        },
      );
      final prepared = client.prepareHardwareTransaction(
        raw: rawFor(transfer()),
        owner: owner,
        recipient: recipient,
        amount: trx,
      );
      final raw = prepared.rawData;
      final signature = ledgerSignature(key, raw);
      final pending = client.createPendingTransaction(prepared, signature);
      raw[0] ^= 0xff;
      signature[0] ^= 0xff;
      await pending.commit();
      final (actualRaw, actualSignature) = _decodeEnvelope(broadcast!);
      expect(actualRaw, prepared.rawData);
      expect(actualSignature, pending.signedTransaction);
    });

    test('rejects a wrong signer, invalid parity and expired data', () {
      var broadcasts = 0;
      final client = TronClient(broadcast: (_) async {
        broadcasts++;
        return 'accepted';
      });
      final prepared = client.prepareHardwareTransaction(
        raw: rawFor(transfer()),
        owner: owner,
        recipient: recipient,
        amount: trx,
      );
      expect(
        () =>
            client.createPendingTransaction(prepared, ledgerSignature(otherKey, prepared.rawData)),
        throwsFormatException,
      );
      final invalid = ledgerSignature(key, prepared.rawData)..[64] = 27;
      expect(() => client.createPendingTransaction(prepared, invalid), throwsFormatException);
      expect(broadcasts, 0);
    });

    test('an expired pending transaction never broadcasts', () async {
      var broadcasts = 0;
      final client = TronClient(broadcast: (_) async {
        broadcasts++;
        return 'accepted';
      });
      final raw = rawFor(
        transfer(),
        expiration: BigInt.from(DateTime.now().millisecondsSinceEpoch + 1000),
      );
      final prepared = client.prepareHardwareTransaction(
          raw: raw, owner: owner, recipient: recipient, amount: trx);
      final pending =
          client.createPendingTransaction(prepared, ledgerSignature(key, prepared.rawData));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await expectLater(pending.commit(), throwsStateError);
      expect(broadcasts, 0);
      expect(
        () => client.prepareHardwareTransaction(
          raw: rawFor(transfer(), expiration: BigInt.one),
          owner: owner,
          recipient: recipient,
          amount: trx,
        ),
        throwsFormatException,
      );
    });

    test('rejects mismatched owner, recipient, amount, memo and permissions', () {
      final client = TronClient();
      final invalid = [
        rawFor(transfer(from: recipient)),
        rawFor(transfer(to: owner)),
        rawFor(transfer(amount: BigInt.one)),
        rawFor(transfer(), memo: [1]),
        rawFor(transfer(), permission: 2),
      ];
      for (final raw in invalid) {
        expect(
          () => client.prepareHardwareTransaction(
            raw: raw,
            owner: owner,
            recipient: recipient,
            amount: trx,
          ),
          throwsFormatException,
        );
      }
    });

    test('accepts only the requested mainnet USDT transfer', () {
      final client = TronClient();
      final amount = Money(BigInt.from(5000000), usdt);
      final data = ContractABI.fromJson(
        trc20Abi,
        isTron: true,
      ).functionFromName('transfer').encodeHex([recipient, amount.amount]);
      final contract = TriggerSmartContract(
        ownerAddress: owner,
        contractAddress: TronAddress(usdt.contractAddress),
        data: BytesUtils.fromHexString(data),
      );
      expect(
        () => client.prepareHardwareTransaction(
          raw: rawFor(contract),
          owner: owner,
          recipient: recipient,
          amount: amount,
        ),
        returnsNormally,
      );
      final wrongToken = TronToken(
        name: 'Other',
        symbol: 'OTHER',
        contractAddress: recipient.toAddress(),
        decimal: 6,
      );
      expect(
        () => client.prepareHardwareTransaction(
          raw: rawFor(contract),
          owner: owner,
          recipient: recipient,
          amount: Money(BigInt.one, wrongToken),
        ),
        throwsUnsupportedError,
      );
      final altered = TriggerSmartContract(
        ownerAddress: owner,
        contractAddress: TronAddress(usdt.contractAddress),
        data: [0, ...contract.data!.skip(1)],
      );
      expect(
        () => client.prepareHardwareTransaction(
          raw: rawFor(altered),
          owner: owner,
          recipient: recipient,
          amount: amount,
        ),
        throwsFormatException,
      );
      for (final unsafe in [
        TriggerSmartContract(
          ownerAddress: owner,
          contractAddress: recipient,
          data: contract.data,
        ),
        TriggerSmartContract(
          ownerAddress: recipient,
          contractAddress: TronAddress(usdt.contractAddress),
          data: contract.data,
        ),
        TriggerSmartContract(
          ownerAddress: owner,
          contractAddress: TronAddress(usdt.contractAddress),
          data: contract.data,
          callValue: BigInt.one,
        ),
        TriggerSmartContract(
          ownerAddress: owner,
          contractAddress: TronAddress(usdt.contractAddress),
          data: contract.data,
          callTokenValue: BigInt.one,
        ),
      ]) {
        expect(
          () => client.prepareHardwareTransaction(
            raw: rawFor(unsafe),
            owner: owner,
            recipient: recipient,
            amount: amount,
          ),
          throwsFormatException,
        );
      }
    });
  });
}
