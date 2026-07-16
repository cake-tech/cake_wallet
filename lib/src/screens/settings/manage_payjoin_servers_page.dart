import 'package:cake_wallet/entities/payjoin/payjoin_server.dart';
import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_indicator.dart';
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
        title: 'Payjoin Servers',
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
        message: 'Manage OHTTP relays and payjoin directories used for Payjoin v2.',
        title: 'Payjoin',
      ),
      content: Consumer<PayjoinServerListViewModel>(
        builder: (_, vm, __) => ListView(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          children: [
            _buildSection(
              context,
              'OHTTP Relays',
              vm.relays,
              vm,
            ),
            SizedBox(height: 24),
            _buildSection(
              context,
              'Payjoin Directories',
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
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final urlController = TextEditingController();
    PayjoinServerType selectedType = PayjoinServerType.relay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  labelText: 'Server URL',
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<PayjoinServerType>(
                value: selectedType,
                decoration: InputDecoration(labelText: 'Type'),
                items: [
                  DropdownMenuItem(
                    value: PayjoinServerType.relay,
                    child: Text('OHTTP Relay'),
                  ),
                  DropdownMenuItem(
                    value: PayjoinServerType.directory,
                    child: Text('Payjoin Directory'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedType = v);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  final vm = context.read<PayjoinServerListViewModel>();
                  vm.addServer(url, selectedType);
                  Navigator.of(ctx).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayjoinServerRow extends StatelessWidget {
  final PayjoinServer server;
  final VoidCallback onDelete;

  const _PayjoinServerRow({
    required this.server,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            spacing: 12,
            children: [
              NodeIndicator(isLive: server.isLive),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      server.label,
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      server.url,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (server.isDefault)
                Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (server.isTesting)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CupertinoActivityIndicator(),
                ),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.remove_circle_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Server'),
        content: Text('Remove ${server.url}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.of(ctx).pop();
            },
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }
}
