import 'dart:ui';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';

class BlackThemeCustomColors extends CustomThemeColors {
  @override
  Color get warningContainerColor => const Color(0xFF8E5800);

  @override
  Color get warningOutlineColor => const Color(0xFFFFB84E);

  @override
  Color get backgroundMainColor => const Color(0xFF000000);

  @override
  Color get backgroundGradientColor => const Color(0xFF000000);

  @override
  Color get cardGradientColorPrimary => const Color(0xFF202023);

  @override
  Color get cardGradientColorSecondary => const Color(0xFF181819);

  @override
  Color get toggleKnobStateColor => const Color(0xFFFFFFFF);

  @override
  Color get toggleColorOffState => const Color(0xFF3A4F88);

  @override
  Color get cakePrimaryColor => const Color(0xFF52B6F0);

  @override
  Color get moneroPrimaryColor => const Color(0xFFD85128);

  @override
  Color get bitcoinPrimaryColor => const Color(0xFFF1B92F);
}
