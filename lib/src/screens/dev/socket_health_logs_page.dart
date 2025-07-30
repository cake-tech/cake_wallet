import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/dev/socket_health_logs_view_model.dart';
import 'package:cw_core/utils/socket_health_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';

class DevSocketHealthLogsPage extends BasePage {
  final SocketHealthLogsViewModel viewModel;

  DevSocketHealthLogsPage(this.viewModel) {
    viewModel.loadLogs();
  }

  @override
  String? get title => "[dev] socket health logs";

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        if (viewModel.logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No logs available"),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadLogs(),
                  child: Text("Load Logs"),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _StatsCard(viewModel),
            Expanded(
              child: _LogsList(viewModel),
            ),
            _ActionButtons(viewModel),
          ],
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard(this.viewModel);

  final SocketHealthLogsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Observer(
          builder: (_) => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem('Total', viewModel.totalLogs.toString(), Colors.blue),
                  _StatItem('Healthy', viewModel.healthyLogs.toString(), Colors.green),
                  _StatItem('Unhealthy', viewModel.unhealthyLogs.toString(), Colors.red),
                ],
              ),
              SizedBox(height: 8),
              if (viewModel.error != null)
                Text(
                  'Error: ${viewModel.error}',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _LogsList extends StatelessWidget {
  const _LogsList(this.viewModel);

  final SocketHealthLogsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final logs = viewModel.logs;
        if (logs.isEmpty) {
          return Center(child: Text("No logs available"));
        }

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _LogItem(log);
          },
        );
      },
    );
  }
}

class _LogItem extends StatelessWidget {
  const _LogItem(this.log);

  final SocketHealthLogEntry log;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM-dd HH:mm:ss.SSS');
    final isHealthy = log.isHealthy;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: isHealthy != null ? (isHealthy ? Colors.green[50] : Colors.red[50]) : Colors.grey[50],
      child: ListTile(
        title: Text(
          log.toLogString(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontFamily: 'Monospace',
                fontSize: 11,
                color: isHealthy != null ? (isHealthy ? Colors.green : Colors.red) : Colors.grey,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateFormat.format(log.timestamp)} | ${log.trigger}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            if (log.error != null)
              Text(
                'Error: ${log.error}',
                style: TextStyle(fontSize: 10, color: Colors.red),
              ),
          ],
        ),
        leading: Icon(
          isHealthy != null ? (isHealthy ? Icons.check_circle : Icons.error) : Icons.help,
          color: isHealthy != null ? (isHealthy ? Colors.green : Colors.red) : Colors.grey,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons(this.viewModel);

  final SocketHealthLogsViewModel viewModel;

  void _copyLogsToClipboard(BuildContext context) {
    final logsText = viewModel.getLogsAsText();
    Clipboard.setData(ClipboardData(text: logsText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _testEnhancedHealthCheck(BuildContext context) async {
    final wallet = getIt.get<AppStore>().wallet;
    if (wallet == null || !isElectrumWallet(wallet.type)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No Electrum wallet found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final isHealthy = await wallet.checkSocketHealth();

      SocketHealthLogger().logHealthCheck(
        walletType: wallet.type,
        walletName: wallet.name,
        isHealthy: isHealthy,
        syncStatus: wallet.syncStatus.toString(),
        wasReconnected: true,
        trigger: 'manual_enhanced_health_check',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enhanced health check completed: ${isHealthy ? "Healthy" : "Unhealthy"}'),
          backgroundColor: isHealthy ? Colors.green : Colors.red,
        ),
      );

      viewModel.loadLogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enhanced health check failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshLogs(BuildContext context) {
    viewModel.loadLogs();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logs refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => viewModel.clearLogs(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Clear Logs'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _copyLogsToClipboard(context),
                  child: Text('Copy to Clipboard'),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _testEnhancedHealthCheck(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Enhanced Health Check'),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _refreshLogs(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Refresh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
