import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/locales/locale.dart';
import 'package:cake_wallet/new-ui/pages/addresses_page.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not render unavailable Zcash address metadata', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: AddressRow(
            selected: false,
            first: true,
            last: true,
            item: WalletAddressListItem(
              address: 't1abcdefghijklmnopqrstuvwxyz1234567',
              isPrimary: false,
            ),
            onSelect: () {},
            walletType: WalletType.zcash,
            onLabelChanged: () {},
            onAddressHidden: () {},
            hasBalance: false,
            hasReceived: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('null'), findsNothing);
    expect(find.textContaining('Transacciones:'), findsNothing);
    expect(find.textContaining('Saldo:'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
