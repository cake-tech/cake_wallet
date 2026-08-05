import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewSendMemoInput extends StatelessWidget {
  const NewSendMemoInput(
      {super.key,
      required this.memoController,
      required this.maxMemoLength,
      required this.memoLength,
      this.hintText,
      this.disclaimerText});

  final TextEditingController memoController;
  final int maxMemoLength;
  final int memoLength;
  final String? hintText;
  final String? disclaimerText;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Semantics(
                    label: hintText ?? S.of(context).memo_optional,
                    child: TextField(
                      maxLength: maxMemoLength,
                      controller: memoController,
                      decoration: InputDecoration(
                          hintText: hintText ?? S.of(context).memo_optional, counterText: ""),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              FloatingIconButton(
                  iconPath: "assets/new-ui/paste.svg",
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null && data.text != null) {
                      memoController.text = data.text!;
                    }
                  }),
              SizedBox(width: 12)
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(disclaimerText ?? S.of(context).memo_disclaimer,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              // The field itself already reports the character count through
              // maxValueLength/currentValueLength, so this visual counter stays silent.
              ExcludeSemantics(
                child: Text("${memoController.text.length} / ${maxMemoLength}",
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              )
            ],
          ),
        )
      ],
    );
  }
}
