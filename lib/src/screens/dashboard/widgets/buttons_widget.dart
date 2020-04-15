import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';

class ButtonsWidget extends StatefulWidget {
  @override
  ButtonsWidgetState createState() => ButtonsWidgetState();
}

class ButtonsWidgetState extends State<ButtonsWidget> {
  final sendImage = Image.asset('assets/images/send.png');
  final exchangeImage = Image.asset('assets/images/exchange.png');
  final buyImage = Image.asset('assets/images/coins.png');

  double height;
  bool isDraw;

  @override
  void initState() {
    height = 0;
    isDraw = false;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    setState(() => height = 108);
    Timer(Duration(milliseconds: 250), () =>
        setState(() => isDraw = true)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: EdgeInsets.only(left: 44, right: 44),
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        height: height,
        duration: Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        child: isDraw
          ? Row(
          children: <Widget>[
            Flexible(
              child: actionButton(
                  image: sendImage,
                  title: S.of(context).send,
                  route: Routes.send
              )
            ),
            Flexible(
              child: actionButton(
                  image: exchangeImage,
                  title: S.of(context).exchange,
                  route: Routes.exchange
              )
            ),
            Flexible(
              child: actionButton(
                  image: buyImage,
                  title: 'Buy',
                  route: ''
              )
            )
          ],
        )
        : Offstage(),
      ),
    );
  }

  Widget actionButton({
    @required Image image,
    @required String title,
    @required String route}) {

    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              if (route.isNotEmpty) {
                Navigator.of(context, rootNavigator: true).pushNamed(route);
              }
            },
            child: Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle
              ),
              child: image,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  color: PaletteDark.walletCardText
              ),
            ),
          )
        ],
      ),
    );
  }
}