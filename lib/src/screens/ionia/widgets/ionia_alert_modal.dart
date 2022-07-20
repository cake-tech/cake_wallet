import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';

class IoniaAlertModal extends StatelessWidget {
  const IoniaAlertModal({
    Key key,
    @required this.title,
    @required this.content,
    @required this.actionTitle,
  }) : super(key: key);

  final String title;
  final String content;
  final String actionTitle;
  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.only(top: 24, left: 24, right: 24),
              margin: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).backgroundColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: textLargeSemiBold(
                        color: Theme.of(context).textTheme.body1.color,
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView(
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            content,
                            style: textMedium(
                              color: Theme.of(context).textTheme.display2.color,
                            ),
                          ),
                        ),
                        SizedBox(height: 35),
                      ],
                    ),
                  ),
                  PrimaryButton(
                    onPressed: () => Navigator.pop(context),
                    text: actionTitle,
                    color: Color.fromRGBO(233, 242, 252, 1),
                    textColor: Theme.of(context).textTheme.display2.color,
                  ),
                  SizedBox(height: 21),
                ],
              ),
            ),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.only(bottom: 40),
                child: CircleAvatar(
                  child: Icon(
                    Icons.close,
                    color: Colors.black,
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
