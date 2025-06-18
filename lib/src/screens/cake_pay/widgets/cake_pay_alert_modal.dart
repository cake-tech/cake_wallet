import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class CakePayAlertModal extends StatelessWidget {
  const CakePayAlertModal({
    Key? key,
    required this.title,
    required this.content,
    required this.actionTitle,
    this.heightFactor = 0.4,
    this.showCloseButton = true,
  }) : super(key: key);

  final String title;
  final Widget content;
  final String actionTitle;
  final bool showCloseButton;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Spacer(),
            Container(
              padding: EdgeInsets.only(top: 24, left: 24, right: 24),
              margin: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * heightFactor),
                    child: ListView(
                      children: [
                        content,
                        SizedBox(height: 35),
                      ],
                    ),
                  ),
                  PrimaryButton(
                    onPressed: () => Navigator.pop(context),
                    text: actionTitle,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    textColor: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 21),
                ],
              ),
            ),
            Spacer(),
           if(showCloseButton)
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.only(bottom: 40),
                child: CircleAvatar(
                  child: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}