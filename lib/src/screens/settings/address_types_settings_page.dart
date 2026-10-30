import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/view_model/settings/address_types_settings_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class AddressTypesSettingsPage extends StatelessWidget {
  const AddressTypesSettingsPage({super.key, required this.addressTypesSettingsViewModel});

  final AddressTypesSettingsViewModel addressTypesSettingsViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).addresses,
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).seed_alert_back,
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: Observer(
                builder: (_) => NewListSections(
                  sections: {
                    "address_types": [
                      for (final option in addressTypesSettingsViewModel.optionalAddressTypes)
                        ListItemToggle(
                          keyValue: "enable_address_type_${option.description}",
                          label: "${S.of(context).enable} ${option.value} (${option.description})",
                          iconPath: option.iconPath,
                          value: addressTypesSettingsViewModel.enabledOptionalAddressTypes
                              .contains(option),
                          onChanged: (value) =>
                              addressTypesSettingsViewModel.setAddressTypeEnabled(option, value),
                        ),
                    ],
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
