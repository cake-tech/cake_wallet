import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/utils/clipboard_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:url_launcher/url_launcher.dart';

class Setup2FAQRPage extends BasePage {
  Setup2FAQRPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => S.current.setup_2fa;

  @override
  Widget body(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_content.png',
        height: 16,
        width: 16,
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor);
    final cake2FAHowToUseUrl = Uri.parse(
        'https://guides.cakewallet.com/docs/advanced-features/authentication/#enabling-cake-2fa');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Spacer(),
          Text(
            S.current.scan_qr_on_device,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5714,
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
            ),
          ),
          SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 3,
                    color: Theme.of(context)
                        .extension<CakeTextTheme>()!
                        .titleColor,
                  ),
                ),
                child: Container(
                    child: QrImage(
                  data: setup2FAViewModel.totpVersionOneLink,
                  version: qr.QrVersions.auto,
                  foregroundColor:
                      Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  backgroundColor: Colors.transparent,
                )),
              ),
            ),
          ),
          SizedBox(height: 26),
          Text(
            S.current.add_secret_code,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5714,
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.current.totp_secret_code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .extension<CakeTextTheme>()!
                            .secondaryTextColor,
                        height: 1.8333,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${setup2FAViewModel.totpSecretKey}',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context)
                              .extension<CakeTextTheme>()!
                              .titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                child: InkWell(
                  onTap: () {
                    ClipboardUtil.setSensitiveDataToClipboard(ClipboardData(
                        text: '${setup2FAViewModel.totpSecretKey}'));
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
                  child: Container(
                    child: copyImage,
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 8),
          StandardListSeparator(),
          SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.current.totp_auth_url,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .extension<CakeTextTheme>()!
                            .secondaryTextColor,
                        height: 1.8333,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${setup2FAViewModel.totpVersionOneLink}',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context)
                              .extension<CakeTextTheme>()!
                              .titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                child: InkWell(
                  onTap: () {
                    ClipboardUtil.setSensitiveDataToClipboard(ClipboardData(
                        text: '${setup2FAViewModel.totpVersionOneLink}'));
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
                  child: Container(
                    child: copyImage,
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 8),
          StandardListSeparator(),
          SizedBox(height: 16),
          GestureDetector(
              onTap: () => _launchUrl(cake2FAHowToUseUrl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(S.current.how_to_use,
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .extension<CakeTextTheme>()!
                              .titleColor)),
                  Icon(Icons.info_outline,
                      size: 20,
                      color: Theme.of(context)
                          .extension<CakeTextTheme>()!
                          .titleColor)
                ],
              )),
          Spacer(flex: 5),
          PrimaryButton(
            onPressed: () {
              Navigator.of(context)
                  .pushReplacementNamed(Routes.totpAuthCodePage,
                      arguments: TotpAuthArgumentsModel(
                        isForSetup: true,
                      ));
            },
            text: S.current.continue_text,
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  static void _launchUrl(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {}
  }
}
