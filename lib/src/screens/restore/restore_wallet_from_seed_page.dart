import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/seed_widget.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/core/seed_validator.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/core/mnemonic_length.dart';

class RestoreWalletFromSeedPage extends BasePage {
  RestoreWalletFromSeedPage({@required this.type, @required this.language});

  final WalletType type;
  final String language;
  final formKey = GlobalKey<_RestoreFromSeedFormState>();

  @override
  String get title => S.current.restore_title_from_seed;

  @override
  Color get titleColor => Colors.white;

  @override
  Color get backgroundLightColor => Colors.transparent;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  bool get resizeToAvoidBottomPadding => false;

  @override
  Widget body(BuildContext context) =>
      RestoreFromSeedForm(key: formKey, type: type, language: language,
          leading: leading(context), middle: middle(context));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: resizeToAvoidBottomPadding,
        body: Container(
            color: Theme.of(context).backgroundColor,
            child: body(context)
        )
    );
  }
}

class RestoreFromSeedForm extends StatefulWidget {
  RestoreFromSeedForm({Key key, this.type, this.language, this.leading, this.middle}) : super(key: key);
  final WalletType type;
  final String language;
  final Widget leading;
  final Widget middle;

  @override
  _RestoreFromSeedFormState createState() => _RestoreFromSeedFormState();
}

class _RestoreFromSeedFormState extends State<RestoreFromSeedForm> {
  final _seedKey = GlobalKey<SeedWidgetState>();

  String mnemonic() => _seedKey.currentState.items.map((e) => e.text).join(' ');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
      child: SeedWidget(
        key: _seedKey,
        maxLength: mnemonicLength(widget.type),
        onMnemonicChange: (seed) => null,
        onFinish: () => Navigator.of(context).pushNamed(
            Routes.restoreWalletFromSeedDetails,
            arguments: [widget.type, widget.language, mnemonic()]),
        leading: widget.leading,
        middle: widget.middle,
        validator:
        SeedValidator(type: widget.type, language: widget.language),
      ),
    );
  }
}
