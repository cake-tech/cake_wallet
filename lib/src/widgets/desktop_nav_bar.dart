import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';

class DesktopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget leading;
  final Widget middle;
  final Widget trailing;

  DesktopNavbar({
    super.key,
    required this.leading,
    required this.middle,
    required this.trailing,
  });

  ThemeBase get currentTheme => getIt.get<SettingsStore>().currentTheme;

  @override
  Widget build(BuildContext context) {
    final appBarColor =
        currentTheme.type == ThemeType.dark ? Colors.black.withOpacity(0.1) : Colors.white;

    return Container(
      padding: const EdgeInsetsDirectional.only(end: 24),
      color: appBarColor,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: leading),
            middle,
            trailing,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60);
}
