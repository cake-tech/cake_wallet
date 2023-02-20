import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/view_model/restore/restore_from_qr_vm.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

class SweepingWalletPage extends BasePage {

  SweepingWalletPage({required this.restoreVMfromQR});

  static const aspectRatioImage = 1.25;
  final welcomeImageLight = Image.asset('assets/images/welcome_light.png');
  final welcomeImageDark = Image.asset('assets/images/welcome.png');

  final WalletRestorationFromQRVM restoreVMfromQR;

  @override
  Widget build(BuildContext context) {
    restoreVMfromQR.create();

    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        resizeToAvoidBottomInset: false,
        body: body(context));
  }

  @override
  Widget body(BuildContext context) {
    final welcomeImage = currentTheme.type == ThemeType.dark ? welcomeImageDark : welcomeImageLight;

    final newWalletImage = Image.asset('assets/images/new_wallet.png',
        height: 12,
        width: 12,
        color: Theme.of(context).accentTextTheme!.headline5!.decorationColor!);
    final restoreWalletImage = Image.asset('assets/images/restore_wallet.png',
        height: 12, width: 12, color: Theme.of(context).primaryTextTheme!.headline6!.color!);

    return WillPopScope(
        onWillPop: () async => false,
        child: Container(
            padding: EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                    flex: 2,
                    child: AspectRatio(
                        aspectRatio: aspectRatioImage,
                        child: FittedBox(child: welcomeImage, fit: BoxFit.fill))),
                Flexible(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Text(
                                S.of(context).please_wait,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).accentTextTheme!.headline2!.color!,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                  S.of(context).sweeping_wallet,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryTextTheme!.headline6!.color!,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                  S.of(context).sweeping_wallet_alert,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).accentTextTheme!.headline2!.color!,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ))
              ],
            )));
  }
}
