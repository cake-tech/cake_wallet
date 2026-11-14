import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_minotari/pending_minotari_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

PendingMinotariTransaction pending(Future<String?> Function() send) => PendingMinotariTransaction(
      amount: Money.fromInt(1000, CryptoCurrency.xtm),
      fee: Money.fromInt(10, CryptoCurrency.xtm),
      send: send,
      isFeeEstimate: true,
    );

void main() {
  test('id is cw\'s transaction id once committed', () async {
    final tx = pending(() async => '12345');
    expect(tx.id, '');
    await tx.commit();
    expect(tx.id, '12345');
  });

  test('id stays empty when cw reported no result', () async {
    final tx = pending(() async => null);
    await tx.commit();
    expect(tx.id, '');
  });
}
