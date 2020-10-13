import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/src/widgets/annotated_editable_text.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/core/seed_validator.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/entities/mnemonic_item.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/widgets.dart';

class SeedWidget extends StatefulWidget {
  SeedWidget({Key key}) : super(key: key);

  @override
  SeedWidgetState createState() => SeedWidgetState();
}

class SeedWidgetState extends State<SeedWidget> {
  SeedWidgetState()
      : controller = TextEditingController(),
        focusNode = FocusNode(),
        words =
            SeedValidator.getWordList(type: WalletType.monero, language: 'en');

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> words;
  bool _showPlaceholder;

  String get text => controller.text;

  @override
  void initState() {
    super.initState();
    _showPlaceholder = true;
  }

  Future<void> _pasteAddress() async {
    final value = await Clipboard.getData('text/plain');

    if (value?.text?.isNotEmpty ?? false) {
      controller.text = value.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
          Stack(children: [
            SizedBox(height: 35),
            if (_showPlaceholder)
              Positioned(
                  top: 10,
                  left: 0,
                  child: Text('Enter your seed',
                      style: TextStyle(
                          fontSize: 16.0, color: Theme.of(context).hintColor))),
            Padding(
                padding: EdgeInsets.only(right: 40, top: 10),
                child: AnnotatedEditableText(
                    cursorColor: Colors.green,
                    backgroundCursorColor: Colors.blue,
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.normal,
                        backgroundColor: Colors.transparent),
                    focusNode: focusNode,
                    controller: controller,
                    words: words)),
            Positioned(
                top: 0,
                right: 0,
                child: Container(
                    width: 34,
                    height: 34,
                    child: InkWell(
                      onTap: () async => _pasteAddress(),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).hintColor,
                            borderRadius: BorderRadius.all(Radius.circular(6))),
                        // child: Image.asset('assets/images/duplicate.png',
                        //     color: Theme.of(context)
                        //         .primaryTextTheme
                        //         .display1
                        //         .decorationColor)
                      ),
                    )))
          ]),
          Container(
              margin: EdgeInsets.only(top: 15),
              height: 1.0,
              color: Theme.of(context).primaryTextTheme.title.backgroundColor),
        ]));
  }
}
