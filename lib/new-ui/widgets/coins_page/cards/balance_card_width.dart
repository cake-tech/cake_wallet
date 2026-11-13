import 'dart:math';

/// Width of the dashboard balance card.
///
/// Portrait desktop windows use the mobile layout, which lets the card grow
/// to 768px and push the history list off the page. Linux phones report as
/// desktop too, so a flat 40% cap is too narrow on a handset-sized window.
double balanceCardWidth({
  required double screenWidth,
  required double screenHeight,
  required bool isDesktop,
  required bool mobileLayout,
}) {
  final mobileWidth = min(screenWidth * 0.878, mobileLayout ? 768.0 : 512.0);
  if (!isDesktop || screenWidth < 700) {
    return mobileWidth;
  }

  final cap = screenHeight < 800 ? 320.0 : 512.0;
  return min(screenWidth * 0.7, cap);
}
