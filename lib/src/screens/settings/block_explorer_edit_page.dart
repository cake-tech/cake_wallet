import 'package:cake_wallet/entities/block_explorer_settings.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

/// Adds a block explorer, or edits or deletes one, like the node editor.
class BlockExplorerEditPage extends StatefulWidget {
  const BlockExplorerEditPage({
    required this.scope,
    required this.settings,
    this.editing,
  });

  final BlockExplorerScope scope;
  final BlockExplorerSettings settings;
  final SavedBlockExplorer? editing;

  @override
  State<BlockExplorerEditPage> createState() => _BlockExplorerEditPageState();
}

class _BlockExplorerEditPageState extends State<BlockExplorerEditPage> {
  static const _nameKey = 'block_explorer_name';
  static const _addressKey = 'block_explorer_address';

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      _nameKey: TextEditingController(text: widget.editing?.name ?? ''),
      _addressKey: TextEditingController(text: widget.editing?.url ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateAddress(String? value) =>
      BlockExplorerSettings.isValidExplorer(widget.scope, value ?? '')
          ? null
          : S.current.block_explorer_invalid_url;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _controllers[_nameKey]!.text;
    final url = _controllers[_addressKey]!.text;
    final editing = widget.editing;

    if (editing == null) {
      await widget.settings.add(widget.scope, name: name, url: url);
    } else {
      await widget.settings.update(
        widget.scope,
        SavedBlockExplorer(id: editing.id, name: name, url: url),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final editing = widget.editing!;
    final confirmed = await showPopUp<bool>(
          context: context,
          builder: (dialogContext) => AlertWithTwoActions(
            alertTitle: S.of(dialogContext).block_explorer_delete_title,
            alertContent: S.of(dialogContext).block_explorer_delete_message(editing.displayName),
            rightButtonText: S.of(dialogContext).remove,
            leftButtonText: S.of(dialogContext).cancel,
            actionRightButton: () => Navigator.pop(dialogContext, true),
            actionLeftButton: () => Navigator.pop(dialogContext, false),
          ),
        ) ??
        false;

    if (!confirmed) return;
    await widget.settings.remove(widget.scope, editing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    final noteStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              title:
                  isEditing ? S.of(context).block_explorer_edit : S.of(context).block_explorer_new,
              leadingIcon: Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: Navigator.of(context).pop,
              trailingIcon: Icon(Icons.check),
              trailingSemanticLabel: S.of(context).save,
              onTrailingPressed: _save,
            ),
            Expanded(
              child: KeyboardHideOverlay(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 18,
                    children: [
                      Form(
                        key: _formKey,
                        child: NewListSections(
                          controllers: _controllers,
                          sections: {
                            "": [
                              ListItemTextField(
                                keyValue: _nameKey,
                                label: S.of(context).block_explorer_name,
                              ),
                              ListItemTextField(
                                keyValue: _addressKey,
                                label: widget.scope.usesMempool
                                    ? S.of(context).block_explorer_mempool_address
                                    : S.of(context).block_explorer_address,
                                validator: _validateAddress,
                              ),
                            ],
                          },
                        ),
                      ),
                      Text(
                        widget.scope.usesMempool
                            ? S.of(context).block_explorer_mempool_address_note
                            : S.of(context).block_explorer_address_note,
                        style: noteStyle,
                      ),
                      if (isEditing)
                        NewListSections(sections: {
                          "": [
                            ListItemRegularRow(
                              keyValue: "delete_block_explorer",
                              label: S.of(context).block_explorer_delete,
                              foregroundColor: Theme.of(context).colorScheme.errorContainer,
                              showArrow: false,
                              onTap: _delete,
                            ),
                          ],
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
