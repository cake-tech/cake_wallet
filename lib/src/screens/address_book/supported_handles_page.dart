import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/handles_list_widget.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class SupportedHandlesPage extends BasePage {
  SupportedHandlesPage();

  @override
  String? get title => 'Supported Handles';

  @override
  Widget body(BuildContext context) {
    final fillColor = currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark
        : CustomThemeColors.backgroundGradientColorLight;

    return HandlesListWidget(items: supportedSources, fillColor: fillColor);
  }
}


