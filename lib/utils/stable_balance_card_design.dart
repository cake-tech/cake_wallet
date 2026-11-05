import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_currency.dart";

/// Stable Balance's card look for the Lightning card, fed into [CardDesign]'s generic
/// `specialDesignOverride`/`extraIconPaths` hooks so `cw_core` stays coin-agnostic.
///
/// Everything here only applies while Stable Balance is actually switched on - not just
/// "eligible", since USDB auto-enables by default for every Lightning wallet.
class StableBalanceCardDesign {
  /// A sketch placeholder for the icon-style option - a hand-drawn `$` SVG, not final design art.
  static const String iconPath = "assets/new-ui/balance_card_icons/stable_balance.svg";

  /// A green card - the real `gradientGreen`/`CardColorCombination.light` pairing already used
  /// elsewhere in the palette. The background graphic is a sketch placeholder; swap the asset
  /// file for real art later without touching this wiring.
  static const design = CardDesign(
    gradient: CardDesign.gradientGreen,
    backgroundType: CardDesignBackgroundTypes.svgFull,
    imagePath: "assets/new-ui/balance_card_backgrounds/stable_balance.svg",
    colors: CardColorCombination.light,
  );

  static const _icon = CardIconPath(iconPath);

  static bool appliesTo(CryptoCurrency currency, {required bool stableBalanceActive}) =>
      currency == CryptoCurrency.btcln && stableBalanceActive;

  static CardDesign? specialDesignOverride(
    CryptoCurrency currency, {
    required bool stableBalanceActive,
  }) =>
      appliesTo(currency, stableBalanceActive: stableBalanceActive) ? design : null;

  static List<CardIconPath> extraIconPaths(
    CryptoCurrency currency, {
    required bool stableBalanceActive,
  }) =>
      appliesTo(currency, stableBalanceActive: stableBalanceActive) ? const [_icon] : const [];

  /// [CardDesign.fromStyleSettings] with the Stable Balance overrides applied.
  static CardDesign fromStyleSettings(
    BalanceCardStyleSettings? setting,
    CryptoCurrency currency, {
    required bool stableBalanceActive,
  }) =>
      CardDesign.fromStyleSettings(
        setting,
        currency,
        specialDesignOverride:
            specialDesignOverride(currency, stableBalanceActive: stableBalanceActive),
        extraIconPaths: extraIconPaths(currency, stableBalanceActive: stableBalanceActive),
      );
}
