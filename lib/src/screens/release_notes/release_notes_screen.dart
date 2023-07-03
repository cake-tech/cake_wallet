import 'dart:convert';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
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
    return Stack(
      alignment: Alignment.center,
      children: [
        AlertBackground(
          child: AlertDialog(
            insetPadding: EdgeInsets.only(left: 16, right: 16, bottom: 48),
            elevation: 0.0,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
            content: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  gradient: LinearGradient(colors: [
                    Theme.of(context).extension<DashboardPageTheme>()!.firstGradientBackgroundColor,
                    Theme.of(context).extension<DashboardPageTheme>()!.secondGradientBackgroundColor,
                  ], begin: Alignment.centerLeft, end: Alignment.centerRight)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          child: DefaultTextStyle(
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                              color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                            ),
                            child: Text(title),
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48, bottom: 16),
                        child: Container(
                          width: double.maxFinite,
                          child: Column(
                            children: <Widget>[
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                                ),
                                child: _getNotesWidget(),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AlertCloseButton(
          bottom: 30,
        )
      ],
    );
  }

  Widget _getNotesWidget() {
    return FutureBuilder<List<String>>(
      future: _loadStrings(),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            shrinkWrap: true,
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
              color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
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
