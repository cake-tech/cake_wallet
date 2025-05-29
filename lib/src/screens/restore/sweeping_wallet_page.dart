import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/scheduler.dart';

class SweepingWalletPage extends BasePage {
  SweepingWalletPage();

  static const aspectRatioImage = 1.25;
  final welcomeImageLight = Image.asset('assets/images/welcome_light.png');
  final welcomeImageDark = Image.asset('assets/images/welcome.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        resizeToAvoidBottomInset: false,
        body: body(context));
  }

  @override
  Widget body(BuildContext context) {
    final welcomeImage = currentTheme.isDark ? welcomeImageDark : welcomeImageLight;

    return SweepingWalletWidget(
      aspectRatioImage: aspectRatioImage,
      welcomeImage: welcomeImage,
    );
  }
}

class SweepingWalletWidget extends StatefulWidget {
  const SweepingWalletWidget({
    required this.aspectRatioImage,
    required this.welcomeImage,
  });

  final double aspectRatioImage;
  final Image welcomeImage;

  @override
  State<SweepingWalletWidget> createState() => _SweepingWalletWidgetState();
}

class _SweepingWalletWidgetState extends State<SweepingWalletWidget> {
  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                        aspectRatio: widget.aspectRatioImage,
                        child: FittedBox(child: widget.welcomeImage, fit: BoxFit.fill))),
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
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                S.of(context).sweeping_wallet,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                S.of(context).sweeping_wallet_alert,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
