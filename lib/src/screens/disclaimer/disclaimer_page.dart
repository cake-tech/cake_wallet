import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/palette.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';

class DisclaimerPage extends BasePage {
  DisclaimerPage({this.isReadOnly = false});

  final bool isReadOnly;

  @override
  bool get isModalBackButton => false;

  @override
  String get title => 'Terms of Use';

  @override
  Widget body(BuildContext context) => DisclaimerPageBody(isReadOnly: true);
}

class DisclaimerPageBody extends StatefulWidget {
  DisclaimerPageBody({this.isReadOnly = true});

  final bool isReadOnly;

  @override
  DisclaimerBodyState createState() => DisclaimerBodyState(false);
}

class DisclaimerBodyState extends State<DisclaimerPageBody> {
  DisclaimerBodyState(this._isAccepted);

  static const xmrtoUrl = 'https://xmr.to/app_static/html/tos.html';
  static const changenowUrl = 'https://changenow.io/terms-of-use';
  static const morphUrl = 'http://morphtoken.com/terms';

  final bool _isAccepted;
  bool _checked = false;
  String _fileText = '';

  Future<void> launchUrl(String url) async {
    if (await canLaunch(url)) await launch(url);
  }

  Future getFileLines() async {
    _fileText = await rootBundle.loadString('assets/text/Terms_of_Use.txt');
    setState(() {});
  }

  Future<void> _showAlertDialog(BuildContext context) async {
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Terms and conditions',
              textAlign: TextAlign.center,
            ),
            content: Text(
              'By using this app, you agree to the Terms of Agreement set forth to below',
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK')),
            ],
          );
        });
  }

  void _afterLayout(Duration _) => _showAlertDialog(context);

  @override
  void initState() {
    super.initState();
    getFileLines();
    if (_isAccepted) WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 10.0),
        Expanded(
            child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              padding: EdgeInsets.only(left: 25.0, right: 25.0),
              child: Column(
                children: <Widget>[
                  !_isAccepted
                      ? Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Terms and conditions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        )
                      : Offstage(),
                  !_isAccepted
                      ? SizedBox(
                          height: 20.0,
                        )
                      : Offstage(),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Legal Disclaimer\nAnd\nTerms of Use',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12.0, fontWeight: FontWeight.bold),
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
                        style: TextStyle(fontSize: 12.0),
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
                              fontSize: 14.0, fontWeight: FontWeight.bold),
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
                        onTap: () => launchUrl(xmrtoUrl),
                        child: Text(
                          xmrtoUrl,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14.0,
                              fontWeight: FontWeight.normal,
                              decoration: TextDecoration.underline),
                        ),
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
                          child: GestureDetector(
                        onTap: () => launchUrl(changenowUrl),
                        child: Text(
                          changenowUrl,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14.0,
                              fontWeight: FontWeight.normal,
                              decoration: TextDecoration.underline),
                        ),
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
                          child: GestureDetector(
                            onTap: () => launchUrl(morphUrl),
                            child: Text(
                              morphUrl,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: Colors.blue,
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
                            Theme.of(context).backgroundColor.withOpacity(0.0),
                            Theme.of(context).backgroundColor,
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
          !_isAccepted
              ? Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                          padding: EdgeInsets.only(
                              left: 25.0, top: 10.0, right: 25.0, bottom: 10.0),
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
                                  height: 25.0,
                                  width: 25.0,
                                  margin: EdgeInsets.only(
                                    right: 10.0,
                                  ),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Palette.lightGrey, width: 1.0),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0)),
                                      color: Theme.of(context).backgroundColor),
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
                                      fontSize: 14.0),
                                )
                              ],
                            ),
                          )),
                    ),
                  ],
                )
              : Offstage(),
          !_isAccepted
              ? Container(
                  padding:
                      EdgeInsets.only(left: 25.0, right: 25.0, bottom: 25.0),
                  child: PrimaryButton(
                    onPressed: _checked ? () {} : null,
                    text: 'Accept',
                    color: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .backgroundColor,
                    borderColor: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .decorationColor,
                  ),
                )
              : Offstage(),
          _isAccepted
              ? SizedBox(
                  height: 20.0,
                )
              : Offstage()
        ],
      ],
    );
  }
}
