import 'package:cake_wallet/core/node_address_validator.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/settings/mweb_settings_view_model.dart';
import 'package:flutter/material.dart';

class MwebNodePage extends StatefulWidget {
  const MwebNodePage(this.mwebSettingsViewModelBase, {super.key});

  final MwebSettingsViewModelBase mwebSettingsViewModelBase;

  @override
  State<MwebNodePage> createState() => _MwebNodePageState();
}

class _MwebNodePageState extends State<MwebNodePage> {
  late final TextEditingController _nodeUriController =
      TextEditingController(text: widget.mwebSettingsViewModelBase.mwebNodeUri);

  @override
  void dispose() {
    _nodeUriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ModalPageWrapper(
        topBar: ModalTopBar(
            title: S.current.litecoin_mweb_settings,
            onLeadingPressed: Navigator.of(context).pop,
            leadingSemanticLabel: S.current.seed_alert_back,
            leadingIcon: Icon(Icons.arrow_back_ios_new)),
        content: Container(
          child: NewListSections(controllers: {
            widget.mwebSettingsViewModelBase.mwebNodeUri: _nodeUriController,
          }, sections: {
            'main': [
              ListItemTextField(
                keyValue: widget.mwebSettingsViewModelBase.mwebNodeUri,
                label: S.current.node_address,
                validator: NodePathValidator(),
              ),
            ]
          }),
        ),
        bottomContent: LoadingPrimaryButton(
          onPressed: () => save(context),
          text: S.of(context).save,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  void save(BuildContext context) {
    widget.mwebSettingsViewModelBase.setMwebNodeUri(_nodeUriController.text);
    Navigator.pop(context);
  }
}
