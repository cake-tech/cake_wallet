import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LightningSwitcher extends StatelessWidget {
  const LightningSwitcher(
      {super.key, required this.lightningMode, required this.onLightningSwitchPress});

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;

  @override
  Widget build(BuildContext context) {
    // One toggle node: the knob position and the coloured glyphs are the only
    // visual cue for which mode is active.
    return Semantics(
      button: true,
      toggled: lightningMode,
      label: S.of(context).lightning_mode,
      child: SizedBox(
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onLightningSwitchPress();
          },
          child: Container(
            decoration: ShapeDecoration(
                shape:
                    RoundedSuperellipseBorder(borderRadius: BorderRadiusGeometry.circular(900.0)),
                color: Theme.of(context).colorScheme.surfaceContainer),
            width: 63,
            height: 36,
            padding: const EdgeInsets.all(4.5),
            child: Stack(
              children: [
                AnimatedContainer(
                  alignment: Alignment.centerRight,
                  margin: EdgeInsets.only(left: lightningMode ? 27 : 0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(9999990.0)),
                      color: Theme.of(context).colorScheme.primary),
                ),
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: CakeImageWidget(
                        imageUrl: 'assets/new-ui/switcher-bitcoin.svg',
                        key: ValueKey(lightningMode),
                        width: 27,
                        height: 27,
                        colorFilter: ColorFilter.mode(
                          lightningMode
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: CakeImageWidget(
                        imageUrl: 'assets/new-ui/switcher-lightning.svg',
                        key: ValueKey(lightningMode),
                        width: 27,
                        height: 27,
                        colorFilter: ColorFilter.mode(
                          lightningMode
                              ? Theme.of(context).colorScheme.surfaceContainer
                              : Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
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
