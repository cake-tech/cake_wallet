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
  Color get backgroundLightColor => Palette.lavender;

  @override
  Color get backgroundDarkColor => PaletteDark.lightNightBlue;

  @override
  Widget body(BuildContext context) =>
      RestoreFromSeedForm(key: formKey, type: type, language: language);
}

class RestoreFromSeedForm extends StatefulWidget {
  RestoreFromSeedForm({Key key, this.type, this.language}) : super(key: key);
  final WalletType type;
  final String language;

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
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: SeedWidget(
          key: _seedKey,
          maxLength: mnemonicLength(widget.type),
          onMnemonicChange: (seed) => null,
          onFinish: () => Navigator.of(context).pushNamed(
              Routes.restoreWalletFromSeedDetails,
              arguments: [widget.type, widget.language, mnemonic()]),
          validator:
              SeedValidator(type: widget.type, language: widget.language),
        ),
      ),
    );
  }
}
