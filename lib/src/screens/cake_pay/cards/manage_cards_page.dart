import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/card_menu.dart';
import 'package:cake_wallet/src/widgets/market_place_item.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class ManageCardsPage extends BasePage {
  @override
  Color get backgroundLightColor => currentTheme.type == ThemeType.bright ? Colors.transparent : Colors.white;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  Color get titleColor => currentTheme.type == ThemeType.bright ? Colors.white : Colors.black;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper => (BuildContext context, Widget scaffold) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: scaffold,
      );

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget get endDrawer => CardMenu();

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).manage_cards,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).accentTextTheme.display3.backgroundColor,
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget trailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TrailingIcon(
          asset: 'assets/images/card.png',
          onPressed: () {},
        ),
        SizedBox(width: 16),
        _TrailingIcon(
          asset: 'assets/images/profile.png',
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    final filterIcon = Image.asset(
      'assets/images/filter.png',
      color: Theme.of(context).textTheme.caption.decorationColor,
    );

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          MarketPlaceItem(
            onTap: () {},
            title: S.of(context).setup_your_debit_card,
            subTitle: S.of(context).no_id_required,
          ),
          SizedBox(height: 48),
          Container(
            padding: EdgeInsets.only(left: 2, right: 22),
            height: 32,
            child: Row(
              children: [
                Expanded(child: _SearchWidget()),
                SizedBox(width: 10),
                Container(
                  width: 32,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: filterIcon,
                )
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: RawScrollbar(
              thumbColor: Colors.white.withOpacity(0.15),
              radius: Radius.circular(20),
              isAlwaysShown: true,
              thickness: 2,
              controller: _scrollController,
              child: ListView.separated(
                padding: EdgeInsets.only(left: 2, right: 22),
                controller: _scrollController,
                itemCount: 20,
                separatorBuilder: (_, __) => SizedBox(height: 4),
                itemBuilder: (_, index) {
                  return MarketPlaceItem(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    logoUrl: '',
                    onTap: ()=>Navigator.of(context).pushNamed(Routes.buyGiftCardPage),
                    title: 'Amazon',
                    subTitle: 'Onlin',
                    hasDiscount: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchWidget extends StatelessWidget {
  const _SearchWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchIcon = Padding(
      padding: EdgeInsets.all(8),
      child: Image.asset(
        'assets/images/search_icon.png',
        color: Theme.of(context).textTheme.caption.decorationColor,
      ),
    );

    return TextField(
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
          filled: true,
          contentPadding: EdgeInsets.only(
            top: 10,
            left: 10,
          ),
          fillColor: Colors.white.withOpacity(0.15),
          hintText: 'Search',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          alignLabelWithHint: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          suffixIcon: searchIcon,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(10),
          )),
    );
  }
}

class _TrailingIcon extends StatelessWidget {
  final String asset;
  final VoidCallback onPressed;

  const _TrailingIcon({this.asset, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      width: 25,
      child: FlatButton(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        padding: EdgeInsets.all(0),
        onPressed: onPressed,
        child: Image.asset(
          asset,
          color: Theme.of(context).accentTextTheme.display3.backgroundColor,
        ),
      ),
    );
  }
}
