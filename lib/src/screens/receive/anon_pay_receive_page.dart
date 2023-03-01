import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class AnonPayReceivePage extends BasePage {
  @override
  String get title => S.current.receive;

  @override
  Color get backgroundLightColor =>
      currentTheme.type == ThemeType.bright ? Colors.transparent : Colors.white;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget leading(BuildContext context) {
    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!,
      size: 16,
    );

    return SizedBox(
      height: 37,
      width: 37,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: TextButton(onPressed: () => onClose(context), child: _backButton),
      ),
    );
  }

  @override
  Widget middle(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
          color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!),
    );
  }

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).accentColor,
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor,
          ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
          child: scaffold);

  @override
  Widget body(BuildContext context) {
    return KeyboardActions(
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).accentTextTheme.bodyText1!.backgroundColor!,
            nextFocus: false,
            actions: []),
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: AnonQrWidget(isLight: currentTheme.type == ThemeType.light),
            ),
          ]),
        ));
  }
}

class AnonQrWidget extends StatelessWidget {
  const AnonQrWidget({super.key, required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_address.png',
        color: Theme.of(context).textTheme.subtitle1!.decorationColor!);

    return GestureDetector(
      onTap: () async {
        // Get the current brightness:
        final double brightness = await DeviceDisplayBrightness.getBrightness();

        // ignore: unawaited_futures
        DeviceDisplayBrightness.setBrightness(1.0);
        await Navigator.pushNamed(
          context,
          Routes.fullscreenQR,
          arguments: {
            'qrData': 'urlstring',
            'isLight': isLight,
          },
        );
        // ignore: unawaited_futures
        DeviceDisplayBrightness.setBrightness(brightness);
      },
      child: Hero(
        tag: Key('urlstring'),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 3,
                  color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!,
                ),
              ),
              child: QrImage(data: 'urlstring'),
            ),
          ),
        ),
      ),
    );
  }
}
