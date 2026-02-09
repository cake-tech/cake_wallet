import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppsWidget extends StatelessWidget {
  AppsWidget({
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
    this.isWide,
    this.isLink,
    this.isCake,
  });

  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final String title;
  final String subTitle;
  final Widget? hint;
  final SvgPicture? svgPicture;
  final Widget? icon;
  final String? image;
  final double? customBorder;
  final double? marginV;
  final double? marginH;
  final double? shadowSpread;
  final double? shadowBlur;
  final bool? isWide;
  final bool? isLink;
  final bool? isCake;

  @override
  Widget build(BuildContext context) {
    if (isWide == true) {
      return Stack(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: marginH ?? 20, vertical: marginV ?? 5),
            width: double.infinity,
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(18)),
              gradient: LinearGradient(
                colors: [
                  context.customColors.cardGradientColorPrimary,
                  context.customColors.cardGradientColorSecondary,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                      width: 1.25, color: Theme.of(context).colorScheme.surfaceContainerHigh),
                ),
                padding: EdgeInsets.all(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: CakeImageWidget(imageUrl: image, height: 54, width: 54),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 6.0,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                  softWrap: true,
                                ),
                                isCake == true ? CakeImageWidget(imageUrl: "assets/new-ui/cakelabs-icon.svg", color: Theme.of(context).colorScheme.onSurfaceVariant) : SizedBox(),
                              ],
                            ),
                            SizedBox(height: 5),
                            Text(
                              subTitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isLink == true ? Icons.arrow_outward : Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      )

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
    else {
      return Stack(

      );
    }
  }
}
