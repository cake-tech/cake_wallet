import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class NewPrimaryButton extends StatelessWidget {
  const NewPrimaryButton({
    required this.onPressed,
    required this.text,
    required this.color,
    required this.textColor,
    this.image,
    this.isLoading = false,
    this.borderColor = Colors.transparent,
    this.disabled = false,
    this.labelStyle,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool disabled;
  final Widget? image;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final String text;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: TextButton(
          onPressed: disabled ? null : onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              disabled ? color.withAlpha(128) : color,
            ),
            shape: WidgetStateProperty.all<RoundedSuperellipseBorder>(
              RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(18),
                side: borderColor == Colors.transparent
                    ? BorderSide.none
                    : BorderSide(color: disabled ? borderColor.withAlpha(128) : borderColor),
              ),
            ),
          ),
          child: Center(
            child: isLoading
                ? const CupertinoActivityIndicator()
                : Row(
                    spacing: 10,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (image != null) image!,
                      Text(
                        text,
                        style: labelStyle?.copyWith(color: textColor) ??
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                      ),
                    ],
                  ),
          ),
        ),
      );
}
