import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/string_constants.dart';
import '../buttons/custom_button.dart';

class UriInputPopup extends StatelessWidget {
  UriInputPopup({
    Key? key,
  }) : super(key: key);

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: StyleConstants.layerColor1NoAlpha,
      title: const Text(
        StringConstants.enterUri,
        style: StyleConstants.subtitleText,
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width - StyleConstants.linear8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              StringConstants.enterUriMessage,
              style: StyleConstants.layerTextStyle3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: StyleConstants.magic10,
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintStyle: StyleConstants.layerTextStyle3,
                hintText: StringConstants.textFieldPlaceholder,
                fillColor: StyleConstants.layerColor2,
                labelStyle: StyleConstants.layerTextStyle3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      StyleConstants.magic10,
                    ),
                  ),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(
              height: StyleConstants.linear16,
            ),
            Row(
              children: [
                CustomButton(
                  type: CustomButtonType.normal,
                  onTap: () {
                    Navigator.of(context).pop(
                      controller.text,
                    );
                  },
                  child: const Text(
                    StringConstants.connect,
                    style: StyleConstants.buttonText,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: StyleConstants.linear16,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                StringConstants.cancel,
                style: StyleConstants.buttonText.copyWith(
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
