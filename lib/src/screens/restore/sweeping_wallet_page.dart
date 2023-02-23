import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/restore/restore_from_qr_vm.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/scheduler.dart';

class SweepingWalletPage extends BasePage {
  SweepingWalletPage({required this.restoreVMfromQR});

  static const aspectRatioImage = 1.25;
  final welcomeImageLight = Image.asset('assets/images/welcome_light.png');
  final welcomeImageDark = Image.asset('assets/images/welcome.png');

  final WalletRestorationFromQRVM restoreVMfromQR;

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await restoreVMfromQR.create();
      if (restoreVMfromQR.state is FailureState) {
        _onWalletCreateFailure(
            context, 'Create wallet state: ${restoreVMfromQR.state.runtimeType.toString()}');
      }
    });

    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        resizeToAvoidBottomInset: false,
        body: body(context));
  }

  @override
  Widget body(BuildContext context) {
    final welcomeImage = currentTheme.type == ThemeType.dark ? welcomeImageDark : welcomeImageLight;

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

void _onWalletCreateFailure(BuildContext context, String error) {
  var count = 0;
  showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
            alertTitle: S.current.error,
            alertContent: error,
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.popUntil(context, (route) => count++ == 3));
      });
}
