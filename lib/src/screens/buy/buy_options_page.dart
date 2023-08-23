import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/support/widgets/support_tiles.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyOptionsPage extends BasePage {
  final imageLiveSupport = Image.asset('assets/images/live_support.png');
  final imageWalletGuides = Image.asset('assets/images/wallet_guides.png');

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
                  title: "Robinhood",
                  description: S.of(context).support_description_live_chat,
                  onPressed: () {},
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: SupportTile(
                  image: imageWalletGuides,
                  title: S.of(context).support_title_guides,
                  description: S.of(context).support_description_guides,
                  onPressed: () {},
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
