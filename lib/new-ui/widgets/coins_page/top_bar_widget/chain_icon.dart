import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';

class ChainIcon extends StatelessWidget {
  const ChainIcon(
      {super.key,
        required this.iconPath,
        required this.dashboardViewModel,
        required this.isSyncHeavy});

  final String iconPath;
  final bool isSyncHeavy;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final progress = dashboardViewModel.status.progress();
        final done = !isSyncHeavy || progress >= 1;

        return Stack(
          children: [
            AnimatedOpacity(
              duration: Duration(milliseconds: 100),
              opacity: done ? 0 : 1,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 100),
                child: CircularProgressIndicator(
                  key: ValueKey(progress),
                  value: progress,
                  color: Color(0xFFFFB84E),
                  strokeWidth: 2,
                ),
              ),
            ),
            AnimatedScale(
              duration: Duration(milliseconds: 150),
              scale: done ? 1 : 0.8,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 150),
                child: SvgPicture.asset(
                  key: ValueKey(progress >= 1),
                  iconPath,
                  width: 36,
                  height: 36,
                  colorFilter: ColorFilter.mode(
                      done
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withAlpha(128),
                      BlendMode.srcIn),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
