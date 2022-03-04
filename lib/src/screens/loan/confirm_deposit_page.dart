import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/src/widgets/framework.dart';

class ConfirmDepositPage extends BasePage {
  ConfirmDepositPage();
  @override
  String get title => 'Increase Deposit';

  @override
  Color get titleColor => Color(0xff355688);

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget trailing(BuildContext context) {
    final questionImage = Image.asset('assets/images/question_mark.png',
        color: Theme.of(context).primaryTextTheme.title.color);

    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          padding: EdgeInsets.all(0),
          onPressed: () => null,
          child: questionImage,
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      content: Column(
        children: [
          SizedBox(height: 50),
          SizedBox(
            height: 140,
            width: 140,
            child: AspectRatio(
              aspectRatio: 1,
              child: QrImage(
                data: "url",
                backgroundColor: Theme.of(context).primaryTextTheme.title.color,
                version: 2,
                foregroundColor:
                    Theme.of(context).accentTextTheme.display3.backgroundColor,
              ),
            ),
          ),
          SizedBox(height: 50),
          ConfirmDetailTile(
            text: '3524232',
            label: 'ID',
            shouldCopy: true,
          ),
          Divider(),
          ConfirmDetailTile(
            text: '0.1300',
            label: 'Amount',
          ),
          Divider(),
          ConfirmDetailTile(
            text: 'waiting',
            label: 'Status',
          ),
          Divider(),
          ConfirmDetailTile(
            text: '355442sdl;kmsmadsasx32',
            label: 'Address',
            shouldCopy: true,
          ),
        ],
      ),
      bottomSection: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: PrimaryButton(
              onPressed: () => null,
              text: 'Confirm',
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class ConfirmDetailTile extends StatelessWidget {
  final String label;

  final bool shouldCopy;

  final String text;

  const ConfirmDetailTile({
    @required this.text,
    @required this.label,
    this.shouldCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
              color: Color(0xff7A93BA),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 16),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$text',
              style: TextStyle(
                color: Theme.of(context).primaryTextTheme.title.color,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            if (shouldCopy)
              InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: Theme.of(context).primaryTextTheme.title.color,
                  ),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '$text'));
                  showBar<void>(context, S.of(context).copied_to_clipboard);
                },
              )
          ],
        ),
      ],
    );
  }
}
