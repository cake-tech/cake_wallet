import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class StandardSlideButton extends StatefulWidget {
  const StandardSlideButton({
    Key? key,
    required this.onSlideComplete,
    this.buttonText = '',
    this.height = 48.0,
    required this.currentTheme,
    required this.accessibleNavigationModeButtonText,
  }) : super(key: key);

  final VoidCallback onSlideComplete;
  final String buttonText;
  final double height;
  final MaterialThemeBase currentTheme;
  final String accessibleNavigationModeButtonText;

  @override
  _StandardSlideButtonState createState() => _StandardSlideButtonState();
}

class _StandardSlideButtonState extends State<StandardSlideButton> {
  double _dragPosition = 0.0;

  @override
  Widget build(BuildContext context) {
    final bool accessible = MediaQuery.of(context).accessibleNavigation;

    final tileBackgroundColor = widget.currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark
        : CustomThemeColors.backgroundGradientColorLight;

    return accessible
        ? PrimaryButton(
            text: widget.accessibleNavigationModeButtonText,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => widget.onSlideComplete(),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              const double sideMargin = 4.0;
              final double effectiveMaxWidth = maxWidth - 2 * sideMargin;
              const double sliderWidth = 42.0;

              return Container(
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: tileBackgroundColor,
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Center(
                      child: Text(
                        widget.buttonText,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Positioned(
                      left: sideMargin + _dragPosition,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragPosition += details.delta.dx;
                            if (_dragPosition < 0) _dragPosition = 0;
                            if (_dragPosition > effectiveMaxWidth - sliderWidth) {
                              _dragPosition = effectiveMaxWidth - sliderWidth;
                            }
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          if (_dragPosition >= effectiveMaxWidth - sliderWidth - 10) {
                            widget.onSlideComplete();
                          } else {
                            setState(() => _dragPosition = 0);
                          }
                        },
                        child: Container(
                          width: sliderWidth,
                          height: widget.height - 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_forward,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
  }
}
