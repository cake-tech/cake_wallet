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
        final addedNetwork = dashboardViewModel.addedNetwork;
        final progressColor = showSyncedMessage ? Color(0xFFFF12A439) : Color(0xFFFFB84E);

        return Stack(
          children: [
            AnimatedOpacity(
              duration: Duration(milliseconds: 100),
              opacity: done ? 0 : 1,
              // Faded out means "nothing to report", so it must leave the tree too.
              child: ExcludeSemantics(
                excluding: done || showSyncedMessage,
                child: addedNetwork != null
                    ? Semantics(
                        label: S.of(context).synchronizing,
                        value: "${(progress * 100).round()}%",
                        child: CustomPaint(
                          size: const Size.square(36),
                          painter: _RoundedSquareProgressPainter(
                            progress: progress,
                            color: progressColor,
                          ),
                        ),
                      )
                    : CircularProgressIndicator(
                        value: progress,
                        color: progressColor,
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
                child: addedNetwork != null
                    ? Opacity(
                        key: ValueKey(progress >= 1),
                        opacity: done ? 0.2 : 1,
                        child: CakeImageWidget(
                          imageUrl: addedNetwork.iconPath,
                          width: 36,
                          height: 36,
                          isRoundedSquare: true,
                          isOutlined: true,
                          fallbackName: addedNetwork.name,
                        ),
                      )
                    : CakeImageWidget(
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

class _RoundedSquareProgressPainter extends CustomPainter {
  const _RoundedSquareProgressPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(
        rect.deflate(_strokeWidth / 2),
        Radius.circular(size.width * CakeImageWidget.networkIconCornerRatio),
      ));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in outline.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)), paint);
    }
  }

  @override
  bool shouldRepaint(_RoundedSquareProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
