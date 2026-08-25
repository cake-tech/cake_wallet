import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PIVX shielded address list', () {
    test('accepts int diversifier indexes from wallet storage', () {
      expect(
        WalletAddressListViewModelBase
            .pivxShieldedDiversifierIndexFromAddressMap({
          'diversifierIndex': 7,
        }),
        equals(7),
      );
    });

    test('accepts legacy string diversifier indexes', () {
      expect(
        WalletAddressListViewModelBase
            .pivxShieldedDiversifierIndexFromAddressMap({
          'diversifierIndex': '8',
        }),
        equals(8),
      );
    });

    test('skips malformed diversifier indexes without crashing', () {
      expect(
        WalletAddressListViewModelBase
            .pivxShieldedDiversifierIndexFromAddressMap({
          'diversifierIndex': 'not-an-index',
        }),
        isNull,
      );
      expect(
        WalletAddressListViewModelBase
            .pivxShieldedDiversifierIndexFromAddressMap({}),
        isNull,
      );
    });
  });
}
