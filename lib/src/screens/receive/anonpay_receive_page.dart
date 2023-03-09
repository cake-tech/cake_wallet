import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/entities/receive_page_option.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class AnonPayReceivePage extends BasePage {
  final AnonpayInvoiceInfo invoiceInfo;

  AnonPayReceivePage({required this.invoiceInfo});

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
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
              color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!),
        ),
        Text(
          ReceivePageOption.anonPayInvoice.toString(),
          style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.headline5!.color!),
        )
      ],
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
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(height: 24),
          Container(
            width: 200,
            padding: EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: Theme.of(context).backgroundColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.current.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryTextTheme.headline1!.decorationColor!,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).accentTextTheme.headline3!.color!,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SyncIndicatorIcon(
                            boolMode: false,
                            value: invoiceInfo.status,
                            size: 6,
                          ),
                          SizedBox(width: 5),
                          Text(
                            invoiceInfo.status,
                            style: textSmallSemiBold(
                              color: Theme.of(context).primaryTextTheme.headline6!.color,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 27),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryTextTheme.headline1!.decorationColor!,
                      ),
                    ),
                    Text(
                      invoiceInfo.invoiceId,
                      style: textSmallSemiBold(
                        color: Theme.of(context).primaryTextTheme.headline6!.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 50, 24, 24),
            child: AnonQrWidget(
                isLight: currentTheme.type == ThemeType.light, anonpayInvoiceInfo: invoiceInfo),
          ),
          SizedBox(height: 24),
          Column(
            children: [
              ShareLinkItem(url: invoiceInfo.clearnetUrl, title: 'Clearnet link'),
              SizedBox(height: 16),
              ShareLinkItem(url: invoiceInfo.onionUrl, title: 'Onion link')
            ],
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}

class AnonQrWidget extends StatelessWidget {
  const AnonQrWidget({super.key, required this.isLight, required this.anonpayInvoiceInfo});

  final bool isLight;
  final AnonpayInvoiceInfo anonpayInvoiceInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            S.of(context).qr_fullscreen,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!),
          ),
        ),
        Row(
          children: [
            Spacer(flex: 3),
            Flexible(
              flex: 5,
              child: GestureDetector(
                onTap: () async {
                  // Get the current brightness:
                  final double brightness = await DeviceDisplayBrightness.getBrightness();

                  // ignore: unawaited_futures
                  DeviceDisplayBrightness.setBrightness(1.0);
                  await Navigator.pushNamed(
                    context,
                    Routes.fullscreenQR,
                    arguments: {
                      'qrData': anonpayInvoiceInfo.clearnetUrl,
                      'isLight': isLight,
                    },
                  );
                  // ignore: unawaited_futures
                  DeviceDisplayBrightness.setBrightness(brightness);
                },
                child: Hero(
                  tag: Key(anonpayInvoiceInfo.clearnetUrl),
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
                        child: QrImage(data: anonpayInvoiceInfo.clearnetUrl),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Spacer(flex: 3),
          ],
        ),
      ],
    );
  }
}

class ShareLinkItem extends StatelessWidget {
  const ShareLinkItem({super.key, required this.url, required this.title});
  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_address.png',
        color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: textMedium(
            color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!,
          ),
        ),
        SizedBox(width: 50),
        Row(
          children: [
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: url));
                showBar<void>(context, S.of(context).copied_to_clipboard);
              },
              child: copyImage,
            ),
            SizedBox(width: 20),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              iconSize: 25,
              onPressed: () => Share.share(url),
              icon: Icon(
                Icons.share,
                color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!,
              ),
            )
          ],
        )
      ],
    );
  }
}
