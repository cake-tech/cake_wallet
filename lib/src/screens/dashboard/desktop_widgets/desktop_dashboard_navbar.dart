import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DesktopDashboardNavbar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  final Widget leading;
  final Widget middle;
  final Widget trailing;

  DesktopDashboardNavbar({
    super.key,
    required this.leading,
    required this.middle,
    required this.trailing,
  });

  MaterialThemeBase get currentTheme => getIt.get<ThemeStore>().currentTheme;

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsetsDirectional.only(end: 24),
      color: Theme.of(context).colorScheme.surfaceContainerLowest.withOpacity(0.1),
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
  
  @override
  bool shouldFullyObstruct(BuildContext context) => false;
}
