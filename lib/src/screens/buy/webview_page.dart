import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebViewPage extends BasePage {
  WebViewPage(this._title, this._url);

  final String _title;
  final Uri _url;

  @override
  String get title => _title;

  @override
  Widget body(BuildContext context) {
    return WebViewPageBody(_title, _url);
  }
}

class WebViewPageBody extends StatefulWidget {
  WebViewPageBody(this.title, this.uri);

  final String title;
  final Uri uri;

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
      onPermissionRequest: (controller, request) async {
        final sharedPrefs = getIt.get<SharedPreferences>();

        if (sharedPrefs.getBool(PreferencesKey.showCameraConsent) ?? true) {
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

          sharedPrefs.setBool(PreferencesKey.showCameraConsent, false);
        }

        bool permissionGranted =
            await PermissionHandler.checkPermission(Permission.camera, context);

        return PermissionResponse(
          resources: request.resources,
          action: permissionGranted
              ? PermissionResponseAction.GRANT
              : PermissionResponseAction.DENY,
        );
      },
    );
  }
}
