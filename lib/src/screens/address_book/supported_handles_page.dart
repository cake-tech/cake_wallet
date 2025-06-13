import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
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

class HandlesListWidget extends StatelessWidget {
  const HandlesListWidget({
    super.key,
    required this.items,
    required this.fillColor,
  });

  final List<AddressSource> items;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final src = items[index];
        return ListTile(
          title: Text(src.label, style: Theme
              .of(context)
              .textTheme
              .bodyMedium),
          trailing: Text(src.alias, style: Theme
              .of(context)
              .textTheme
              .bodyMedium),
          tileColor: fillColor,
          dense: true,
          visualDensity: VisualDensity(horizontal: 0, vertical: -3),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          leading: ImageUtil.getImageFromPath(imagePath: src.iconPath, height: 24, width: 24),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          onTap: () {},
        );
      },
    );
  }
}
