import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/dev/background_sync_logs_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';

class DevBackgroundSyncLogsPage extends BasePage {
  final BackgroundSyncLogsViewModel viewModel;

  DevBackgroundSyncLogsPage(this.viewModel) {
    viewModel.loadLogs();
  }

  @override
  String? get title => "[dev] background sync logs";

  @override
  Widget? trailing(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.refresh),
      onPressed: () => viewModel.loadLogs(),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        if (viewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (viewModel.error != null) {
          return Center(child: Text("Error: ${viewModel.error}"));
        }

        if (viewModel.logData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No logs loaded"),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadLogs(),
                  child: Text("Load Logs"),
                ),
              ],
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: "Logs (${viewModel.logs.length})"),
                  Tab(text: "Sessions (${viewModel.sessions.length})"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildLogsTab(context),
                    _buildSessionsTab(context),
                  ],
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab(BuildContext context) {
    final logs = viewModel.logs;
    if (logs.isEmpty) {
      return Center(child: Text("No logs available"));
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          title: Text(
            log.message,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontFamily: 'Monospace',
                ),
          ),
          subtitle: Text(
            '${dateFormat.format(log.timestamp)} | ${log.level}' +
                (log.sessionId != null ? ' | Session: ${log.sessionId}' : ''),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: _getLevelColor(log.level),
                ),
          ),
          dense: true,
          onTap: () {
            Clipboard.setData(ClipboardData(text: log.message));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Log message copied to clipboard')),
            );
          },
          onLongPress: () {
            Clipboard.setData(ClipboardData(
                text: '${dateFormat.format(log.timestamp)} [${log.level}] ${log.message}'));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Full log entry copied to clipboard')),
            );
          },
          tileColor: index % 2 == 0 ? Colors.transparent : Colors.black.withOpacity(0.03),
        );
      },
    );
  }

  Widget _buildSessionsTab(BuildContext context) {
    final sessions = viewModel.sessions;
    if (sessions.isEmpty) {
      return Center(child: Text("No sessions available"));
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isActive = session.endTime == null;

        return ExpansionTile(
          title: Text(
            session.name,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green : null,
                ),
          ),
          subtitle: Text(
            'ID: ${session.id} | Started: ${dateFormat.format(session.startTime)}',
            style: Theme.of(context).textTheme.bodySmall!,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start: ${session.startTime.toString()}'),
                  if (session.endTime != null) Text('End: ${session.endTime.toString()}'),
                  if (session.duration != null)
                    Text('Duration: ${_formatDuration(session.duration!)}'),
                  SizedBox(height: 8),
                  _buildSessionLogs(context, session.id),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionLogs(BuildContext context, int sessionId) {
    final sessionLogs = viewModel.logs.where((log) => log.sessionId == sessionId).toList();

    if (sessionLogs.isEmpty) {
      return Text('No logs for this session');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Logs (${sessionLogs.length}):',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListView.builder(
            itemCount: sessionLogs.length,
            itemBuilder: (context, index) {
              final log = sessionLogs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  '[${log.level}] ${log.message}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontFamily: 'Monospace',
                        color: _getLevelColor(log.level),
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            onPressed: () => viewModel.loadLogs(),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.copy),
            label: Text('Copy All'),
            onPressed: () => _copyAllLogs(context),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete),
            label: Text('Clear'),
            onPressed: () => _confirmClearLogs(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _copyAllLogs(BuildContext context) {
    if (viewModel.logData == null) return;

    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

    for (final log in viewModel.logs) {
      buffer.writeln('${dateFormat.format(log.timestamp)} [${log.level}] ${log.message}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All logs copied to clipboard')),
    );
  }

  void _confirmClearLogs(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Logs'),
          content: Text('Are you sure you want to clear the logs display?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                viewModel.clearLogs();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'debug':
        return Colors.green;
      case 'trace':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
