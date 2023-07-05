import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

class DisclaimerPage extends BasePage {
  DisclaimerPage({this.isReadOnly = false});

  final bool isReadOnly;

  @override
  String get title => 'Terms of Use';

  @override
  Widget? leading(BuildContext context) =>
      isReadOnly ? super.leading(context) : null;

  @override
  Widget body(BuildContext context) =>
      DisclaimerPageBody(isReadOnly: isReadOnly);
}

class DisclaimerPageBody extends StatefulWidget {
  DisclaimerPageBody({required this.isReadOnly});

  final bool isReadOnly;

  @override
  DisclaimerBodyState createState() => DisclaimerBodyState();
}

class DisclaimerBodyState extends State<DisclaimerPageBody> {
  static const changenowUrl = 'https://changenow.io/terms-of-use';

  bool _checked = false;
  String _fileText = '';

  Future<void> launchUrl(String url) async {
    if (await canLaunch(url)) await launch(url);
  }

  Future getFileLines() async {
    _fileText = await rootBundle.loadString(
      isMoneroOnly
      ? 'assets/text/Monerocom_Terms_of_Use.txt'
      : 'assets/text/Terms_of_Use.txt' );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getFileLines();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: Column(
            children: <Widget>[
              SizedBox(height: 10.0),
              Expanded(
                  child: Stack(
                children: <Widget>[
                  SingleChildScrollView(
                    padding: EdgeInsets.only(left: 24.0, right: 24.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Terms and conditions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Legal Disclaimer\nAnd\nTerms of Use',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                                child: Text(
                              _fileText,
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                            ))
                          ],
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Other Terms and Conditions',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                                child: GestureDetector(
                              onTap: () => launchUrl(changenowUrl),
                              child: Text(
                                changenowUrl,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.normal,
                                    decoration: TextDecoration.underline),
                              ),
                            ))
                          ],
                        ),
                        SizedBox(
                          height: 16.0,
                        )
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 12.0,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 0.7, sigmaY: 0.7),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .background
                                      .withOpacity(0.0),
                                  Theme.of(context).colorScheme.background,
                                ],
                                begin: FractionalOffset.topCenter,
                                end: FractionalOffset.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )),
              if (!widget.isReadOnly) ...[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                          padding: EdgeInsets.only(
                              left: 24.0, top: 10.0, right: 24.0, bottom: 10.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _checked = !_checked;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  height: 24.0,
                                  width: 24.0,
                                  margin: EdgeInsets.only(
                                    right: 10.0,
                                  ),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
                                          width: 1.0),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0)),
                                      color: Theme.of(context).colorScheme.background),
                                  child: _checked
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.blue,
                                          size: 20.0,
                                        )
                                      : null,
                                ),
                                Text(
                                  'I agree to Terms of Use',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.0,
                                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                                )
                              ],
                            ),
                          )),
                    ),
                  ],
                ),
                Container(
                  padding:
                      EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                  child: PrimaryButton(
                      onPressed: _checked
                          ? () => Navigator.of(context)
                              .popAndPushNamed(Routes.welcome)
                          : null,
                      text: 'Accept',
                      color: Theme.of(context).extension<WalletListTheme>()!.createNewWalletButtonBackgroundColor,
                      textColor: Theme.of(context).extension<WalletListTheme>()!.restoreWalletButtonTextColor),
                ),
              ],
            ],
          ),
        ));
  }
}
