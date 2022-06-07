import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/market_place_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class MarketPlacePage extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: RawScrollbar(
        thumbColor: Colors.white.withOpacity(0.15),
        radius: Radius.circular(20),
        isAlwaysShown: true,
        thickness: 2,
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              Text(
                S.of(context).market_place,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).accentTextTheme.display3.backgroundColor,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: <Widget>[
                    SizedBox(height: 20),
                    MarketPlaceItem(
                      onTap: () => Navigator.of(context).pushNamed(Routes.ioniaWelcomePage),
                      title: S.of(context).cake_pay_title,
                      subTitle: S.of(context).cake_pay_subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
