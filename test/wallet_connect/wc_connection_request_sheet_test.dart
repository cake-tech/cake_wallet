import "dart:async";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_listener_widget.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_connection_request_sheet.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_permissions_card.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:reown_walletkit/reown_walletkit.dart";

import "sheet_test_app.dart";
import "wc_service_rig.dart";

const _address = "0x52908400098527886E0F7030069857D2E4169EE7";

const _manyMethods = [
  "eth_sendTransaction",
  "personal_sign",
  "wallet_switchEthereumChain",
  "wallet_getCapabilities",
  "wallet_sendCalls",
  "wallet_getCallsStatus",
  "wallet_showCallsStatus",
  "wallet_watchAsset",
  "wallet_scanQRCode",
  "wallet_requestPermissions",
  "wallet_getPermissions",
];

void main() {
  setUpAll(() async {
    S.current = const S();
    await loadSheetFonts();
  });

  Future<void> pumpSheetFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<List<Object?>> showSheet(
    WidgetTester tester,
    Size size, {
    required List<String> methods,
  }) async {
    setPhoneSize(tester, size);
    final service = BottomSheetServiceImpl();
    await tester.pumpWidget(
      sheetTestApp(
        home: BottomSheetListener(
          bottomSheetService: service,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );

    const requester = ConnectionMetadata(
      publicKey: "requester key",
      metadata: PairingMetadata(
        name: "Uniswap Interface",
        description: "",
        url: "https://app.uniswap.org",
      ),
    );
    final answers = <Object?>[];
    unawaited(
      service
          .queueBottomSheet(
            widget: WCConnectionRequestSheet(
              proposalData: ProposalData(
                id: 1,
                expiry: 0,
                relays: const [],
                proposer: requester,
                requiredNamespaces: const {},
                optionalNamespaces: const {},
                pairingTopic: "pairing topic",
                generatedNamespaces: {
                  "eip155": Namespace(
                    accounts: const ["eip155:1:$_address"],
                    methods: methods,
                    events: const [],
                  ),
                },
              ),
              requester: requester,
              walletKeyService: RigKeyService(),
              appStore: RigAppStore()
                ..wallet = RigWallet(
                  "EthTest",
                  address: _address,
                  privateKey: "",
                  chains: const ["eip155:1"],
                ),
            ),
          )
          .then(answers.add),
    );
    await pumpSheetFrames(tester);

    return answers;
  }

  final sheetScrollView = find.byType(SingleChildScrollView);

  ScrollPosition sheetScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(of: sheetScrollView, matching: find.byType(Scrollable)).first,
      )
      .position;

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets(
      "a connection cannot be approved on a $size phone before its permissions were scrolled past",
      (tester) async {
        final answers = await showSheet(tester, size, methods: _manyMethods);

        expect(find.byType(ConfirmSwiper).hitTestable(), findsNothing);
        final pinnedSwiperY = tester.getRect(find.byType(WCConnectionRequestSheet)).bottom - 44;
        await tester.dragFrom(Offset(size.width / 2, pinnedSwiperY), const Offset(400, 0));
        await pumpSheetFrames(tester);
        expect(answers, isEmpty);

        await tester.drag(sheetScrollView, const Offset(0, -2000));
        await pumpSheetFrames(tester);
        expect(sheetScroll(tester).extentAfter, closeTo(0, 0.01));
        expect(
          tester.getRect(find.byType(WCPermissionsCard)).bottom,
          lessThan(tester.getRect(find.byType(ConfirmSwiper)).top),
        );

        await tester.drag(find.byType(ConfirmSwiper), const Offset(400, 0));
        await pumpSheetFrames(tester);

        expect(answers, [WCBottomSheetResult.one]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets("a connection with one permission group hugs the sheet and needs no scroll", (
    tester,
  ) async {
    const size = Size(390, 844);
    final answers = await showSheet(tester, size, methods: const ["personal_sign"]);

    final sheet = tester.getRect(find.byType(WCConnectionRequestSheet));
    expect(sheet.height, lessThan(size.height * 0.9 - 40));
    expect(sheet.bottom, size.height - 24);
    expect(sheetScroll(tester).maxScrollExtent, 0);

    await tester.drag(find.byType(ConfirmSwiper), const Offset(400, 0));
    await pumpSheetFrames(tester);

    expect(answers, [WCBottomSheetResult.one]);
    expect(tester.takeException(), isNull);
  });
}
