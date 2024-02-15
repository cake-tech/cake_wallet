import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/buy/buy_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class WebViewPage extends BasePage {
  WebViewPage(this._url, this._providerType, this.isBuyAction, {required this.buyViewModel}) {
    buyViewModel.selectedProviderType = _providerType;
    buyViewModel.isBuyAction = isBuyAction;
  }

  final Uri _url;
  final ProviderType? _providerType;
  final bool? isBuyAction;
  final BuyViewModel buyViewModel;

  @override
  String get title => _providerType?.title ?? '';

  @override
  Widget body(BuildContext context) {
    return WebViewPageBody(title, _url, buyViewModel);
  }
}

class WebViewPageBody extends StatefulWidget {
  WebViewPageBody(this.title, this.uri, this.buyViewModel);

  final String title;
  final Uri uri;
  final BuyViewModel buyViewModel;

  @override
  WebViewPageBodyState createState() => WebViewPageBodyState();
}

class WebViewPageBodyState extends State<WebViewPageBody> {
  WebViewPageBodyState();

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
      ),
      initialUrlRequest: URLRequest(url: WebUri.uri(widget.uri)),
      onWebViewCreated: (InAppWebViewController controller) =>
          setState(() => controller),
      onLoadStart: (controller, url) async {
        if (widget.buyViewModel.selectedProviderType == null) return;
        widget.buyViewModel.processProviderUrl(urlStr: url.toString());
      },
      onPermissionRequest: (controller, request) async {
        bool permissionGranted = await Permission.camera.status == PermissionStatus.granted;
        if (!permissionGranted) {
          final bool userConsent = await showPopUp<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertWithTwoActions(
                        alertTitle: S.of(context).privacy,
                        alertContent: S.of(context).camera_consent(widget.title),
                        rightButtonText: S.of(context).agree,
                        leftButtonText: S.of(context).cancel,
                        actionRightButton: () => Navigator.of(context).pop(true),
                        actionLeftButton: () => Navigator.of(context).pop(false));
                  }) ??
              false;

          /// if user did NOT give the consent then return permission denied
          if (!userConsent) {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.DENY,
            );
          }

          permissionGranted = await Permission.camera.request().isGranted;
        }

        return PermissionResponse(
          resources: request.resources,
          action:
              permissionGranted ? PermissionResponseAction.GRANT : PermissionResponseAction.DENY,
        );
      },
    );
  }
}
