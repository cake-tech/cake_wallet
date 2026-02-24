import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewSendMemoInput extends StatelessWidget {
  const NewSendMemoInput({super.key, required this.memoController});

  final TextEditingController memoController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
                controller: memoController,
              decoration: InputDecoration(hintText: S.of(context).transaction_memo_optional),
            ),
          ),
          SizedBox(width:12),
          FloatingIconButton(
              iconPath: "assets/new-ui/paste.svg",
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if(data != null && data.text != null) {
                  memoController.text = data.text!;
                }
              }
          ),
          SizedBox(width:12)
        ],
      ),
    );
  }
}
