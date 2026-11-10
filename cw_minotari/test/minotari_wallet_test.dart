import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/exceptions/cake_exception.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/api/scanner.dart';
import 'package:flutter_test/flutter_test.dart';

OutputInfo _output({String address = 'addr', int amount = 0, bool sendAll = false, String? note}) =>
    OutputInfo(
      address: address,
      sendAll: sendAll,
      isParsedAddress: false,
      cryptoAmount: Money.fromInt(amount, CryptoCurrency.xtm),
      note: note,
    );

void main() {
  group('minotariSyncStatusFor', () {
    SyncStatus? statusFor(ScanEventDto event) => minotariSyncStatusFor(event, startHeight: 100);

    test('progress reports the percentage towards the tip', () {
      final status = statusFor(ScanEventDto.progress(
        accountId: 1,
        currentHeight: BigInt.from(150),
        tipHeight: BigInt.from(200),
        blocksScanned: BigInt.from(50),
      ));

      expect(status, isA<SyncingSyncStatus>());
      expect(status!.progress(), 0.5);
    });

    test('only a caught-up or completed scan is synced', () {
      expect(statusFor(ScanEventDto.waiting(accountId: 1, resumeInSeconds: BigInt.from(60))),
          isA<SyncedSyncStatus>());
      expect(
          statusFor(ScanEventDto.completed(
              accountId: 1, finalHeight: BigInt.one, totalBlocksScanned: BigInt.one)),
          isA<SyncedSyncStatus>());
      expect(statusFor(ScanEventDto.started(accountId: 1, fromHeight: BigInt.zero)),
          isNot(isA<SyncedSyncStatus>()));
    });

    test('a stopped or replaced scan is not connected, an error fails', () {
      expect(statusFor(const ScanEventDto.cancelled()), isA<NotConnectedSyncStatus>());
      expect(statusFor(const ScanEventDto.superseded()), isA<NotConnectedSyncStatus>());
      expect(statusFor(const ScanEventDto.error('transport error')), isA<FailedSyncStatus>());
    });

    test('blocks and transaction events leave the status alone', () {
      expect(
          statusFor(ScanEventDto.moreBlocksAvailable(accountId: 1, lastScannedHeight: BigInt.one)),
          isNull);
    });
  });

  group('minotariRecipients', () {
    test('maps every output, with its note as payment id', () {
      final recipients = minotariRecipients([
        _output(address: 'a', amount: 1000, note: 'invoice 7'),
        _output(address: 'b', amount: 2000),
      ]);

      expect(recipients.map((r) => r.address), ['a', 'b']);
      expect(recipients.map((r) => r.amount), [BigInt.from(1000), BigInt.from(2000)]);
      expect(recipients.map((r) => r.paymentId), ['invoice 7', null]);
    });

    test('send-all pays one recipient and passes no amount', () {
      final recipients = minotariRecipients([_output(sendAll: true, amount: 5000)]);

      expect(recipients.single.amount, BigInt.zero);
    });

    test('rejects send-all combined with other outputs', () {
      expect(
        () => minotariRecipients([_output(sendAll: true), _output(amount: 1)]),
        throwsA(isA<TransactionGenerationException>()),
      );
    });

    test('rejects a zero amount and no outputs', () {
      expect(() => minotariRecipients([_output()]), throwsA(isA<TransactionGenerationException>()));
      expect(() => minotariRecipients([]), throwsA(isA<TransactionGenerationException>()));
    });
  });

  group('network', () {
    test('testnet is stagenet, otherwise mainnet', () {
      expect(minotariNetworkFor(isTestnet: true), TariNetwork.stageNet);
      expect(minotariNetworkFor(isTestnet: false), TariNetwork.mainNet);
      expect(minotariNetworkFor(), TariNetwork.mainNet);
    });

    test('the stored network name round-trips; none is mainnet', () {
      expect(minotariNetworkFromName(TariNetwork.stageNet.name), TariNetwork.stageNet);
      expect(minotariNetworkFromName(null), TariNetwork.mainNet);
    });
  });
}
