import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoCard extends StatelessWidget {
  final String leftButtonTitle;
  final String rightButtonTitle;

  final Function() leftButtonAction;
  final Function() rightButtonAction;

  const InfoCard(
      {Key? key,
      required this.leftButtonTitle,
      required this.rightButtonTitle,
      required this.leftButtonAction,
      required this.rightButtonAction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashBoardRoundedCardWidget(
      customBorder: 30,
      title: S.of(context).litecoin_mweb,
      subTitle: S.of(context).litecoin_mweb_description,
      hint: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => launchUrl(
              Uri.parse("https://docs.cakewallet.com/cryptos/litecoin/#mweb"),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              S.of(context).learn_more,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w400,
                color: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                height: 1,
              ),
              softWrap: true,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: leftButtonAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    leftButtonTitle,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: rightButtonAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    rightButtonTitle,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => {},
      icon: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: ImageIcon(
          AssetImage('assets/images/mweb_logo.png'),
          color: Color.fromARGB(255, 11, 70, 129),
          size: 40,
        ),
      ),
    );
  }
}
