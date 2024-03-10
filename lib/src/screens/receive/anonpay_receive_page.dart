import 'package:cake_wallet/anonpay/anonpay_info_base.dart';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/entities/qr_view_data.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/screens/receive/widgets/anonpay_status_section.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/receive/widgets/copy_link_item.dart';
import 'package:cake_wallet/themes/extensions/qr_code_theme.dart';
import 'package:cake_wallet/utils/brightness_util.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';

class AnonPayReceivePage extends BasePage {
  final AnonpayInfoBase invoiceInfo;

  AnonPayReceivePage({required this.invoiceInfo});

  @override
  String get title => S.current.receive;

  @override
  bool get gradientBackground => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  void onClose(BuildContext context) => Navigator.popUntil(context, (route) => route.isFirst);

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
              color: titleColor(context)),
        ),
        Text(
          invoiceInfo is AnonpayInvoiceInfo
              ? ReceivePageOption.anonPayInvoice.toString()
              : ReceivePageOption.anonPayDonationLink.toString(),
          style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).extension<QRCodeTheme>()!.qrCodeColor),
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
          color: pageIconColor(context),
          size: 22.0,
        ),
      ),
    );
  }

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

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
                  BrightnessUtil.changeBrightnessForFunction(() async {
                    await Navigator.pushNamed(context, Routes.fullscreenQR,
                        arguments: QrViewData(
                          data: invoiceInfo.clearnetUrl,
                          version: qr.QrVersions.auto,
                        ));
                  });
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
                            color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
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
