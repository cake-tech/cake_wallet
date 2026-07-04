import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/locales/locale.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpButtons(
    WidgetTester tester, {
    required double width,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: ReceiveBottomButtons(
            largeQrMode: false,
            onCopyButtonPressed: () {},
            onAmountButtonPressed: () {},
            onLabelButtonPressed: () {},
            onAccountsButtonPressed: () {},
            showLabelButton: true,
            showAccountsButton: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'keeps all Spanish receive actions visible at ${width.toInt()}px',
      (tester) async {
        await pumpButtons(tester, width: width);

        expect(find.text('Copiar'), findsOneWidget);
        expect(find.text('Establecer cantidad'), findsOneWidget);
        expect(find.text('Etiqueta'), findsOneWidget);
        expect(find.text('Direcciones'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
