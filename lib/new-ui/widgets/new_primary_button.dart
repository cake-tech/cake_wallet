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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
