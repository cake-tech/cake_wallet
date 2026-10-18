import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';

class ChainIcon extends StatelessWidget {
  const ChainIcon(
      {super.key,
      required this.iconPath,
      required this.dashboardViewModel,
      required this.isSyncHeavy,
      required this.showSyncedMessage});

  final String iconPath;
  final bool isSyncHeavy;
  final DashboardViewModel dashboardViewModel;
  final bool showSyncedMessage;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final progress = dashboardViewModel.status.progress();
        final done = !showSyncedMessage && (!isSyncHeavy || progress >= 1);

        return Stack(
          children: [
            AnimatedOpacity(
              duration: Duration(milliseconds: 100),
              opacity: done ? 0 : 1,
              // Faded out means "nothing to report", so it must leave the tree too.
              child: ExcludeSemantics(
                excluding: done || showSyncedMessage,
                child: CircularProgressIndicator(
                  value: progress,
                  color: showSyncedMessage ? Color(0xFFFF12A439) : Color(0xFFFFB84E),
                  strokeWidth: 2,
                  semanticsLabel: S.of(context).synchronizing,
                  semanticsValue: "${(progress * 100).round()}%",
                ),
              ),
            ),
            AnimatedScale(
              duration: Duration(milliseconds: 150),
              scale: done ? 1 : 0.8,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 150),
                child: CakeImageWidget(
                  imageUrl: iconPath,
                  key: ValueKey(progress >= 1),
                  width: 36,
                  height: 36,
                  colorFilter: ColorFilter.mode(
                    done
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
