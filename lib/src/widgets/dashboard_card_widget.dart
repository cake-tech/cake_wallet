import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashBoardRoundedCardWidget extends StatelessWidget {
  DashBoardRoundedCardWidget({
    this.onTap,
    required this.title,
    required this.subTitle,
    this.hint,
    this.svgPicture,
    this.image,
    this.icon,
    this.onClose,
    this.customBorder,
    this.shadowSpread,
    this.shadowBlur,
    super.key,
    this.marginV,
    this.marginH,
  });

  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final String title;
  final String subTitle;
  final Widget? hint;
  final SvgPicture? svgPicture;
  final Widget? icon;
  final Image? image;
  final double? customBorder;
  final double? marginV;
  final double? marginH;
  final double? shadowSpread;
  final double? shadowBlur;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: marginH ?? 20, vertical: marginV ?? 5),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                context.customColors.cardGradientColorPrimary,
                context.customColors.cardGradientColorSecondary,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            // border: Border.all(
            //   color: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor,
            //     width: 1
            // ),
            // boxShadow: [
            //   BoxShadow(
            //       color: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor
            //           .withAlpha(50),
            //       spreadRadius: shadowSpread ?? 3,
            //       blurRadius: shadowBlur ?? 7,
            //   )
            // ],
          ),
          child: TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                    width: 1.25, color: Theme.of(context).colorScheme.surfaceContainerHigh),
              ),
              padding: EdgeInsets.only(left: 24, top: 24, right: 20, bottom: 24),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                            softWrap: true,
                          ),
                          SizedBox(height: 5),
                          Text(
                            subTitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(left: 10)),
                    if (image != null) image! else if (svgPicture != null) svgPicture!,
                    if (icon != null) icon!
                  ],
                ),
                if (hint != null) ...[
                  SizedBox(height: 10),
                  hint!,
                ]
              ],
            ),
          ),
        ),
        if (onClose != null)
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: onClose,
              //color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
      ],
    );
  }
}
