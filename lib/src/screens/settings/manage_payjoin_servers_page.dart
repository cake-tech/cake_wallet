import 'package:cake_wallet/entities/payjoin/payjoin_server.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart' show NodeSpeed;
import 'package:cake_wallet/view_model/payjoin/payjoin_server_list_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagePayjoinServersPage extends StatelessWidget {
  ManagePayjoinServersPage({required this.viewModel});

  final PayjoinServerListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: _ManagePayjoinServersBody(),
    );
  }
}

class _ManagePayjoinServersBody extends StatefulWidget {
  @override
  State<_ManagePayjoinServersBody> createState() =>
      _ManagePayjoinServersBodyState();
}

class _ManagePayjoinServersBodyState
    extends State<_ManagePayjoinServersBody> {
  @override
  Widget build(BuildContext context) {
    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: S.of(context).payjoin_servers,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        onLeadingPressed: () => Navigator.of(context).pop(),
        trailingWidget: Row(
          spacing: 8,
          children: [
            Consumer<PayjoinServerListViewModel>(
              builder: (_, vm, __) => ModernButton(
                size: 36,
                icon: vm.isTesting
                    ? CupertinoActivityIndicator()
                    : Icon(Icons.refresh),
                onPressed: () => vm.checkHealth(),
              ),
            ),
            ModernButton(
              size: 36,
              icon: Icon(Icons.add),
              onPressed: () => _showAddDialog(context),
            ),
          ],
        ),
      ),
      header: ModalHeader(
        iconPath: 'assets/new-ui/settings_row_icons/payjoin.svg',
        message: S.of(context).manage_payjoin_servers_description,
        title: S.of(context).payjoin,
      ),
      content: Consumer<PayjoinServerListViewModel>(
        builder: (_, vm, __) => ListView(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          children: [
            _buildSection(
              context,
              S.of(context).ohttp_relays,
              vm.relays,
              vm,
            ),
            SizedBox(height: 24),
            _buildSection(
              context,
              S.of(context).payjoin_directories,
              vm.directories,
              vm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<PayjoinServer> servers,
    PayjoinServerListViewModel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 18, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: servers.length,
              separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 1,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
              ),
              itemBuilder: (_, index) {
                final server = servers[index];
                return _PayjoinServerRow(
                  server: server,
                  onDelete: () => vm.removeServer(server),
                  onEdit: (s) => _showServerDialog(context, editing: s),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) => _showServerDialog(context);

  void _showServerDialog(
    BuildContext context, {
    PayjoinServer? editing,
  }) {
    final vm = context.read<PayjoinServerListViewModel>();

    showDialog(
      context: context,
      builder: (_) => _PayjoinServerDialog(
        editing: editing,
        viewModel: vm,
      ),
    );
  }
}

class _PayjoinServerDialog extends StatefulWidget {
  const _PayjoinServerDialog({
    required this.viewModel,
    this.editing,
  });

  final PayjoinServer? editing;
  final PayjoinServerListViewModel viewModel;

  @override
  State<_PayjoinServerDialog> createState() => _PayjoinServerDialogState();
}

class _PayjoinServerDialogState extends State<_PayjoinServerDialog> {
  late final TextEditingController _urlController;
  late PayjoinServerType _selectedType;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.editing?.url);
    _selectedType = widget.editing?.type ?? PayjoinServerType.relay;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.editing == null ? S.of(context).add_server : S.of(context).edit_server),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://example.com',
              labelText: S.of(context).server_url,
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          SegmentedButton<PayjoinServerType>(
            segments: [
              ButtonSegment(
                value: PayjoinServerType.relay,
                label: Text(S.of(context).ohttp_relay),
              ),
              ButtonSegment(
                value: PayjoinServerType.directory,
                label: Text(S.of(context).payjoin_directory),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<PayjoinServerType> selected) {
              setState(() => _selectedType = selected.first);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).cancel),
        ),
        TextButton(
          onPressed: () {
            final url = _urlController.text.trim();
            if (url.isEmpty) return;
            if (widget.editing == null) {
              widget.viewModel.addServer(url, _selectedType);
            } else {
              widget.viewModel.updateServer(widget.editing!, url);
            }
            Navigator.of(context).pop();
          },
          child: Text(widget.editing == null ? S.of(context).add : S.of(context).save),
        ),
      ],
    );
  }
}

class _PayjoinServerRow extends StatelessWidget {
  final PayjoinServer server;
  final VoidCallback onDelete;
  final void Function(PayjoinServer) onEdit;

  const _PayjoinServerRow({
    required this.server,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _showActions(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          child: Row(
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      server.label,
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      server.url,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      children: [
        _buildSpeedBadge(context),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showActions(context),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 12.0),
            child: CakeImageWidget(
              imageUrl: 'assets/new-ui/3dots_vertical.svg',
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedBadge(BuildContext context) {
    if (server.isTesting) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CupertinoActivityIndicator(),
      );
    }
    final speed = server.isLive ? NodeSpeed.fast : NodeSpeed.disconnected;
    return CakeImageWidget(
      imageUrl: Theme.of(context).brightness == Brightness.dark
          ? speed.darkIconPath
          : speed.iconPath,
      width: 24,
      height: 24,
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text(S.of(context).edit),
              onTap: () {
                Navigator.of(ctx).pop();
                onEdit(server);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                S.of(context).remove,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).remove_server),
        content: Text(S.of(context).remove_server_confirm(server.url)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.of(ctx).pop();
            },
            child: Text(S.of(context).remove),
          ),
        ],
      ),
    );
  }
}
