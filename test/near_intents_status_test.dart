import 'package:cake_wallet/exchange/provider/near_intents_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps a Stellar deposit memo and drops a blank one', () {
    expect(nearIntentsDepositMemo('  abc  '), 'abc');
    expect(nearIntentsDepositMemo(''), isNull);
    expect(nearIntentsDepositMemo(null), isNull);
  });

  test('status lookup includes the memo when the quote had one', () {
    expect(
      nearIntentsStatusQuery(depositAddress: 'GABC', depositMemo: 'memo-1'),
      {'depositAddress': 'GABC', 'depositMemo': 'memo-1'},
    );
    expect(
      nearIntentsStatusQuery(depositAddress: 'GABC', depositMemo: '   '),
      {'depositAddress': 'GABC'},
    );
  });
}
