import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/routes.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/themes.dart';
import 'package:cake_wallet/theme_changer.dart';

class NewWalletTypePage extends BasePage {
  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => WalletTypeForm();
}

class WalletTypeForm extends StatefulWidget {
  @override
  WalletTypeFormState createState() => WalletTypeFormState();
}

class WalletTypeFormState extends State<WalletTypeForm> {
  static const aspectRatioImage = 1.22;

  final moneroIcon = Image.asset('assets/images/monero.png', height: 24, width: 24);
  final bitcoinIcon = Image.asset('assets/images/bitcoin.png', height: 24, width: 24);
  final walletTypeImageLight = Image.asset('assets/images/wallet_type_light.png');
  final walletTypeImageDark = Image.asset('assets/images/wallet_type.png');

  bool isDisabledButton;
  bool isMoneroSelected;
  bool isBitcoinSelected;

  Color moneroBackgroundColor = Colors.transparent;
  Color moneroTextColor = Colors.transparent;
  Color bitcoinBackgroundColor = Colors.transparent;
  Color bitcoinTextColor = Colors.transparent;

  @override
  void initState() {
    isDisabledButton = true;
    isMoneroSelected = false;
    isBitcoinSelected = false;

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    moneroBackgroundColor = Theme.of(context).accentTextTheme.title.backgroundColor;
    moneroTextColor = Theme.of(context).primaryTextTheme.title.color;
    bitcoinBackgroundColor = Theme.of(context).accentTextTheme.title.backgroundColor;
    bitcoinTextColor = Theme.of(context).primaryTextTheme.title.color;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final _themeChanger = Provider.of<ThemeChanger>(context);
    final walletTypeImage = _themeChanger.getTheme() == Themes.darkTheme
        ? walletTypeImageDark : walletTypeImageLight;

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 2,
            child: AspectRatio(
              aspectRatio: aspectRatioImage,
              child: FittedBox(child: walletTypeImage, fit: BoxFit.fill)
            )
          ),
          Flexible(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        S.of(context).choose_wallet_currency,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryTextTheme.title.color
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: SelectButton(
                          image: bitcoinIcon,
                          text: 'Bitcoin',
                          color: bitcoinBackgroundColor,
                          textColor: bitcoinTextColor,
                          onTap: () {}),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: SelectButton(
                          image: moneroIcon,
                          text: 'Monero',
                          color: moneroBackgroundColor,
                          textColor: moneroTextColor,
                          onTap: () => onSelectMoneroButton(context)),
                    )
                  ],
                ),
                PrimaryButton(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.newWallet),
                  text: S.of(context).seed_language_next,
                  color: Colors.green,
                  textColor: Colors.white,
                  isDisabled: isDisabledButton,
                )
              ],
            )
          )
        ],
      )
    );
  }

  void onSelectMoneroButton(BuildContext context) {
    isMoneroSelected = true;
    isBitcoinSelected = false;
    isDisabledButton = false;

    moneroBackgroundColor = Theme.of(context).accentTextTheme.title.decorationColor;
    moneroTextColor = Theme.of(context).primaryTextTheme.title.backgroundColor;
    bitcoinBackgroundColor = Theme.of(context).accentTextTheme.title.backgroundColor;
    bitcoinTextColor = Theme.of(context).primaryTextTheme.title.color;

    setState(() {});
  }

  void onSelectBitcoinButton(BuildContext context) {
    isMoneroSelected = false;
    isBitcoinSelected = true;
    isDisabledButton = false;

    moneroBackgroundColor = Theme.of(context).accentTextTheme.title.backgroundColor;
    moneroTextColor = Theme.of(context).primaryTextTheme.title.color;
    bitcoinBackgroundColor = moneroBackgroundColor = Theme.of(context).accentTextTheme.title.decorationColor;
    bitcoinTextColor = Theme.of(context).primaryTextTheme.title.backgroundColor;

    setState(() {});
  }
}