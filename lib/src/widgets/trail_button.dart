import 'package:flutter/material.dart';

class TrailButton extends StatelessWidget {
  TrailButton({required this.caption, required this.onPressed, this.textColor});

  final String caption;
  final VoidCallback onPressed;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      minWidth: double.minPositive,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: TextButton(
        // FIX-ME: ignored padding
        //padding: EdgeInsets.all(0),
        child: Text(
          caption,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor ?? Theme.of(context).colorScheme.primary,
                height: 1.8,
              ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
