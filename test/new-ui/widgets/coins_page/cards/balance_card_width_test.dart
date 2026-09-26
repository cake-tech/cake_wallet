import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card_width.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a narrow desktop window keeps the mobile card width', () {
    final width = balanceCardWidth(
      screenWidth: 400,
      screenHeight: 800,
      isDesktop: true,
      mobileLayout: true,
    );

    expect(width, closeTo(351.2, 0.01));
    expect(width, greaterThan(400 * 0.4));
  });

  test('a short wide desktop window stays capped so history fits', () {
    final width = balanceCardWidth(
      screenWidth: 1400,
      screenHeight: 700,
      isDesktop: false,
      mobileLayout: false,
    );
    final desktop = balanceCardWidth(
      screenWidth: 1400,
      screenHeight: 700,
      isDesktop: true,
      mobileLayout: false,
    );

    expect(width, closeTo(512, 0.01));
    expect(desktop, 320);
  });

  test('a tall wide desktop window uses 70 percent up to 512', () {
    final width = balanceCardWidth(
      screenWidth: 1600,
      screenHeight: 1200,
      isDesktop: true,
      mobileLayout: false,
    );

    expect(width, 512);
  });

  test('a phone keeps the mobile card width', () {
    final width = balanceCardWidth(
      screenWidth: 390,
      screenHeight: 844,
      isDesktop: false,
      mobileLayout: true,
    );

    expect(width, closeTo(390 * 0.878, 0.01));
  });
}
