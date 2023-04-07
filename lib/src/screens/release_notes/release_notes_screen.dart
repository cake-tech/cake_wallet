import 'dart:convert';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReleaseNotesScreen extends StatefulWidget {
  ReleaseNotesScreen({
    required this.title,
  });

  final String title;

  @override
  _ReleaseNotesScreenState createState() => _ReleaseNotesScreenState();
}

class _ReleaseNotesScreenState extends State<ReleaseNotesScreen> {
  String _fileText = '';
  List<Widget> notesWidgetList = [];

  Future<void> getFileLines() async {
    _fileText = await rootBundle.loadString(isMoneroOnly ? 'assets/text/Monerocom_Release_Notes.txt'
        :'assets/text/Release_Notes.txt');
    getWidgetsList(_fileText);

    setState(() {});
  }

  List<Widget> getWidgetsList(String myString) {
    final LineSplitter ls = LineSplitter();
    final List<String> _notesList = ls.convert(myString);
    _notesList.forEach((element) {
      notesWidgetList.add(Column(
        children: [
          DefaultTextStyle(
              style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 16.0,
                  fontFamily: 'Lato',
                  color: Theme.of(context).accentTextTheme!.headline2!.backgroundColor!,
                  ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text('•'),
                  ),
                  Expanded(
                    child: Text(element),
                  ),
                ],
              )),
          SizedBox(
            height: 16.0,
          )
        ],
      ));
    });
    return notesWidgetList;
  }

  @override
  void initState() {
    super.initState();
    getFileLines();
  }

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: SizedBox()),
        Expanded(
          flex: 19,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                gradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).scaffoldBackgroundColor,
                ], begin: Alignment.centerLeft, end: Alignment.centerRight),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        child: DefaultTextStyle(
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                            color: Theme.of(context).accentTextTheme!.headline2!.backgroundColor!,
                          ),
                          child: Text(widget.title),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(),
                    ),
                    Expanded(
                      flex: 20,
                      child: Container(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(0),
                          itemCount: notesWidgetList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return notesWidgetList[index];
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(),
        ),
        Expanded(
            flex: 3,
            child: Container(
              child: Column(
                children: [
                  AlertCloseButton(
                    isPositioned: false,
                  ),
                ],
              ),
            )),
      ],
    ));
  }
}
