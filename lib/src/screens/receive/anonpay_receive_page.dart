import 'package:cake_wallet/anonpay/anonpay_info_base.dart';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/entities/qr_view_data.dart';
import 'package:cake_wallet/entities/receive_page_option.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/screens/receive/widgets/anonpay_status_section.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/receive/widgets/copy_link_item.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

class AnonPayReceivePage extends BasePage {
  final AnonpayInfoBase invoiceInfo;

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
      color: Theme.of(context)
          .accentTextTheme!
          .displayMedium!
          .backgroundColor!,
      size: 16,
    );

    return SizedBox(
      height: 37,
      width: 37,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: TextButton(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, Routes.dashboard, (route) => false),
            child: _backButton),
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
              color: Theme.of(context)
                  .accentTextTheme!
                  .displayMedium!
                  .backgroundColor!),
        ),
        Text(
          invoiceInfo is AnonpayInvoiceInfo
              ? ReceivePageOption.anonPayInvoice.toString()
              : ReceivePageOption.anonPayDonationLink.toString(),
          style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme!.headlineSmall!.color!),
        )
      ],
    );
  }

  @override
  Widget? trailing(BuildContext context) {
    if (invoiceInfo is AnonpayInvoiceInfo) {
      return null;
    }

    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: () => Navigator.popAndPushNamed(
          context,
          Routes.anonPayInvoicePage,
          arguments: [invoiceInfo.address, ReceivePageOption.anonPayDonationLink],
        ),
        icon: Icon(
          Icons.edit,
          color: Theme.of(context)
              .accentTextTheme!
              .bodySmall!
              .color!,
          size: 22.0,
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
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(height: 24),
          if (invoiceInfo is AnonpayInvoiceInfo)
            AnonInvoiceStatusSection(invoiceInfo: invoiceInfo as AnonpayInvoiceInfo),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 50, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: GestureDetector(
                onTap: () async {
                  final double brightness = await DeviceDisplayBrightness.getBrightness();

                  // ignore: unawaited_futures
                  DeviceDisplayBrightness.setBrightness(1.0);
                  await Navigator.pushNamed(
                    context,
                    Routes.fullscreenQR,
                    arguments: QrViewData(data: invoiceInfo.clearnetUrl,
                      version: qr.QrVersions.auto,
                    )
                  );
                  // ignore: unawaited_futures
                  DeviceDisplayBrightness.setBrightness(brightness);
                },
                child: Hero(
                  tag: Key(invoiceInfo.clearnetUrl),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 3,
                            color: Theme.of(context)
                                .accentTextTheme!
                                .displayMedium!
                                .backgroundColor!,
                          ),
                        ),
                        child: QrImage(
                          data: invoiceInfo.clearnetUrl,
                          version: qr.QrVersions.auto,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Column(
            children: [
              CopyLinkItem(url: invoiceInfo.clearnetUrl, title: S.of(context).clearnet_link),
              SizedBox(height: 16),
              CopyLinkItem(url: invoiceInfo.onionUrl, title: S.of(context).onion_link),
            ],
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}
