import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _switcherDuration = Duration(milliseconds: 250);
const _switcherCurve = Curves.easeOutCubic;
const _collapsedSegmentWidth = 40.0;
const _expandedSegmentWidth = 120.0;
const _switcherPadding = 4.0;

class LightningSwitcher extends StatelessWidget {
  const LightningSwitcher(
      {required this.lightningMode, required this.onLightningSwitchPress, super.key});

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;

  @override
  Widget build(BuildContext context) {
    const switcherWidth =
        _expandedSegmentWidth + _collapsedSegmentWidth + _switcherPadding * 2;

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
              padding: const EdgeInsets.all(_switcherPadding),
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadiusGeometry.circular(900.0),
                ),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: _switcherDuration,
                    curve: _switcherCurve,
                    left: lightningMode ? _collapsedSegmentWidth : 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: _expandedSegmentWidth,
                      decoration: ShapeDecoration(
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadiusGeometry.circular(900.0),
                        ),
                        color: Theme.of(context).colorScheme.surface
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _SwitcherSegment(
                        iconPath: 'assets/new-ui/switcher-bitcoin.svg',
                        label: 'On-chain',
                        isSelected: !lightningMode,
                      ),
                      _SwitcherSegment(
                        iconPath: 'assets/new-ui/switcher-lightning.svg',
                        label: 'Lightning',
                        isSelected: lightningMode,
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
  const _SwitcherSegment({
    required this.iconPath,
    required this.label,
    required this.isSelected,
  });

  final String iconPath;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: _switcherDuration,
      curve: _switcherCurve,
      width: isSelected ? _expandedSegmentWidth : _collapsedSegmentWidth,
      height: 32,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: _expandedSegmentWidth,
          maxWidth: _expandedSegmentWidth,
          child: Row(
            children: [
              SizedBox(
                width: _collapsedSegmentWidth,
                child: Center(
                  child: CakeImageWidget(
                    imageUrl: iconPath,
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(
                      isSelected ? colorScheme.onSurfaceVariant : colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: _switcherDuration,
                  curve: _switcherCurve,
                  opacity: isSelected ? 1 : 0,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
