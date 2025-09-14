import 'dart:ui';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';

class DarkThemeCustomColors extends CustomThemeColors {
  @override
  Color get warningContainerColor => const Color(0xFF8E5800);

  @override
  Color get warningOutlineColor => const Color(0xFFFFB84E);

  @override
  Color get backgroundMainColor => const Color(0xFF000000);

  @override
  Color get backgroundGradientColor => const Color(0xFF0F1A36);

  @override
  Color get cardGradientColorPrimary => const Color(0xFF2B3A67);

  @override
  Color get cardGradientColorSecondary => const Color(0xFF1C2A4F);

  @override
  Color get toggleKnobStateColor => const Color(0xFFFFFFFF);

  @override
  Color get toggleColorOffState => const Color(0xFF3A4F88);

  @override
  Color? get cakePrimaryColor => null;

  @override
  Color? get moneroPrimaryColor => null;

  @override
  Color? get bitcoinPrimaryColor => null;
}
