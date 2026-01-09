import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:flutter/material.dart';

class SelectButton extends StatelessWidget {
  SelectButton({
    required this.text,
    required this.onTap,
    this.image,
    this.isSelected = false,
    this.showTrailingIcon = true,
    this.height = 60,
    this.textSize = 18,
    this.color,
    this.textColor,
    this.arrowColor,
    this.borderColor,
    this.deviceConnectionTypes,
    this.borderRadius,
    this.padding,
    this.leading,
    super.key,
  });

  final Widget? image;
  final String text;
  final double textSize;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showTrailingIcon;
  final List<DeviceConnectionType>? deviceConnectionTypes;
  final double height;
  final Color? color;
  final Color? textColor;
  final Color? arrowColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ?? (isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainer);
    final effectiveTextColor = textColor ??
        (isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface);
    final effectiveArrowColor = arrowColor ??
        (isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface);

    final trailingIcons = <Image>[];
    final selectArrowImage =
        Image.asset('assets/images/select_arrow.png', color: effectiveArrowColor);

    deviceConnectionTypes?.forEach((element) => trailingIcons.add(Image.asset(
          element.iconString,
          color: effectiveArrowColor,
          height: 24,
        )));

    if (showTrailingIcon) trailingIcons.add(selectArrowImage);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        padding: padding ?? EdgeInsets.only(left: 30, right: 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.all(Radius.circular(15)),
          color: backgroundColor,
          border: borderColor != null ? Border.all(color: borderColor!, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            leading ?? Offstage(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  image ?? Offstage(),
                  Padding(
                    padding: image != null ? EdgeInsets.only(left: 15) : EdgeInsets.only(left: 0),
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: textSize,
                        fontWeight: FontWeight.w500,
                        color: effectiveTextColor,
                      ),
                    ),
                  )
                ],
              ),
            ),
            ...trailingIcons
          ],
        ),
      ),
    );
  }
}
