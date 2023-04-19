import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/services.dart';

import '../../widgets/base_text_form_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_list.dart';

class Setup2FAQRPage extends BasePage {
  Setup2FAQRPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => 'Set up Cake 2FA';

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
          Text('Add this secret code to another device'),
          SizedBox(height: 10),
          QrImage(
            size: 327,
            data:
                'otpauth://totp/Cake%20Wallet:Samsung%20S21%20Ultra?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Cake%20Wallet&algorithm=SHA1&digits=6&period=30',
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
                    Text('TOTP Secret Code'),
                    SizedBox(height: 8),
                    Text(
                      'HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ',
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
                    Clipboard.setData(ClipboardData(text: ''));
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
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(Routes.setup_2faEnterCodePage),
            text: S.of(context).continue_text,
            color: Theme.of(context).accentTextTheme!.bodyText1!.color!,
            textColor: Colors.white,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
