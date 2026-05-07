import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ChainIcon extends StatelessWidget {
  const ChainIcon(
      {super.key,
      required this.iconPath,
      required this.dashboardViewModel,
      required this.isSyncHeavy,
      required this.openChainSelection});

  final String iconPath;
  final bool isSyncHeavy;
  final DashboardViewModel dashboardViewModel;
  final VoidCallback openChainSelection;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final progress = dashboardViewModel.status.progress();
        final done = !isSyncHeavy || progress >= 1;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999999),
            onTap: () {
              HapticFeedback.mediumImpact();
              openChainSelection();
            },
            child: Container(
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadiusGeometry.circular(900.0),
                ),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 100),
                        opacity: done ? 0 : 1,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            value: progress,
                            color: const Color(0xFFFFB84E),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      AnimatedScale(
                        duration: const Duration(milliseconds: 150),
                        scale: done ? 1 : 0.8,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: CakeImageWidget(
                            imageUrl: iconPath,
                            key: ValueKey(progress >= 1),
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
