import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewPrimaryButton extends StatelessWidget {
  const NewPrimaryButton(
      {required this.onPressed,
        this.image,
        required this.text,
        required this.color,
        required this.textColor,
        this.borderColor = Colors.transparent,
        super.key});

  final VoidCallback onPressed;
  final SvgPicture? image;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
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
              spacing: 10,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if(image != null) image!,
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
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