import "dart:async";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_listener_widget.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_sheet_header.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_signing_request_sheet.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_wallet_card.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "sheet_test_app.dart";

WCDecodedRequest unlimitedApprove() => WCDecodedRequest(
  actionTitle: "Approve",
  warnings: [S.current.wc_warning_unlimited_approval, S.current.wc_warning_unknown_token],
  rows: const [
    WCDecodedRow(label: "Token", value: "Tether USD (USDT)"),
    WCDecodedRow(label: "Amount", value: "Unlimited USDT", kind: WCDecodedRowKind.amount),
    WCDecodedRow(
      label: "Approved spender",
      value: "0x1111111254eeb25477b68fb85ed929f73a960582",
      kind: WCDecodedRowKind.address,
    ),
  ],
);

const approveInfoRows = [
  WCDecodedRow(label: "Method", value: "eth_sendTransaction"),
  WCDecodedRow(label: "Chain ID", value: "eip155:1"),
  WCDecodedRow(label: "Transport Type", value: "RELAY"),
];

const oneLineMessage = WCDecodedRequest(
  actionTitle: "Sign message",
  rows: [WCDecodedRow(label: "Message", value: "hello")],
);

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
    required WCDecodedRequest decoded,
    List<WCDecodedRow> infoRows = const [],
    int? signAllCount,
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

    final answers = <Object?>[];
    unawaited(
      service
          .queueBottomSheet(
            widget: WCSigningRequestSheet(
              title: S.current.wc_approve_request_title,
              swipeLabel: S.current.wc_swipe_to_approve,
              dappName: "Uniswap Interface",
              dappSubtitle: "https://app.uniswap.org",
              decoded: decoded,
              infoRows: infoRows,
              walletName: "EthTest",
              address: "0x52908400098527886E0F7030069857D2E4169EE7",
              signAllCount: signAllCount,
            ),
          )
          .then(answers.add),
    );
    await pumpSheetFrames(tester);

    return answers;
  }

  final sheetScrollView = find.byType(CustomScrollView);

  ScrollPosition sheetScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(of: sheetScrollView, matching: find.byType(Scrollable)).first,
      )
      .position;

  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.drag(sheetScrollView, const Offset(0, -2000));
    await pumpSheetFrames(tester);
  }

  for (final size in phoneSizes) {
    testWidgets(
      "an approve cannot be swiped on a $size phone before its details were scrolled past",
      (tester) async {
        final answers = await showSheet(
          tester,
          size,
          decoded: unlimitedApprove(),
          infoRows: approveInfoRows,
        );

        expect(find.byType(ConfirmSwiper).hitTestable(), findsNothing);
        final pinnedSwiperY = tester.getRect(find.byType(WCSigningRequestSheet)).bottom - 44;
        await tester.dragFrom(Offset(size.width / 2, pinnedSwiperY), const Offset(400, 0));
        await pumpSheetFrames(tester);
        expect(answers, isEmpty);

        await scrollToEnd(tester);
        expect(sheetScroll(tester).extentAfter, closeTo(0, 0.01));
        final lastCardRow = tester.getRect(find.text("Transport Type"));
        final walletCard = tester.getRect(find.byType(WCWalletCard));
        final swiper = tester.getRect(find.byType(ConfirmSwiper));
        expect(lastCardRow.bottom, lessThan(walletCard.top));
        expect(walletCard.bottom, lessThan(swiper.top));

        await tester.drag(find.byType(ConfirmSwiper), const Offset(400, 0));
        await pumpSheetFrames(tester);

        expect(answers, [WCBottomSheetResult.one]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in const [Size(390, 844), Size(412, 915)]) {
    testWidgets("a one line message on a $size phone hugs the sheet and needs no scroll", (
      tester,
    ) async {
      final answers = await showSheet(tester, size, decoded: oneLineMessage);

      final sheet = tester.getRect(find.byType(WCSigningRequestSheet));
      expect(sheet.height, lessThan(size.height * 0.9 - 40));
      expect(sheet.bottom, size.height - 24);
      expect(sheetScroll(tester).maxScrollExtent, 0);

      await tester.drag(find.byType(ConfirmSwiper), const Offset(400, 0));
      await pumpSheetFrames(tester);

      expect(answers, [WCBottomSheetResult.one]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("the sign all button sits below the swiper, at the end of the scroll", (
    tester,
  ) async {
    final answers = await showSheet(
      tester,
      const Size(360, 640),
      decoded: unlimitedApprove(),
      signAllCount: 3,
    );
    final signAll = find.descendant(
      of: sheetScrollView,
      matching: find.text(S.current.wc_sign_all_count("3")),
    );
    expect(signAll.hitTestable(), findsNothing);

    await scrollToEnd(tester);
    expect(
      tester.getRect(signAll).top,
      greaterThan(tester.getRect(find.byType(ConfirmSwiper)).bottom),
    );
    await tester.tap(signAll);
    await pumpSheetFrames(tester);

    expect(answers, [WCBottomSheetResult.all]);
  });

  testWidgets("a 20000 row request builds only the rows near the screen and ends at the swiper", (
    tester,
  ) async {
    final rows = [
      for (var index = 0; index < 20000; index++)
        WCDecodedRow(label: "Row $index", value: "value $index"),
    ];

    final answers = await showSheet(
      tester,
      const Size(390, 844),
      decoded: WCDecodedRequest(actionTitle: "Sign all", rows: rows),
    );

    expect(find.byType(SelectableText, skipOffstage: false).evaluate().length, lessThan(50));
    expect(find.byType(ConfirmSwiper).hitTestable(), findsNothing);

    while (sheetScroll(tester).extentAfter > 0.01) {
      await tester.drag(sheetScrollView, const Offset(0, -8000));
      await tester.pump();
    }
    await pumpSheetFrames(tester);

    expect(find.text("value 19999"), findsOneWidget);
    await tester.drag(find.byType(ConfirmSwiper), const Offset(400, 0));
    await pumpSheetFrames(tester);

    expect(answers, [WCBottomSheetResult.one]);
    expect(tester.takeException(), isNull);
  });

  group("reject button", () {
    testWidgets("is a labelled 48 px button", (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        sheetTestApp(
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: WCSheetHeader(title: "Approve"),
            ),
          ),
        ),
      );

      final reject = find.bySemanticsLabel(S.current.reject);
      expect(tester.getSize(reject), const Size(48, 48));
      expect(
        tester.getSemantics(reject),
        matchesSemantics(
          label: S.current.reject,
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets("rejects the request", (tester) async {
      final answers = await showSheet(tester, const Size(390, 844), decoded: oneLineMessage);

      await tester.tap(find.bySemanticsLabel(S.current.reject));
      await pumpSheetFrames(tester);

      expect(answers, [WCBottomSheetResult.reject]);
    });
  });
}
