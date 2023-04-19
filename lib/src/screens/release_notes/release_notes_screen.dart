import 'dart:convert';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReleaseNotesScreen extends StatelessWidget {
  const ReleaseNotesScreen({
    required this.title,
  });

  final String title;

  Future<List<String>> _loadStrings() async {
    String notesContent = await rootBundle.loadString(
        isMoneroOnly ? 'assets/text/Monerocom_Release_Notes.txt' : 'assets/text/Release_Notes.txt');
    return LineSplitter().convert(notesContent);
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
                          child: Text(title),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(),
                    ),
                    Expanded(
                      flex: 20,
                      child: _getNotesWidget(),
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

  Widget _getNotesWidget() {
    return FutureBuilder<List<String>>(
      future: _loadStrings(),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (BuildContext context, int index) {
              return _getNoteItemWidget(snapshot.data![index], context);
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _getNoteItemWidget(String myString, BuildContext context) {
    return Column(
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
                  child: Text(myString),
                ),
              ],
            )),
        SizedBox(
          height: 16.0,
        )
      ],
    );
  }
}
