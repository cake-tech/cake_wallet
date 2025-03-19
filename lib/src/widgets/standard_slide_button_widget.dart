import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:flutter/material.dart';

class StandardSlideButton extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final String buttonText;
  final double height;

  const StandardSlideButton({
    Key? key,
    required this.onSlideComplete,
    this.buttonText = '',
    this.height = 48.0,
  }) : super(key: key);

  @override
  _StandardSlideButtonState createState() => _StandardSlideButtonState();
}

class _StandardSlideButtonState extends State<StandardSlideButton> {
  double _dragPosition = 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxWidth = constraints.maxWidth;
      const double sideMargin = 4.0;
      final double effectiveMaxWidth = maxWidth - 2 * sideMargin;
      const double sliderWidth = 42.0;

      return Container(
        height: widget.height,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).extension<CakeMenuTheme>()!.backgroundColor),
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
                    color: Theme.of(context).extension<FilterTheme>()!.buttonColor,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.arrow_forward,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
