import 'package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewSendAmountInput extends StatefulWidget {
  const NewSendAmountInput({super.key, required this.currency, required this.hasPicker, required this.onPickerClicked, required this.currencyIconPath, required this.amountController});

  final String currency;
  final String currencyIconPath;
  final bool hasPicker;
  final VoidCallback onPickerClicked;
  final TextEditingController amountController;

  @override
  State<NewSendAmountInput> createState() => _NewSendAmountInputState();
}

class _NewSendAmountInputState extends State<NewSendAmountInput> {


  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16)
          ),
          child:Row(
            children: [
              Expanded(
                // flex:9,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  spacing: 8,
                  children: [
                    Expanded(child: TextField(controller: widget.amountController,
                    decoration: InputDecoration(hintText: "0"),)),
                    FloatingIconButton(
                        iconPath: "assets/new-ui/paste.svg",
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if(data != null && data.text != null) {
                            widget.amountController.text = data.text!;
                          }
                        }
                    ),
                    SizedBox.shrink()
                  ],
                ),
              ),
              IntrinsicWidth(
                child: Observer(
                  builder:(_) {

                    return GestureDetector(
                      onTap: widget.onPickerClicked,
                      child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(topRight: Radius.circular(16),bottomRight: Radius.circular(16)),
                            color: widget.hasPicker ?Theme.of(context).colorScheme.surfaceContainerHigh:Theme.of(context).colorScheme.surfaceContainer,
                          ),
                          child:Padding(
                              padding:EdgeInsets.symmetric(horizontal: 12),
                              child:Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                spacing: 8,
                                children: [
                                  if(widget.hasPicker&&widget.currencyIconPath.isNotEmpty)
                                    Image.asset(widget.currencyIconPath, width:24,height:24),
                                  Text(
                                      widget.currency
                                  ),
                                  if(widget.hasPicker)
                                    SvgPicture.asset("assets/new-ui/chooser.svg", width:12,height:12, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),)
                                ],
                              ))
                      ),
                    );
                  },
                ),
              ),
            ],
          )
      ),
    );
  }
}
