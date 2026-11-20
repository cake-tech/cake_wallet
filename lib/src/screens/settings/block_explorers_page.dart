import 'package:cake_wallet/entities/block_explorer_settings.dart';
import 'package:cake_wallet/entities/default_block_explorers.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/settings/block_explorer_edit_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

/// Wallet settings page listing the block explorers for one currency (or EVM
/// network), laid out like the Nodes page: the one in use at the top, the
/// built-in default and the user's own explorers below, and + to add one.
class BlockExplorersPage extends StatefulWidget {
  const BlockExplorersPage({
    required this.scope,
    required this.settings,
    required this.mempoolApiEnabled,
  });

  final BlockExplorerScope scope;
  final BlockExplorerSettings settings;
  final bool mempoolApiEnabled;

  @override
  State<BlockExplorersPage> createState() => _BlockExplorersPageState();
}

class _BlockExplorersPageState extends State<BlockExplorersPage> {
  late List<SavedBlockExplorer> _explorers;
  SavedBlockExplorer? _selected;

  BlockExplorerScope get _scope => widget.scope;

  String get _defaultHost => defaultExplorerHost(_scope.walletType, chainId: _scope.chainId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _explorers = widget.settings.explorers(_scope);
    _selected = widget.settings.selected(_scope);
  }

  void _reload() => setState(_load);

  Future<void> _openEditor({SavedBlockExplorer? editing}) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BlockExplorerEditPage(
        scope: _scope,
        settings: widget.settings,
        editing: editing,
      ),
    ));
    if (mounted) _reload();
  }

  Future<void> _confirmSelect({required String name, required String? id}) async {
    await showPopUp<void>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(dialogContext).block_explorer_change_title,
        alertContent: S.of(dialogContext).block_explorer_change_message(name),
        leftButtonText: S.of(dialogContext).cancel,
        rightButtonText: S.of(dialogContext).change,
        actionLeftButton: () => Navigator.of(dialogContext).pop(),
        actionRightButton: () async {
          await widget.settings.select(_scope, id);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          if (mounted) _reload();
        },
      ),
    );
  }

  Widget _defaultRow({required bool isSelected}) => _ExplorerRow(
        title: _defaultHost,
        isDefault: true,
        isSelected: isSelected,
        onTap: isSelected ? () {} : () => _confirmSelect(name: _defaultHost, id: null),
      );

  Widget _savedRow(SavedBlockExplorer explorer, {required bool isSelected}) => _ExplorerRow(
        title: explorer.displayName,
        subtitle: explorer.name.isNotEmpty ? explorer.host : null,
        isSelected: isSelected,
        onTap:
            isSelected ? () {} : () => _confirmSelect(name: explorer.displayName, id: explorer.id),
        onEdit: () => _openEditor(editing: explorer),
      );

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final otherRows = <Widget>[
      if (selected != null) _defaultRow(isSelected: false),
      for (final explorer in _explorers)
        if (explorer.id != selected?.id) _savedRow(explorer, isSelected: false),
    ];

    final noteStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: S.of(context).block_explorers,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        leadingSemanticLabel: S.of(context).seed_alert_back,
        onLeadingPressed: () => Navigator.of(context).pop(),
        trailingWidget: ModernButton(
          size: 36,
          icon: Icon(Icons.add),
          semanticLabel: S.of(context).block_explorer_add,
          onPressed: () => _openEditor(),
        ),
      ),
      header: ModalHeader(
        iconPath: "assets/new-ui/settings_row_icons/connections.svg",
        title: S.of(context).block_explorers,
        message: _scope.usesMempool
            ? S.of(context).block_explorers_bitcoin_desc
            : S.of(context).block_explorers_desc,
        bottomWidget: selected == null
            ? _defaultRow(isSelected: true)
            : _savedRow(selected, isSelected: true),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (otherRows.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    for (int i = 0; i < otherRows.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            height: 1,
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          ),
                        ),
                      otherRows[i],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_scope.usesMempool && selected != null && !widget.mempoolApiEnabled) ...[
            Text(S.of(context).block_explorer_mempool_api_off, style: noteStyle),
            const SizedBox(height: 8),
          ],
          Text(S.of(context).block_explorer_onion_note, style: noteStyle),
        ],
      ),
    );
  }
}

/// One explorer in the list, styled like a node row.
class _ExplorerRow extends StatelessWidget {
  const _ExplorerRow({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.isDefault = false,
    this.onEdit,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            spacing: 12,
            children: [
              isSelected
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.check, size: 16, color: colors.primary),
                    )
                  : const SizedBox(width: 24, height: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault)
                          CakeImageWidget(
                            imageUrl: "assets/new-ui/default_node.svg",
                            colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                          ),
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, left: 12.0),
                    child: CakeImageWidget(
                      imageUrl: "assets/new-ui/3dots_vertical.svg",
                      colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                    ),
                  ),
                )
              else
                const SizedBox(width: 44, height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
