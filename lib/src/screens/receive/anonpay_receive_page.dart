import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/anonpay/anonpay_provider_description.dart';
import 'package:cake_wallet/entities/receive_page_option.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/anonpay_status_section.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_widget.dart';
import 'package:cake_wallet/src/screens/receive/widgets/share_link_item.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';

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
  Widget? trailing(BuildContext context) {
    if (invoiceInfo.provider == AnonpayProviderDescription.anonpayInvoice) {
      return null;
    }

    return Material(
      color: Colors.transparent,
      child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.edit,
              color: Theme.of(context).accentTextTheme.caption!.color!, size: 22.0)),
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
          if (invoiceInfo.provider == AnonpayProviderDescription.anonpayInvoice)
            AnonInvoiceStatusSection(invoiceInfo: invoiceInfo),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 50, 24, 24),
            child: QRWidget(isLight: currentTheme.type == ThemeType.light, 
            urlString: invoiceInfo.clearnetUrl,
            ),
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


