import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_connection_request_sheet.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_dapp_card.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_signing_request_sheet.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_warning_row.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:reown_walletkit/reown_walletkit.dart";

import "sheet_test_app.dart";

class _MockAppStore extends Mock implements AppStore {}

class _MockKeyService extends Mock implements WalletConnectKeyService {}

const claimedUrl = "https://app.uniswap.org";
const verifiedOrigin = "https://uniswap-airdrop.example";

VerifyContext verifyContextOf(Validation validation) => VerifyContext(
  origin: validation == Validation.INVALID ? verifiedOrigin : claimedUrl,
  validation: validation,
  verifyUrl: "https://verify.walletconnect.org",
);

void main() {
  setUpAll(() async {
    S.current = const S();
    await loadSheetFonts();
  });

  Future<void> pumpBody(WidgetTester tester, Widget body) async {
    setPhoneSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      sheetTestApp(
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: body),
        ),
      ),
    );
    await tester.pump();
  }

  Widget cardOf(WCDappCardAction action, VerifyContext? verifyContext) => WCDappCard(
    name: "Uniswap Interface",
    iconUrl: null,
    subtitle: claimedUrl,
    action: action,
    verifyContext: verifyContext,
  );

  for (final action in [WCDappCardAction.connect, WCDappCardAction.sign]) {
    testWidgets("a mismatched origin replaces the claimed URL on the ${action.name} card", (
      tester,
    ) async {
      await pumpBody(tester, cardOf(action, verifyContextOf(Validation.INVALID)));

      expect(find.text(verifiedOrigin), findsOneWidget);
      expect(find.text(claimedUrl), findsNothing);
      expect(
        find.widgetWithText(WCWarningRow, S.current.wc_warning_origin_mismatch),
        findsOneWidget,
      );
      expect(find.text(S.current.wc_not_verified), findsNothing);
    });
  }

  testWidgets("an origin nobody attested keeps the claimed URL and the not verified badge", (
    tester,
  ) async {
    await pumpBody(tester, cardOf(WCDappCardAction.sign, verifyContextOf(Validation.UNKNOWN)));

    expect(find.text(claimedUrl), findsOneWidget);
    expect(find.text(S.current.wc_not_verified), findsOneWidget);
    expect(find.byType(WCWarningRow), findsNothing);
  });

  testWidgets("a matching origin shows the verified badge and no warning", (tester) async {
    await pumpBody(tester, cardOf(WCDappCardAction.sign, verifyContextOf(Validation.VALID)));

    expect(find.text(claimedUrl), findsOneWidget);
    expect(find.text(S.current.wc_verified), findsOneWidget);
    expect(find.byType(WCWarningRow), findsNothing);
  });

  testWidgets("a card without a verify context shows the claimed URL alone", (tester) async {
    await pumpBody(tester, cardOf(WCDappCardAction.connected, null));

    expect(find.text(claimedUrl), findsOneWidget);
    expect(find.text(S.current.wc_not_verified), findsNothing);
    expect(find.byType(WCWarningRow), findsNothing);
  });

  testWidgets("the signing sheet names the verified origin on a mismatch", (tester) async {
    await pumpBody(
      tester,
      WCSigningRequestSheet(
        title: S.current.wc_signing_request_title,
        swipeLabel: S.current.wc_swipe_to_sign,
        dappName: "Uniswap Interface",
        dappSubtitle: claimedUrl,
        decoded: const WCDecodedRequest(actionTitle: "Sign message"),
        walletName: "EthTest",
        address: "0x52908400098527886E0F7030069857D2E4169EE7",
        verifyContext: verifyContextOf(Validation.INVALID),
      ),
    );

    expect(find.text(verifiedOrigin), findsOneWidget);
    expect(find.text(claimedUrl), findsNothing);
    expect(find.text(S.current.wc_warning_origin_mismatch), findsOneWidget);
  });

  testWidgets("the connection sheet names the verified origin on a mismatch", (tester) async {
    const requester = ConnectionMetadata(
      publicKey: "requester key",
      metadata: PairingMetadata(name: "Uniswap Interface", description: "", url: claimedUrl),
    );
    final appStore = _MockAppStore();
    when(() => appStore.wallet).thenReturn(null);

    await pumpBody(
      tester,
      WCConnectionRequestSheet(
        proposalData: const ProposalData(
          id: 1,
          expiry: 0,
          relays: [],
          proposer: requester,
          requiredNamespaces: {},
          optionalNamespaces: {},
          pairingTopic: "pairing topic",
        ),
        requester: requester,
        walletKeyService: _MockKeyService(),
        appStore: appStore,
        verifyContext: verifyContextOf(Validation.INVALID),
      ),
    );

    expect(find.text(verifiedOrigin), findsOneWidget);
    expect(find.text(claimedUrl), findsNothing);
    expect(find.text(S.current.wc_warning_origin_mismatch), findsOneWidget);
  });
}
