import 'dart:ui';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

class DisclaimerPage extends BasePage {
  DisclaimerPage({this.isReadOnly = false});

  final bool isReadOnly;

  @override
  String get title => 'Terms of Use';

  @override
  Widget? leading(BuildContext context) => isReadOnly ? super.leading(context) : null;

  @override
  Widget body(BuildContext context) => DisclaimerPageBody(isReadOnly: isReadOnly);
}

class DisclaimerPageBody extends StatefulWidget {
  DisclaimerPageBody({required this.isReadOnly});

  final bool isReadOnly;

  @override
  DisclaimerBodyState createState() => DisclaimerBodyState();
}

class DisclaimerBodyState extends State<DisclaimerPageBody> {
  bool _checked = false;
  String _fileText = '';

  void getFileLines() {
    final fileName =
        isMoneroOnly ? 'assets/text/Monerocom_Terms_of_Use.txt' : 'assets/text/Terms_of_Use.txt';
    rootBundle.loadString(fileName).then((text) => setState(() => _fileText = text));
  }

  @override
  void initState() {
    super.initState();
    getFileLines();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: widget.isReadOnly,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface),
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              style: Theme.of(context).textTheme.bodySmall,
                            ))
                          ],
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
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
                                  Theme.of(context).colorScheme.surface.withAlpha(0),
                                  Theme.of(context).colorScheme.surface,
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
                          padding:
                              EdgeInsets.only(left: 24.0, top: 10.0, right: 24.0, bottom: 10.0),
                          child: InkWell(
                            key: ValueKey('disclaimer_check_key'),
                            onTap: () => setState(() =>_checked = !_checked),
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
                                          color: Theme.of(context).colorScheme.outline, width: 1.0),
                                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                      color: Theme.of(context).colorScheme.surface),
                                  child: _checked
                                      ? Icon(
                                          key: ValueKey('disclaimer_check_icon_key'),
                                          Icons.check,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20.0,
                                        )
                                      : null,
                                ),
                                Text(
                                  'I agree to Terms of Use',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                )
                              ],
                            ),
                          )),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                  child: PrimaryButton(
                      key: ValueKey('disclaimer_accept_button_key'),
                      onPressed: _checked
                          ? () => Navigator.of(context).popAndPushNamed(Routes.welcome)
                          : null,
                      text: 'Accept',
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ],
          ),
        ));
  }
}
