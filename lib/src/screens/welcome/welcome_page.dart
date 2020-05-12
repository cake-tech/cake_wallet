import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

WalletType _selectedType;

class WelcomePage extends BasePage {
  static const _aspectRatioImage = 1.26;
  static const _baseWidth = 411.43;
  final _image = Image.asset('assets/images/welcomeImg.png');
  final _cakeLogo = Image.asset('assets/images/cake_logo.png');
  final Map<String, WalletType> _picker =
      walletTypes.fold(Map<String, WalletType>(), (acc, item) {
    acc[walletTypeToString(item)] = item;
    return acc;
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _selectedType == null
        ? showDialog<void>(
            builder: (_) => Picker(
                items: walletTypes
                    .map((item) => walletTypeToString(item))
                    .toList(),
                selectedAtIndex: -1,
                title: 'Select wallet type',
                pickerHeight: 510,
                onItemSelected: (String item) {
                  print('before $_selectedType');
                  _selectedType = _picker[item];
                  print('after $_selectedType');
                }),
            context: context)
        : null);

    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        resizeToAvoidBottomPadding: false,
        body: SafeArea(child: body(context)));
  }

  @override
  Widget body(BuildContext context) {
    final _screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = _screenWidth < _baseWidth ? 0.76 : 1.0;

    return Column(children: <Widget>[
      Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AspectRatio(
              aspectRatio: _aspectRatioImage,
              child: FittedBox(child: _image, fit: BoxFit.fill)),
          Positioned(bottom: 0.0, child: _cakeLogo)
        ],
      ),
      Expanded(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                S.of(context).welcome,
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
                textScaleFactor: textScaleFactor,
                textAlign: TextAlign.center,
              ),
              Text(
                S.of(context).first_wallet_text,
                style: TextStyle(
                  fontSize: 22.0,
                  color: Palette.lightBlue,
                ),
                textScaleFactor: textScaleFactor,
                textAlign: TextAlign.center,
              ),
              Text(
                S.of(context).please_make_selection,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Palette.lightBlue,
                ),
                textScaleFactor: textScaleFactor,
                textAlign: TextAlign.center,
              )
            ]),
      ),
      Container(
          padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
          child: Column(children: <Widget>[
            PrimaryButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.newWalletFromWelcome,
                      arguments: _selectedType);
                },
                text: S.of(context).create_new,
                color:
                    Theme.of(context).primaryTextTheme.button.backgroundColor,
                borderColor:
                    Theme.of(context).primaryTextTheme.button.decorationColor),
            SizedBox(height: 10),
            PrimaryButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.restoreOptions,
                    arguments: _selectedType);
              },
              color: Theme.of(context).accentTextTheme.caption.backgroundColor,
              borderColor:
                  Theme.of(context).accentTextTheme.caption.decorationColor,
              text: S.of(context).restore_wallet,
            )
          ]))
    ]);
  }
}
