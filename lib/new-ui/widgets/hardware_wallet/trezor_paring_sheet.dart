import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';

class HardwareWalletTrezorParingSheet extends StatefulWidget {
  const HardwareWalletTrezorParingSheet({super.key});

  @override
  State<HardwareWalletTrezorParingSheet> createState() => _HardwareWalletTrezorParingSheetState();
}

class _HardwareWalletTrezorParingSheetState extends State<HardwareWalletTrezorParingSheet> {
  final TextEditingController _paringCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalTopBar(
                title: "Paring code",
                onLeadingPressed: Navigator.of(context).pop,
                onTrailingPressed: () {},
                leadingIcon: Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    SizedBox(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 75,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              textAlign: TextAlign.left,
                              textAlignVertical: TextAlignVertical.center,
                              controller: _paringCodeController,
                              keyboardType:
                                  TextInputType.numberWithOptions(signed: false, decimal: false),
                              decoration: InputDecoration(
                                hint: Text(
                                  "000 000",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                                border: InputBorder.none,
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(),
                    NewPrimaryButton(
                      text: S.of(context).continue_text,
                      onPressed: () => Navigator.of(context).pop(_paringCodeController.text),
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
