import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';

class StandardSlideButton extends StatefulWidget {
  const StandardSlideButton({
    Key? key,
    required this.onSlideComplete,
    this.buttonText = '',
    this.height = 48.0,
    required this.currentTheme,
  }) : super(key: key);

  final VoidCallback onSlideComplete;
  final String buttonText;
  final double height;
  final ThemeBase currentTheme;

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
    return LayoutBuilder(builder: (context, constraints) {
      final double maxWidth = constraints.maxWidth;
      effectiveMaxWidth = maxWidth - 2 * sideMargin;

      final tileBackgroundColor = widget.currentTheme.type == ThemeType.light
          ? Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor
          : widget.currentTheme.type == ThemeType.oled
              ? Colors.black.withOpacity(0.5)
              : Theme.of(context).extension<FilterTheme>()!.buttonColor;

      return Container(
        height: widget.height,
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(10), color: tileBackgroundColor),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Center(
                child: Text(widget.buttonText,
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor))),
            Positioned(
              left: sideMargin + _dragPosition,
              child: GestureDetector(
                key: ValueKey('standard_slide_button_widget_slider_key'),
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
                  key: ValueKey('standard_slide_button_widget_slider_container_key'),
                  width: sliderWidth,
                  height: widget.height - 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    key: ValueKey('standard_slide_button_widget_slider_icon_key'),
                    Icons.arrow_forward,
                    color: widget.currentTheme.type == ThemeType.bright
                        ? Theme.of(context).extension<CakeMenuTheme>()!.backgroundColor
                        : Theme.of(context).extension<FilterTheme>()!.buttonColor,
                  ),
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
