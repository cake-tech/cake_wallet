import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:flutter/material.dart';
import "package:flutter_mobx/flutter_mobx.dart";
import 'package:url_launcher/url_launcher.dart';

class Setup2FAPage extends BasePage {
  Setup2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  bool get hideAppBar => true;

  @override
  Widget body(BuildContext context) {
    final cake2FAGuideUri = Uri.parse('https://docs.cakewallet.com/features/advanced/authentication/');
    return ModalPageWrapper(
      topBar: ModalTopBar(
          title: "",
          leadingIcon: Icon(Icons.arrow_back_ios_new),
          leadingSemanticLabel: S.of(context).seed_alert_back,
          onLeadingPressed: () => Navigator.of(context).pop()),
      header: ModalHeader(
          iconPath: "assets/new-ui/settings_row_icons/security.svg",
          message: S.of(context).privacy_and_security_desc,
          title: "Cake 2FA"),
      content: Column(
        spacing: 16,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Observer(
            builder: (_) => NewListSections(sections: {
              "": [
                ListItemRegularRow(
                    keyValue: "setup_totp",
                    label: S.current.setup_totp_recommended,
                    onTap: () {
                    setup2FAViewModel.generateSecretKey();
                    Navigator.of(context).pushReplacementNamed(Routes.setup_2faQRPage);
                    }
                ),
                ListItemRegularRow(
                    keyValue: "2fa_guide",
                    label: "Cake 2FA Guide",
                    onTap: () => _launchUrl(cake2FAGuideUri)
                )]
            })
          )
        ]
      )
    );
  }

  static void _launchUrl(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {}
  }
}
