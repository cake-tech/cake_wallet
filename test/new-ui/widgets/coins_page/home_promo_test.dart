import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/home_promo.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  late int taps;
  late List<String> dismissed;

  setUp(() {
    taps = 0;
    dismissed = [];
  });

  HomePromo promo(String name) => HomePromo(
        title: "$name title",
        description: "$name description",
        iconPath: "assets/new-ui/settings_row_icons/accounts.svg",
        onTap: () => taps++,
        onDismiss: () => dismissed.add(name),
      );

  Widget testApp(List<HomePromo> promos) => MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: HomePromoCarousel(promos: promos)),
      );

  testWidgets("a single promo shows its copy without page dots", (tester) async {
    await tester.pumpWidget(testApp([promo("Accounts")]));

    expect(find.text("Accounts title"), findsOneWidget);
    expect(find.text("Accounts description"), findsOneWidget);
    expect(find.byKey(const ValueKey("home-promo-dot-0")), findsNothing);

    await tester.tap(find.text("Accounts title"));
    await tester.tap(find.text("Don’t show this anymore"));
    expect(taps, 1);
    expect(dismissed, ["Accounts"]);
  });

  testWidgets("multiple promos can be swiped through", (tester) async {
    await tester.pumpWidget(testApp([promo("Accounts"), promo("Backup")]));

    expect(find.text("Accounts title").hitTestable(), findsOneWidget);
    expect(find.text("Backup title").hitTestable(), findsNothing);
    expect(find.byKey(const ValueKey("home-promo-dot-1")), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text("Backup title").hitTestable(), findsOneWidget);
    expect(find.text("Accounts title").hitTestable(), findsNothing);

    await tester.tap(find.text("Don’t show this anymore").hitTestable());
    expect(dismissed, ["Backup"]);
  });

  testWidgets("a title too long for one line shrinks instead of wrapping", (tester) async {
    final title = "Long promo title " * 3;
    await tester.pumpWidget(
      testApp([
        HomePromo(
          title: title,
          description: "Short",
          iconPath: "assets/new-ui/settings_row_icons/accounts.svg",
          onTap: () {},
          onDismiss: () {},
        ),
      ]),
    );

    final text = tester.widget<Text>(find.text(title));
    final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
    expect(text.style?.fontSize, lessThan(14));
    expect(text.maxLines, 1);
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets("no promos render nothing", (tester) async {
    await tester.pumpWidget(testApp([]));

    expect(find.byType(HomePromo), findsNothing);
  });
}
