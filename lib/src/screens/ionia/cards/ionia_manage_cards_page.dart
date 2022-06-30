import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/card_item.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/card_menu.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/ionia/ionia_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class IoniaManageCardsPage extends BasePage {
   IoniaManageCardsPage(this._ioniaViewModel);
  final IoniaViewModel _ioniaViewModel;

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
  Widget leading(BuildContext context) {
    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: Theme.of(context).accentTextTheme.display3.backgroundColor,
      size: 16,
    );

    return SizedBox(
      height: 37,
      width: 37,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            padding: EdgeInsets.all(0),
            onPressed: () => Navigator.pop(context),
            child: _backButton),
      ),
    );
  }

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).manage_cards,
      style: textLargeSemiBold(
        color: Theme.of(context).accentTextTheme.display3.backgroundColor,
      ),
    );
  }


  @override
  Widget trailing(BuildContext context) {
    return 
        _TrailingIcon(
          asset: 'assets/images/profile.png',
          onPressed: () {},
    );
  }

  @override
  Widget body(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 2, right: 22),
            height: 32,
            child:  _SearchWidget()
            
          ),
          SizedBox(height: 8),
          Expanded(
            child: Observer(builder: (_) {
              return IoniaManageCardsPageBody(scrollOffsetFromTop: _ioniaViewModel.scrollOffsetFromTop, 
              ioniaMerchants: _ioniaViewModel.ioniaMerchants, 
              onSetScrollOffset: (offset) => _ioniaViewModel.setScrollOffsetFromTop(offset),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class IoniaManageCardsPageBody extends StatefulWidget {
  const IoniaManageCardsPageBody({
    Key key,
    @required this.scrollOffsetFromTop,
    @required this.ioniaMerchants,
     @required this.onSetScrollOffset,
  }) : super(key: key);


  final List<IoniaMerchant> ioniaMerchants;
  final double scrollOffsetFromTop;
  final Function(double) onSetScrollOffset;

  @override
  _IoniaManageCardsPageBodyState createState() => _IoniaManageCardsPageBodyState();
}

class _IoniaManageCardsPageBodyState extends State<IoniaManageCardsPageBody> {

   double get backgroundHeight => MediaQuery.of(context).size.height * 0.75;
   double  thumbHeight = 72;
   bool get isAlwaysShowScrollThumb => merchantsList == null ? false : merchantsList.length > 3;


  List<IoniaMerchant> get merchantsList => widget.ioniaMerchants;

  final _scrollController = ScrollController();

@override
  void initState() {
    _scrollController.addListener(() {
      final scrollOffsetFromTop = _scrollController.hasClients
          ? (_scrollController.offset / _scrollController.position.maxScrollExtent * (backgroundHeight - thumbHeight))
          : 0.0;
      widget.onSetScrollOffset(scrollOffsetFromTop);
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListView.separated(
        padding: EdgeInsets.only(left: 2, right: 22),
        controller: _scrollController,
        itemCount: merchantsList.length,
        separatorBuilder: (_, __) => SizedBox(height: 4),
        itemBuilder: (_, index) {
          final merchant = merchantsList[index];
          return CardItem(
            logoUrl: merchant.logoUrl,
            onTap: () => Navigator.of(context).pushNamed(Routes.ioniaBuyGiftCardPage, arguments: [merchant]),
            title: merchant.legalName,
            subTitle: merchant.isOnline ? S.of(context).online : S.of(context).offline,
            backgroundColor: Theme.of(context).textTheme.title.backgroundColor,
            titleColor: Theme.of(context).accentTextTheme.display3.backgroundColor,
            subtitleColor: Theme.of(context).accentTextTheme.display2.backgroundColor,
            discount: merchant.minimumDiscount,
          );
        },
      ),
      isAlwaysShowScrollThumb
          ? CakeScrollbar(
              backgroundHeight: backgroundHeight,
              thumbHeight: thumbHeight,
              rightOffset: 1,
              width: 3,
              backgroundColor: Theme.of(context).textTheme.caption.decorationColor.withOpacity(0.05),
              thumbColor: Theme.of(context).textTheme.caption.decorationColor.withOpacity(0.5),
              fromTop: widget.scrollOffsetFromTop,
            )
          : Offstage()
    ]);
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
          hintText: S.of(context).search,
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


