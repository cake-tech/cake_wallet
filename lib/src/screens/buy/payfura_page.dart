import 'package:cake_wallet/buy/payfura/payfura_buy_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class PayFuraPage extends BasePage {
  PayFuraPage(this._PayfuraBuyProvider);

  final PayfuraBuyProvider _PayfuraBuyProvider;

  @override
  String get title => S.current.buy;

  @override
  Widget body(BuildContext context) {
    return PayFuraPageBody(_PayfuraBuyProvider);
  }
}

class PayFuraPageBody extends StatefulWidget {
  PayFuraPageBody(this._PayfuraBuyProvider);

  final PayfuraBuyProvider _PayfuraBuyProvider;

  Uri get uri => _PayfuraBuyProvider.requestUrl();

  @override
  PayFuraPageBodyState createState() => PayFuraPageBodyState();
}

class PayFuraPageBodyState extends State<PayFuraPageBody> {
  PayFuraPageBodyState();

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(transparentBackground: true),
      ),
      initialUrlRequest: URLRequest(url: widget.uri),
      androidOnPermissionRequest: (_, __, resources) async {
        bool permissionGranted = await Permission.camera.status == PermissionStatus.granted;
        if (!permissionGranted) {
          permissionGranted = await Permission.camera.request().isGranted;
        }

        return PermissionRequestResponse(
          resources: resources,
          action: permissionGranted
              ? PermissionRequestResponseAction.GRANT
              : PermissionRequestResponseAction.DENY,
        );
      },
    );
  }
}
