import 'package:cw_pivx/src/pivx_receive_page_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PivxReceivePageOption', () {
    test('offers transparent and shielded, transparent first', () {
      expect(PivxReceivePageOption.all, [
        PivxReceivePageOption.transparent,
        PivxReceivePageOption.shieldedSapling,
      ]);
    });

    test('maps options to address types and back', () {
      expect(PivxReceivePageOption.transparent.toType(), PivxAddressType.transparent);
      expect(PivxReceivePageOption.shieldedSapling.toType(), PivxAddressType.shieldedSapling);
      expect(PivxReceivePageOption.fromType(PivxAddressType.transparent),
          PivxReceivePageOption.transparent);
      expect(PivxReceivePageOption.fromType(PivxAddressType.shieldedSapling),
          PivxReceivePageOption.shieldedSapling);
    });

    test('labels match the picker text', () {
      expect(PivxReceivePageOption.transparent.value, 'Transparent');
      expect(PivxReceivePageOption.shieldedSapling.value, 'Shielded (Sapling)');
    });
  });
}
