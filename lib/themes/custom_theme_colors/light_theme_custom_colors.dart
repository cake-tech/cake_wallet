import 'dart:ui';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';

class LightThemeCustomColors extends CustomThemeColors {
  @override
  Color get warningContainerColor => const Color(0xFFFFCC00);
  
  @override
  Color get warningOutlineColor => const Color(0xFF312938);

  @override
  Color get backgroundMainColor => const Color(0xFF000000);
  
  @override
  Color get backgroundGradientColor => const Color(0xFFE7E7FD);
  
  @override
  Color get cardGradientColorPrimary => const Color(0xFFFFFFFF);
  
  @override
  Color get cardGradientColorSecondary => const Color(0xFFF3F3FF);
  
  @override
  Color get toggleKnobStateColor => const Color(0xFFFFFFFF);
  
  @override
  Color get toggleColorOffState => const Color(0xFFCACAE7);
}
