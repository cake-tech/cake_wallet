import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
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
    return _EnterWalletConnectURIWidget(
      controller: controller,
    );
  }
}

class _EnterWalletConnectURIWidget extends BaseAlertDialog {
  _EnterWalletConnectURIWidget({
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
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(height: 8),
          Text(
            S.current.copyWalletConnectLink,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 16),
          TextField(
            controller: controller,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
            decoration: InputDecoration(
              suffixIcon: Container(
                width: 24,
                height: 24,
                padding: EdgeInsets.only(top: 0),
                child: Semantics(
                  label: S.of(context).paste,
                  child: InkWell(
                    onTap: () => _pasteWalletConnectURI(),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Image.asset(
                        'assets/images/paste_ios.png',
                        color:
                            Theme.of(context).extension<SendPageTheme>()!.textFieldButtonIconColor,
                      ),
                    ),
                  ),
                ),
              ),
              hintText: S.current.enterWalletConnectURI,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).extension<SendPageTheme>()!.textFieldBorderColor,
                ),
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).extension<SendPageTheme>()!.textFieldHintColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
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
      color: Theme.of(context).dialogBackgroundColor,
      child: ButtonTheme(
        minWidth: double.infinity,
        child: TextButton(
          onPressed: () {
            Navigator.pop(context, controller.text);
          },
          child: Text(
            S.current.confirm,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
