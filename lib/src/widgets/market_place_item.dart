import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';

class MarketPlaceItem extends StatelessWidget {


  MarketPlaceItem({
    required this.onTap,
    required this.title,
    required this.subTitle,
  });

  final VoidCallback onTap;
  final String title;
  final String subTitle;

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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      subTitle,
                      style: TextStyle(
                          color:  Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Lato'),
                    )
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

