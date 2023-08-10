import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/support/widgets/support_tiles.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/support_urls.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class SupportPage extends BasePage {
  final imageLiveSupport = Image.asset('assets/images/live_support.png');
  final imageWalletGuides = Image.asset('assets/images/wallet_guides.png');
  final imageMoreLinks = Image.asset('assets/images/more_links.png');

  @override
  String get title => S.current.settings_support;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) {
    return Container(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 330),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: SupportTile(
                  image: imageLiveSupport,
                  title: S.of(context).support_title_live_chat,
                  description: S.of(context).support_description_live_chat,
                  onPressed: () {
                    if (DeviceInfo.instance.isDesktop) {
                      _launchUrl(
                          "$CHATWOOT_BASE_URL/widget?website_token=${secrets.chatwootWebsiteToken}");
                    } else {
                      Navigator.pushNamed(context, Routes.supportLiveChat);
                    }
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: SupportTile(
                  image: imageWalletGuides,
                  title: S.of(context).support_title_guides,
                  description: S.of(context).support_description_guides,
                  onPressed: () => _launchUrl(SUPPORT_GUIDES_URL),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: SupportTile(
                  image: imageMoreLinks,
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
