import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _switcherDuration = Duration(milliseconds: 250);
const _switcherCurve = Curves.easeOutCubic;
const _switcherHeight = 32.0;
const _switcherPadding = 2.0;
const _segmentIconSize = 24.0;
const _switcherBorderWidth = 0.5;

const _onChainIconPath = "assets/new-ui/switcher-bitcoin.svg";
const _lightningIconPath = "assets/new-ui/switcher-lightning.svg";


class LightningSwitcher extends StatelessWidget {
  const LightningSwitcher({
    required this.lightningMode,
    required this.onLightningSwitchPress,
    super.key,
  });

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      identifier: "home_page_lightning_switch_key",
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
              width: double.infinity,
              height: _switcherHeight,
              padding: const EdgeInsets.all(_switcherPadding),
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadiusGeometry.circular(900.0),
                ),
                color: colorScheme.surfaceContainerLowest,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedAlign(
                    duration: _switcherDuration,
                    curve: _switcherCurve,
                    alignment: lightningMode ? Alignment.centerRight : Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadiusGeometry.circular(900.0),
                            side: BorderSide(
                              width: _switcherBorderWidth,
                              color: colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          color: colorScheme.surfaceContainer,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _SwitcherSegment(
                          iconPath: _onChainIconPath,
                          isSelected: !lightningMode,
                        ),
                      ),
                      Expanded(
                        child: _SwitcherSegment(
                          iconPath: _lightningIconPath,
                          isSelected: lightningMode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitcherSegment extends StatelessWidget {
  const _SwitcherSegment({required this.iconPath, required this.isSelected});

  final String iconPath;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: CakeImageWidget(
        imageUrl: iconPath,
        width: _segmentIconSize,
        height: _segmentIconSize,
        colorFilter: ColorFilter.mode(
          isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
