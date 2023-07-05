import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class ChooseYatAddressAlert extends BaseAlertDialog {
  ChooseYatAddressAlert({
    required this.alertTitle,
    required this.alertContent,
    required this.addresses,
  });

  final String alertTitle;
  final String alertContent;
  final List<String> addresses;

  @override
  String get titleText => alertTitle;

  @override
  String get contentText => alertContent;

  @override
  bool get barrierDismissible => false;

  @override
  Widget actionButtons(BuildContext context) =>
      ChooseYatAddressButtons(addresses);
}

class ChooseYatAddressButtons extends StatefulWidget {
  ChooseYatAddressButtons(this.addresses);

  final List<String> addresses;

  @override
  ChooseYatAddressButtonsState createState() =>
      ChooseYatAddressButtonsState(addresses);
}

class ChooseYatAddressButtonsState extends State<ChooseYatAddressButtons> {
  ChooseYatAddressButtonsState(this.addresses)
      : itemCount = addresses?.length ?? 0;

  final List<String> addresses;
  final int itemCount;
  final double backgroundHeight = 118;
  final double thumbHeight = 72;
  ScrollController controller = ScrollController();
  double fromTop = 0;

  @override
  Widget build(BuildContext context) {
    controller.addListener(() {
      fromTop = controller.hasClients
          ? (controller.offset / controller.position.maxScrollExtent *
          (backgroundHeight - thumbHeight))
          : 0;
      setState(() {});
    });

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
            width: 300,
            height: 158,
            color: Theme.of(context).dialogBackgroundColor,
            child: ListView.separated(
                controller: controller,
                padding: EdgeInsets.all(0),
                itemCount: itemCount,
                separatorBuilder: (_, __) => const HorizontalSectionDivider(),
                itemBuilder: (context, index) {
                  final address = addresses[index];

                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop<String>(address),
                    child: Container(
                        width: 300,
                        height: 52,
                        padding: EdgeInsets.only(left: 24, right: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: Text(
                                  address,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Lato',
                                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                                    decoration: TextDecoration.none,
                                  ),
                                )
                            )
                          ],
                        )
                    ),
                  );
                })
        ),
        if (itemCount > 3) CakeScrollbar(
            backgroundHeight: backgroundHeight,
            thumbHeight: thumbHeight,
            fromTop: fromTop
        )
      ]
    );
  }
}