import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/restore/restore_from_qr_vm.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/scheduler.dart';

class SweepingWalletPage extends BasePage {
  SweepingWalletPage({required this.sweepingWalletPageData});

  final SweepingWalletPageData sweepingWalletPageData;

  static const aspectRatioImage = 1.25;
  final welcomeImageLight = Image.asset('assets/images/welcome_light.png');
  final welcomeImageDark = Image.asset('assets/images/welcome.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        resizeToAvoidBottomInset: false,
        body: body(context));
  }

  @override
  Widget body(BuildContext context) {
    final welcomeImage = currentTheme.type == ThemeType.dark
        ? welcomeImageDark
        : welcomeImageLight;

    return SweepingWalletWidget(
      welcomeImage: welcomeImage,
      restoredWallet: sweepingWalletPageData.restoredWallet,
      aspectRatioImage: aspectRatioImage,
      restoreFromQRViewModel: sweepingWalletPageData.restorationFromQRVM,
    );
  }
}

class SweepingWalletWidget extends StatefulWidget {
  const SweepingWalletWidget({
    required this.welcomeImage,
    required this.restoredWallet,
    required this.aspectRatioImage,
    required this.restoreFromQRViewModel,
  });

  final Image welcomeImage;
  final double aspectRatioImage;
  final RestoredWallet restoredWallet;
  final WalletRestorationFromQRVM restoreFromQRViewModel;

  @override
  State<SweepingWalletWidget> createState() => _SweepingWalletWidgetState();
}

class _SweepingWalletWidgetState extends State<SweepingWalletWidget> {
  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _initializeRestoreFromQR();
    });
    super.initState();
  }

  Future<void> _initializeRestoreFromQR() async {
    try {
      await widget.restoreFromQRViewModel
          .createFlowForSweepAll(restoreWallet: widget.restoredWallet);

      if (widget.restoreFromQRViewModel.state is ExecutedSuccessfullyState) {
        await Navigator.of(navigatorKey.currentContext!).pushNamed(
          Routes.preSeed,
          arguments: widget.restoreFromQRViewModel.type,
        );
      }

      if (widget.restoreFromQRViewModel.state is FailureState) {
        final errorState = widget.restoreFromQRViewModel.state as FailureState;
        _onWalletCreateFailure(
            context, 'Create wallet state: ${errorState.error}');
      }
    } catch (e) {
      _onWalletCreateFailure(context, e.toString());
    }
  }

  void _onWalletCreateFailure(BuildContext context, String error) async {
    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
          alertTitle: S.current.error,
          alertContent: error,
          buttonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(),
        );
      },
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Container(
            padding: EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: widget.aspectRatioImage,
                    child: FittedBox(
                      child: widget.welcomeImage,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Flexible(
                    flex: 2,
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
                                  color: Theme.of(context)
                                      .accentTextTheme
                                      .displayMedium!
                                      .color,
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
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .titleLarge!
                                      .color!,
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
                                  color: Theme.of(context)
                                      .accentTextTheme
                                      .displayMedium!
                                      .color,
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

class SweepingWalletPageData {
  final WalletRestorationFromQRVM restorationFromQRVM;
  final RestoredWallet restoredWallet;

  SweepingWalletPageData({
    required this.restorationFromQRVM,
    required this.restoredWallet,
  });
}
