import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashBoardRoundedCardWidget extends StatelessWidget {
  DashBoardRoundedCardWidget({
    required this.onTap,
    required this.title,
    required this.subTitle,
    this.hint,
    this.svgPicture,
    this.image,
    this.icon,
    this.onClose,
    this.customBorder,
  });

  final VoidCallback onTap;
  final VoidCallback? onClose;
  final String title;
  final String subTitle;
  final Widget? hint;
  final SvgPicture? svgPicture;
  final Widget? icon;
  final Image? image;
  final double? customBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
              borderRadius: BorderRadius.circular(customBorder ?? 20),
              border: Border.all(
                color: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor,
              ),
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
                            style: TextStyle(
                              color:
                                  Theme.of(context).extension<DashboardPageTheme>()!.cardTextColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                            softWrap: true,
                          ),
                          SizedBox(height: 5),
                          Text(
                            subTitle,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .extension<DashboardPageTheme>()!
                                    .cardTextColor,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Lato'),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    if (image != null) image!
                    else if (svgPicture != null) svgPicture!,
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
          if (onClose != null)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: onClose,
                color: Theme.of(context).extension<DashboardPageTheme>()!.cardTextColor,
              ),
            ),
        ],
      ),
    );
  }
}
