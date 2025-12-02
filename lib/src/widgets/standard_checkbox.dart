import 'package:flutter/material.dart';

class StandardCheckbox extends StatelessWidget {
  StandardCheckbox(
      {required this.value,
      this.caption = '',
      this.gradientBackground = false,
      this.borderColor,
      this.iconColor,
      this.captionColor,
      required this.onChanged});

  final bool value;
  final String caption;
  final bool gradientBackground;
  final Color? borderColor;
  final Color? iconColor;
  final Color? captionColor;
  final Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final baseGradient = LinearGradient(colors: [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.primary.withOpacity(0.7),
    ], begin: Alignment.centerLeft, end: Alignment.centerRight);

    final boxBorder = Border.all(
      color: borderColor ?? Theme.of(context).colorScheme.outline,
      width: 2.0,
    );

    final checkedBoxDecoration = BoxDecoration(
      gradient: gradientBackground ? baseGradient : null,
      border: gradientBackground ? null : boxBorder,
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    );

    final uncheckedBoxDecoration =
        BoxDecoration(border: boxBorder, borderRadius: BorderRadius.all(Radius.circular(8.0)));

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 24.0,
            width: 24.0,
            decoration: value ? checkedBoxDecoration : uncheckedBoxDecoration,
            child: value
                ? Icon(
                    Icons.check,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                    size: 20.0,
                  )
                : Offstage(),
          ),
          if (caption.isNotEmpty)
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  caption,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.0,
                     
                    fontWeight: FontWeight.normal,
                    color: captionColor ?? Theme.of(context).colorScheme.onSurface,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
