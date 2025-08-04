import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';

class PopUpCancellableAlertDialog extends StatelessWidget {
  final String contentText;
  final String actionButtonText;
  final VoidCallback? buttonAction;
  final bool sameActionForButtonAndClose;

  const PopUpCancellableAlertDialog({
    super.key,
    this.contentText = '',
    this.actionButtonText = '',
    this.buttonAction,
    this.sameActionForButtonAndClose = true,
  });
  bool get barrierDismissible => false;
  Color? get actionButtonTextColor => null;
  Color? get actionButtonColor => null;

  Widget content(BuildContext context) {
    return Text(
      contentText,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.normal,
         
        color: Theme.of(context).colorScheme.onSurface,
        decoration: TextDecoration.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => barrierDismissible ? Navigator.of(context).pop() : null,
      child: AlertBackground(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Positioned(
              top: 280,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      child: Container(
                        width: 340,
                        padding: EdgeInsets.all(10),
                        color: Theme.of(context).colorScheme.surface,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                                  child: content(context),
                                ),
                                PrimaryButton(
                                  onPressed: buttonAction,
                                  text: actionButtonText,
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AlertCloseButton(
              onTap: sameActionForButtonAndClose ? buttonAction : null,
            ),
          ],
        ),
      ),
    );
  }
}
