import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/themes/extensions/info_theme.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/view_model/support_view_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';

class SupportPage extends BasePage {
  SupportPage(this.supportViewModel);

  final SupportViewModel supportViewModel;

  final imageLiveSupport = Image.asset('assets/images/cake_icon.png');
  final imageWalletGuides = Image.asset('assets/images/wallet_guides.png');
  final imageMoreLinks = Image.asset('assets/images/more_links.png');

  @override
  String get title => S.current.settings_support;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;



  @override
  Widget body(BuildContext context) {

    final mainColor = Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor;
    final brightColor = Theme.of(context).extension<InfoTheme>()!.textColor;

    final iconColor = currentTheme.type == ThemeType.bright ? brightColor : mainColor;

    return Container(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 330),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: OptionTile(
                  icon: Icon(
                    Icons.support_agent,
                    color: iconColor,
                    size: 50,
                  ),
                  title: S.of(context).support_title_live_chat,
                  description: S.of(context).support_description_live_chat,
                  onPressed: () {
                    if (DeviceInfo.instance.isDesktop) {
                      _launchUrl(supportViewModel.fetchUrl());
                    } else {
                      Navigator.pushNamed(context, Routes.supportLiveChat);
                    }
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: OptionTile(
                  icon: Icon(
                      Icons.find_in_page,
                      color: iconColor,
                    size: 50,
                  ),
                  title: S.of(context).support_title_guides,
                  description: S.of(context).support_description_guides,
                  onPressed: () => _launchUrl(supportViewModel.guidesUrl),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: OptionTile(
                  icon: Icon(
                    Icons.contact_support,
                    color: iconColor,
                    size: 50,
                  ),
                  title: S.of(context).support_title_other_links,
                  description: S.of(context).support_description_other_links,
                  onPressed: () => Navigator.pushNamed(context, Routes.supportOtherLinks),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {}
  }
}
