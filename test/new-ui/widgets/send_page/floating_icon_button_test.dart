import "package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";

import "../../../utils/semantics_helpers.dart";

const _iconPath = "assets/images/2fa.png";

Future<void> _pump(WidgetTester tester, {VoidCallback? onPressed}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: FloatingIconButton(
            iconPath: _iconPath,
            onPressed: onPressed ?? () {},
            semanticLabel: "Scan QR code",
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group("FloatingIconButton semantics", () {
    testWidgets("exposes a single, named button node", (tester) async {
      await _pump(tester);

      expect(screenReaderStops(tester), hasLength(1));
      expect(
        tester.getSemantics(find.byType(FloatingIconButton)),
        isSemantics(
          label: "Scan QR code",
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets("the decorative icon adds no node of its own", (tester) async {
      await _pump(tester);

      expect(find.semantics.byFlag(SemanticsFlag.isImage), findsNothing);
    });

    testWidgets("a semantic tap invokes onPressed", (tester) async {
      var pressed = 0;
      await _pump(tester, onPressed: () => pressed++);

      tester.semantics.tap(find.semantics.byLabel("Scan QR code"));
      await tester.pump();

      expect(pressed, 1);
    });
  });
}
