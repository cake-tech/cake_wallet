import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';

class StandardSlideButton extends StatefulWidget {
  const StandardSlideButton({
    Key? key,
    required this.onSlideComplete,
    this.buttonText = '',
    this.height = 48.0,
    required this.accessibleNavigationModeButtonText,
    this.tileBackgroundColor,
    this.knobColor,
    this.isDisabled = false,
  }) : super(key: key);

  final VoidCallback onSlideComplete;
  final String buttonText;
  final double height;
  final String accessibleNavigationModeButtonText;
  final Color? tileBackgroundColor;
  final Color? knobColor;
  final bool isDisabled;

  @override
  StandardSlideButtonState createState() => StandardSlideButtonState();
}

class StandardSlideButtonState extends State<StandardSlideButton> {
  double _dragPosition = 0.0;
  double get dragPosition => _dragPosition;

  double sideMargin = 4.0;
  double effectiveMaxWidth = 0.0;
  double sliderWidth = 42.0;

  @override
  Widget build(BuildContext context) {
    final bool accessible = MediaQuery.of(context).accessibleNavigation;

    final tileBackgroundColor = widget.isDisabled
        ? context.currentTheme.customColors.backgroundGradientColor.withOpacity(0.5)
        : context.currentTheme.customColors.backgroundGradientColor;

    return accessible
        ? PrimaryButton(
            text: widget.accessibleNavigationModeButtonText,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: widget.isDisabled ? null : () => widget.onSlideComplete(),
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
                  color: (widget.isDisabled
                          ? widget.tileBackgroundColor?.withOpacity(0.5)
                          : widget.tileBackgroundColor) ??
                      tileBackgroundColor,
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
                        key: ValueKey('standard_slide_button_widget_slider_key'),
                        onHorizontalDragUpdate: widget.isDisabled
                            ? null
                            : (details) {
                                setState(() {
                                  _dragPosition += details.delta.dx;
                                  if (_dragPosition < 0) _dragPosition = 0;
                                  if (_dragPosition > effectiveMaxWidth - sliderWidth) {
                                    _dragPosition = effectiveMaxWidth - sliderWidth;
                                  }
                                });
                              },
                        onHorizontalDragEnd: widget.isDisabled
                            ? null
                            : (details) {
                                if (_dragPosition >= effectiveMaxWidth - sliderWidth - 10) {
                                  widget.onSlideComplete();
                                } else {
                                  setState(() => _dragPosition = 0);
                                }
                              },
                        child: Container(
                          key: ValueKey('standard_slide_button_widget_slider_container_key'),
                          width: sliderWidth,
                          height: widget.height - 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: widget.knobColor ?? Theme.of(context).colorScheme.surface,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            key: ValueKey('standard_slide_button_widget_slider_icon_key'),
                            Icons.arrow_forward,
                            color: widget.isDisabled ? Theme.of(context).colorScheme.onSurface.withOpacity(0.2) : Theme.of(context).colorScheme.onSurface,
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
