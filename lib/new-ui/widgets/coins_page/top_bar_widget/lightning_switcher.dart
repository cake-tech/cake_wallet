import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LightningSwitcher extends StatelessWidget {
  const LightningSwitcher(
      {super.key, required this.lightningMode, required this.onLightningSwitchPress});

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;

  @override
  Widget build(BuildContext context) {
    const switcherWidth = 142.0;
    const switcherPadding = 4.0;
    const onChainSegmentWidth = 94.0;
    const lightningSegmentWidth = 40.0;

    // One toggle node: the knob position and coloured glyphs are the only
    // visual cue for which mode is active.
    return Semantics(
      button: true,
      toggled: lightningMode,
      label: S.of(context).lightning_mode,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999999),
            onTap: () {
              HapticFeedback.mediumImpact();
              onLightningSwitchPress();
            },
            child: Container(
              width: switcherWidth,
              height: 40,
              padding: const EdgeInsets.all(switcherPadding),
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadiusGeometry.circular(900.0),
                ),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: lightningMode ? onChainSegmentWidth : 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: lightningMode ? lightningSegmentWidth : onChainSegmentWidth,
                      height: 32,
                      decoration: ShapeDecoration(
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadiusGeometry.circular(900.0),
                        ),
                        color: Color.fromRGBO(215, 226, 247, 0.12),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: onChainSegmentWidth,
                        height: 32,
                        child: Row(
                          children: [
                            const SizedBox(width: 2),
                            CakeImageWidget(
                              imageUrl: 'assets/new-ui/switcher-bitcoin.svg',
                              width: 28,
                              height: 28,
                              colorFilter: ColorFilter.mode(
                                lightningMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'On-chain',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: lightningSegmentWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: CakeImageWidget(
                              imageUrl: 'assets/new-ui/switcher-lightning.svg',
                              width: 28,
                              height: 28,
                              colorFilter: ColorFilter.mode(
                                lightningMode
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                                : Theme.of(context).colorScheme.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
