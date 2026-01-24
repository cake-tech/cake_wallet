import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewPrimaryButton extends StatelessWidget {
  const NewPrimaryButton(
      {required this.onPressed,
        this.image,
        required this.text,
        required this.color,
        required this.textColor,
        this.isLoading = false,
        this.borderColor = Colors.transparent,
        super.key});

  final VoidCallback onPressed;
  final bool isLoading;
  final SvgPicture? image;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.0,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(color),
            shape: WidgetStateProperty.all<RoundedSuperellipseBorder>(
              RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            )),
        child: Center(
          child: isLoading ? CupertinoActivityIndicator() : Row(
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
    );
  }
}