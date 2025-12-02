import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.text,
    required this.color,
    required this.textColor,
    this.onPressed,
    this.isDisabled = false,
    this.isDottedBorder = false,
    this.borderColor = Colors.black,
    this.onDisabledPressed,
    this.borderRadius,
    super.key,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onDisabledPressed;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final String text;
  final bool isDisabled;
  final bool isDottedBorder;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
      child: SizedBox(
        width: double.infinity,
        height: 52.0,
        child: TextButton(
          onPressed:
              isDisabled ? (onDisabledPressed != null ? onDisabledPressed : null) : onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              isDisabled ? color.withOpacity(0.5) : color,
            ),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12.0),
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? textColor.withOpacity(0.5) : textColor,
                ),
          ),
        ),
      ),
    );

    return isDottedBorder
        ? DottedBorder(
            borderType: BorderType.RRect,
            dashPattern: [6, 4],
            color: borderColor,
            strokeWidth: 2,
            radius: Radius.circular(15),
            child: content)
        : content;
  }
}

class LoadingPrimaryButton extends StatelessWidget {
  const LoadingPrimaryButton({
    required this.onPressed,
    required this.text,
    required this.color,
    required this.textColor,
    this.isDisabled = false,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final bool isDisabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
      child: SizedBox(
        width: double.infinity,
        height: 52.0,
        child: TextButton(
          onPressed: (isLoading || isDisabled)
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  onPressed.call();
                },
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(isDisabled ? color.withOpacity(0.5) : color),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              )),
          child: isLoading
              ? CupertinoActivityIndicator(animating: true, color: textColor)
              : Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? textColor.withOpacity(0.5) : textColor,
                      ),
                ),
        ),
      ),
    );
  }
}

class PrimaryIconButton extends StatelessWidget {
  const PrimaryIconButton({
    required this.onPressed,
    required this.iconData,
    required this.text,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.textColor,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.radius = 12,
    super.key,
  });

  final VoidCallback onPressed;
  final IconData iconData;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String text;
  final MainAxisAlignment mainAxisAlignment;
  final Color textColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
      child: SizedBox(
          width: double.infinity,
          height: 52.0,
          child: TextButton(
            onPressed: onPressed,
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(color),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                )),
            child: Stack(
              children: <Widget>[
                Row(
                  mainAxisAlignment: mainAxisAlignment,
                  children: <Widget>[
                    Container(
                      width: 26.0,
                      height: 52.0,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: iconBackgroundColor),
                      child: Center(
                        child: Icon(iconData, color: iconColor, size: 22.0),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 52.0,
                  child: Center(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: textColor,
                          ),
                    ),
                  ),
                )
              ],
            ),
          )),
    );
  }
}

class PrimaryImageButton extends StatelessWidget {
  const PrimaryImageButton(
      {required this.onPressed,
      required this.image,
      required this.text,
      required this.color,
      required this.textColor,
      this.borderColor = Colors.transparent,
      super.key});

  final VoidCallback onPressed;
  final Image image;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
      child: SizedBox(
        width: double.infinity,
        height: 52.0,
        child: TextButton(
          onPressed: onPressed,
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(color),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              )),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                image,
                SizedBox(width: 15),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
