import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnterWalletConnectURIWrapperWidget extends StatefulWidget {
  const EnterWalletConnectURIWrapperWidget({super.key});

  @override
  State<EnterWalletConnectURIWrapperWidget> createState() =>
      _EnterWallectConnectURIWrapperWidgetState();
}

class _EnterWallectConnectURIWrapperWidgetState extends State<EnterWalletConnectURIWrapperWidget> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnterWalletConnectURIWidget(
      controller: controller,
    );
  }
}

class EnterWalletConnectURIWidget extends BaseAlertDialog {
  EnterWalletConnectURIWidget({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  String get titleText => S.current.enterWalletConnectURI;

  Future<void> _pasteWalletConnectURI() async {
    final clipboard = await Clipboard.getData('text/plain');
    final totpURI = clipboard?.text ?? '';

    if (totpURI.isNotEmpty) {
      controller.text = totpURI;
    }
  }

  @override
  Widget content(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0.0,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(height: 8),
          Text(
            S.current.copyWalletConnectLink,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 16),
          BaseTextFormField(
            controller: controller,
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            suffixIcon: Container(
              width: 24,
              height: 24,
              padding: EdgeInsets.only(top: 0),
              child: Semantics(
                label: S.of(context).paste,
                child: InkWell(
                  onTap: () => _pasteWalletConnectURI(),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Image.asset(
                      'assets/images/paste_ios.png',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            hintText: S.current.enterWalletConnectURI,
            placeholderTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget actionButtons(BuildContext context) {
    return Container(
      width: 300,
      height: 52,
      padding: EdgeInsets.only(left: 12, right: 12),
      color: Theme.of(context).colorScheme.surface,
      child: ButtonTheme(
        minWidth: double.infinity,
        child: TextButton(
          onPressed: () {
            Navigator.pop(context, controller.text);
          },
          child: Text(
            S.current.confirm,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.none,
                ),
          ),
        ),
      ),
    );
  }
}
