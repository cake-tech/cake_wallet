import 'package:flutter/material.dart';
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
        onTap: onLightningSwitchPress,
        child: Container(
          decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadiusGeometry.circular(900.0)),
              color: Theme.of(context).colorScheme.surfaceContainer),
          width: 84,
          height: 44,
          padding: EdgeInsets.all(4),
          child: Stack(
            children: [
              AnimatedContainer(
                alignment: Alignment.centerRight,
                margin: EdgeInsets.only(left: lightningMode ? 40 : 0),
                duration: Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 36,
                height: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(900.0)),
                    color: Theme.of(context).colorScheme.primary),
              ),
              Container(
                child: Row(
                  spacing: 4.0,
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: SvgPicture.asset(
                        key: ValueKey(lightningMode),
                        'assets/new-ui/switcher-bitcoin.svg',
                        width: 36,
                        height: 36,
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
                        width: 36,
                        height: 36,
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