import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/wallet_info.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("keeps a hardware wallet name on one ellipsized line", (tester) async {
    const walletName =
        "My exceptionally long Ledger hardware wallet name that cannot fit in the header";
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              child: WalletInfoBar(
                name: walletName,
                hardwareWalletType: HardwareWalletType.ledger,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final name = tester.widget<Text>(find.text(walletName));
    expect(name.maxLines, 1);
    expect(name.softWrap, isFalse);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(name.style?.fontSize, 16);

    final hardwareIcon = tester.widget<CakeImageWidget>(
      find.byKey(const ValueKey("hardware_wallet_icon")),
    );
    expect(hardwareIcon.imageUrl, "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg");
    expect(hardwareIcon.width, 24);
    expect(hardwareIcon.height, 24);
    expect(
      tester.getRect(find.text(walletName)).left -
          tester.getRect(find.byKey(const ValueKey("hardware_wallet_icon"))).right,
      4,
    );

    expect(
      find.bySemanticsLabel("$walletName, ${S.current.hardware_wallet}"),
      findsOneWidget,
    );
    expect(find.byType(ModernButton), findsNothing);
    expect(find.bySemanticsLabel(S.current.wallet_accounts), findsNothing);
    expect(tester.takeException(), isNull);
    semanticsHandle.dispose();
  });
}
