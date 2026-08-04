import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class HistoryTopBar extends StatelessWidget {
  const HistoryTopBar({super.key, required this.onTap, required this.roundedBottom});

  final VoidCallback onTap;
  final bool roundedBottom;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Semantics(
        button: true,
        label: S.of(context).history,
        onTap: onTap,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                        bottom: roundedBottom ? Radius.circular(18) : Radius.zero),
                    color: Theme.of(context).colorScheme.surfaceContainer),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  child: Column(
                    spacing: 12,
                    children: [
                      SizedBox.shrink(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(S.of(context).history),
                          CakeImageWidget(
                            imageUrl: "assets/new-ui/arrow_right.svg",
                            colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                          )
                        ],
                      ),
                      if (!roundedBottom)
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(175),
                        )
                      else
                        Container(height: 2)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
