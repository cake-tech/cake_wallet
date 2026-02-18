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
    return SizedBox(
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onLightningSwitchPress();
        },
        child: Container(
          decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadiusGeometry.circular(900.0)),
              color: Theme.of(context).colorScheme.surfaceContainer),
          width: 70,
          height: 36,
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Stack(
            children: [
              AnimatedContainer(
                alignment: Alignment.centerRight,
                margin: EdgeInsets.only(left: lightningMode ? 36 : 2),
                duration: Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 32,
                height: 32,
                // height: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(9999990.0)),
                    color: Theme.of(context).colorScheme.primary),
              ),
              Container(
                child: Row(
                  spacing: 2.0,
                  children: [
                    SizedBox(),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: SvgPicture.asset(
                        key: ValueKey(lightningMode),
                        'assets/new-ui/switcher-bitcoin.svg',
                        width: 32,
                        height: 32,
                        colorFilter: ColorFilter.mode(
                          lightningMode
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: SvgPicture.asset(
                        key: ValueKey(lightningMode),
                        'assets/new-ui/switcher-lightning.svg',
                        width: 32,
                        height: 32,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}