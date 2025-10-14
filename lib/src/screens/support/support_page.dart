import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends BasePage {
  SupportPage(this.supportViewModel);

  final SupportViewModel supportViewModel;

  @override
  String get title => S.current.settings_support;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  String get _imageSupportChat => currentTheme.isDark
      ? 'assets/images/support_chat_dark.webp'
      : 'assets/images/support_chat.webp';

  String get _imageSupportDocs => currentTheme.isDark
      ? 'assets/images/support_docs_dark.webp'
      : 'assets/images/support_docs.webp';

  String get _imageSupportLinks => currentTheme.isDark
      ? 'assets/images/support_links_dark.webp'
      : 'assets/images/support_links.webp';

  @override
  Widget body(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: OptionTile(
                  image: Image.asset(_imageSupportChat, width: 55, height: 55),
                  title: S.of(context).support_title_live_chat,
                  description: S.of(context).support_description_live_chat,
                  onPressed: () => _onPressedSupportChat(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: OptionTile(
                  image: Image.asset(_imageSupportDocs, width: 55, height: 55),
                  title: S.of(context).support_title_guides,
                  description: S.of(context).support_description_guides,
                  onPressed: () => _launchUrl(supportViewModel.docsUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: OptionTile(
                  image: Image.asset(_imageSupportLinks, width: 55, height: 55),
                  title: S.of(context).support_title_other_links,
                  description: S.of(context).support_description_other_links,
                  onPressed: () => Navigator.pushNamed(context, Routes.supportOtherLinks),
                ),
              ),
            ],
          ),
        ),
      );

  void _onPressedSupportChat(BuildContext context) {
    if (DeviceInfo.instance.isDesktop) {
      _launchUrl(supportViewModel.fetchUrl());
    } else {
      Navigator.pushNamed(context, Routes.supportLiveChat);
    }
  }

  void _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {}
  }
}
