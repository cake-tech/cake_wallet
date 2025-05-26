import 'package:cake_wallet/src/screens/yat/widgets/yat_close_button.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class YatEmojiId extends StatelessWidget {
  YatEmojiId(this.emojiId);
  static const durationInMilliseconds = 250;

  final String emojiId;
  final image = Image.asset('assets/images/emoji_popup.png');

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        AlertBackground(child: Container()),
        SlideInUp(
          from: 420,
          duration: Duration(milliseconds: durationInMilliseconds),
          child: ClipRRect(
              borderRadius:
                  BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              child: Container(
                  height: 420,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: EdgeInsets.fromLTRB(24, 15, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(children: [
                        Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [YatCloseButton(onClose: () => Navigator.of(context).pop())]),
                        Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainer,
                                      border: Border.all(
                                          color: Theme.of(context).colorScheme.outlineVariant),
                                      borderRadius: BorderRadius.all(Radius.circular(50))),
                                  child: Text(emojiId,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontSize: 46,
                                            decoration: TextDecoration.none,
                                          )))
                            ])
                      ]),
                      Container(
                          padding: EdgeInsets.only(left: 6, right: 6),
                          child: Column(children: [
                            Text("That's one nice Yat!",
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    )),
                            Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Text(
                                    'You can manage your Yat or purchase additional Yats in your account settings',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontSize: 18,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          decoration: TextDecoration.none,
                                        )))
                          ])),
                      PrimaryButton(
                          text: 'Got it',
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () => Navigator.of(context).pop())
                    ],
                  ))),
        )
      ],
    );
  }
}
