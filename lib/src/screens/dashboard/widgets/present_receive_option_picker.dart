import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/rounded_checkbox.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';

class PresentReceiveOptionPicker extends StatelessWidget {
  PresentReceiveOptionPicker(
      {required this.receiveOptionViewModel, required this.color});

  final ReceiveOptionViewModel receiveOptionViewModel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final arrowBottom = Image.asset(
      'assets/images/arrow_bottom_purple_icon.png',
      color: color,
      height: 6,
    );

    return TextButton(
      onPressed: () => _showPicker(context),
      style: ButtonStyle(
        padding: MaterialStateProperty.all(EdgeInsets.zero),
        splashFactory: NoSplash.splashFactory,
        foregroundColor: MaterialStateProperty.all(Colors.transparent),
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                S.current.receive,
                style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                    color: color),
              ),
              Observer(
                  builder: (_) => Text(receiveOptionViewModel.selectedReceiveOption.toString(),
                      style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w500,
                          color: color)))
            ],
          ),
          SizedBox(width: 5),
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: arrowBottom,
          )
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) async {
    await showPopUp<void>(
      builder: (BuildContext popUpContext) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: AlignmentDirectional.center,
          children:[ AlertBackground(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Theme.of(context).colorScheme.background,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 24),
                    child: (ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: receiveOptionViewModel.options.length,
                      itemBuilder: (_, index) {
                        final option = receiveOptionViewModel.options[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(popUpContext);

                            receiveOptionViewModel.selectReceiveOption(option);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24, right: 24),
                            child: Observer(builder: (_) {
                              final value = receiveOptionViewModel.selectedReceiveOption;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(option.toString(),
                                      textAlign: TextAlign.left,
                                      style: textSmall(
                                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                                      ).copyWith(
                                        fontWeight:
                                            value == option ? FontWeight.w800 : FontWeight.w500,
                                      )),
                                  RoundedCheckbox(
                                    value: value == option,
                                  )
                                ],
                              );
                            }),
                          ),
                        );
                      },
                      separatorBuilder: (_, index) => SizedBox(height: 30),
                    )),
                  ),
                ),
                Spacer()
              ],
            ),
          ),
            AlertCloseButton(onTap: () => Navigator.of(popUpContext).pop(), bottom: 40)
          ],
        ),
      ),
      context: context,
    );
  }
}
