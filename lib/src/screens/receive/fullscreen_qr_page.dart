import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class FullscreenQRPage extends BasePage {
  FullscreenQRPage({@required this.qrData, @required this.isLight});

  final bool isLight;
  final String qrData;

  @override
  Color get backgroundLightColor => currentTheme.type == ThemeType.bright ? Colors.transparent : Colors.white;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  bool get resizeToAvoidBottomInset => false;

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
          onPressed: () => onClose(context),
          child: _backButton,
        ),
      ),
    );
  }

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
      child: scaffold);

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Hero(
        tag: Key(qrData),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                  border: Border.all(width: 3, color: Theme.of(context).accentTextTheme.display3.backgroundColor)),
              child: QrImage(
                data: qrData,
                backgroundColor: isLight ? Colors.transparent : Colors.black,
                foregroundColor: Theme.of(context).accentTextTheme.display3.backgroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
