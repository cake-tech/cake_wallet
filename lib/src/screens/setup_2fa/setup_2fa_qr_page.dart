import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import '../../../palette.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_list.dart';

class Setup2FAQRPage extends BasePage {
  Setup2FAQRPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => S.current.setup_2fa;

  @override
  Widget body(BuildContext context) {
  
    final copyImage = Image.asset(
      'assets/images/copy_content.png',
      height: 12,
      width: 12,
      color: Color(0xFF355688),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 58),
          Text(
            S.current.add_secret_code,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5714,
              color: Palette.darkBlueCraiola,
            ),
          ),
          SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 3,
                  color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!,
                ),
              ),
              child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 3,
                      color: Colors.white,
                    ),
                  ),
                  child: QrImage(
                    data: setup2FAViewModel.totpVersionOneLink,
                    version: qr.QrVersions.auto,
                  )),
            ),
          ),
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
                      S.current.totp_secret_code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Palette.darkGray,
                        height: 1.8333,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${setup2FAViewModel.secretKey}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.375,
                      ),
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
                    Clipboard.setData(ClipboardData(text: '${setup2FAViewModel.secretKey}'));
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Color(0xFFF2F0FA),
                    ),
                    child: copyImage,
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 8),
          StandardListSeparator(),
          Spacer(),
          PrimaryButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(
                Routes.totpAuthCodePage,
                  arguments: TotpAuthArgumentsModel(
                    isForSetup: true,
                  )
                  
              );
            },
            text: S.current.continue_text,
            color: Theme.of(context).accentTextTheme.bodyLarge!.color!,
            textColor: Colors.white,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
