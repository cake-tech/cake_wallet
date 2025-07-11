import 'dart:ui';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThirdPartyDisclaimerPage extends BasePage {
  ThirdPartyDisclaimerPage({this.title = "Disclaimer"});

  @override
  final String title;

  final String filePath = 'assets/text/disclaimer_deuro.txt';

  @override
  Widget body(BuildContext context) => _ThirdPartyDisclaimerPageBody(filePath: filePath);
}

class _ThirdPartyDisclaimerPageBody extends StatefulWidget {
  _ThirdPartyDisclaimerPageBody({required this.filePath});

  final String filePath;

  @override
  _ThirdPartyDisclaimerPageBodyState createState() => _ThirdPartyDisclaimerPageBodyState();
}

class _ThirdPartyDisclaimerPageBodyState extends State<_ThirdPartyDisclaimerPageBody> {
  String _fileText = '';

  void getFileLines() =>
      rootBundle.loadString(widget.filePath).then((text) => setState(() => _fileText = text));

  @override
  void initState() {
    super.initState();
    getFileLines();
  }

  @override
  Widget build(BuildContext context) => Container(
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
                      height: 12,
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
              ),
            ),
          ],
        ),
      );
}
