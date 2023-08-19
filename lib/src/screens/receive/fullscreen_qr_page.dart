import 'package:cake_wallet/entities/qr_view_data.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';

class FullscreenQRPage extends BasePage {
  FullscreenQRPage({required this.qrViewData});

  final QrViewData qrViewData;

  @override
  bool get gradientBackground => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget leading(BuildContext context) {
    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
      size: 16,
    );

    return SizedBox(
      height: 37,
      width: 37,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: TextButton(
          // FIX-ME: Style
          //highlightColor: Colors.transparent,
          //splashColor: Colors.transparent,
          //padding: EdgeInsets.all(0),
          onPressed: () => onClose(context),
          child: _backButton,
        ),
      ),
    );
  }

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) =>
          GradientBackground(scaffold: scaffold);

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Hero(
        tag: Key(qrViewData.heroTag ?? qrViewData.data),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(
                      width: 3,
                      color: Theme.of(context).extension<DashboardPageTheme>()!.textColor)),
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(width: 3, color: Colors.white)),
                  child: QrImage(data: qrViewData.data, version: qrViewData.version)),
            ),
          ),
        ),
      ),
    );
  }
}
