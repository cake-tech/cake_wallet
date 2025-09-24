import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/dev/exchange_provider_logs_view_model.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';

class DevExchangeProviderLogsPage extends BasePage {
  final ExchangeProviderLogsViewModel viewModel;

  DevExchangeProviderLogsPage(this.viewModel) {
    viewModel.loadLogs();
  }

  @override
  String? get title => "[dev] exchange provider logs";

  @override
  Widget? trailing(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.refresh),
      onPressed: () => viewModel.refreshLogs(),
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

        if (viewModel.logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No exchange provider logs available"),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsCard(viewModel),
            _LogsHeader(viewModel),
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

class _StatsCard extends StatefulWidget {
  final ExchangeProviderLogsViewModel viewModel;

  const _StatsCard(this.viewModel);

  @override
  State<_StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<_StatsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              "Stats",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                  ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded) ...[
            Observer(
              builder: (_) => Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem("Total", widget.viewModel.totalLogs.toString()),
                        _StatItem("Success", widget.viewModel.successLogs.toString()),
                        _StatItem("Errors", widget.viewModel.errorLogs.toString()),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Logs by Provider:",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    ...widget.viewModel.logsByProvider.entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key.title),
                            Text(entry.value.toString()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogsHeader extends StatelessWidget {
  final ExchangeProviderLogsViewModel viewModel;

  const _LogsHeader(this.viewModel);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Logs",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Observer(
            builder: (_) => PopupMenuButton<LogFilter>(
              tooltip: "Filter logs",
              onSelected: (LogFilter filter) {
                viewModel.setFilter(filter);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: LogFilter.all,
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 18),
                      SizedBox(width: 8),
                      Text("All Logs"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LogFilter.success,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Success Only"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LogFilter.error,
                  child: Row(
                    children: [
                      Icon(Icons.error, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Errors Only"),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, size: 16),
                    SizedBox(width: 4),
                    Text(_getFilterText(viewModel.currentFilter)),
                    Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterText(LogFilter filter) {
    switch (filter) {
      case LogFilter.all:
        return "All";
      case LogFilter.success:
        return "Success";
      case LogFilter.error:
        return "Errors";
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label),
      ],
    );
  }
}

class _LogsList extends StatelessWidget {
  final ExchangeProviderLogsViewModel viewModel;

  const _LogsList(this.viewModel);

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => ListView.builder(
        itemCount: viewModel.filteredLogs.length,
        itemBuilder: (context, index) {
          final log = viewModel.filteredLogs[index];
          return _LogEntryCard(log);
        },
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final ExchangeProviderLogEntry log;

  const _LogEntryCard(this.log);

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              log.isSuccess ? Icons.check_circle : Icons.error,
              color: log.isSuccess ? Colors.green : Colors.red,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "${log.provider.title} - ${log.function}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        subtitle: Text(
          dateFormat.format(log.timestamp),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.error != null) ...[
                  Text(
                    "Error:",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, log.error!),
                      child: Text(
                        log.error!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                if (log.stackTrace != null) ...[
                  Text(
                    "Stack Trace:",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, log.stackTrace!),
                      child: Text(
                        log.stackTrace!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                if (log.callStack != null) ...[
                  Text(
                    "Call Stack:",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, log.callStack!),
                      child: Text(
                        log.callStack!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                if (log.requestData != null) ...[
                  Text(
                    "Request Data:",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, log.requestData.toString()),
                      child: Text(
                        log.requestData.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                if (log.responseData != null) ...[
                  Text(
                    "Response Data:",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, log.responseData.toString()),
                      child: Text(
                        log.responseData.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ExchangeProviderLogsViewModel viewModel;

  const _ActionButtons(this.viewModel);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => _copyLogsAsText(context),
            icon: Icon(Icons.copy, size: 18),
            label: Text("Copy Text"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _copyLogsAsJson(context),
            icon: Icon(Icons.code, size: 18),
            label: Text("Copy JSON"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showClearDialog(context),
            icon: Icon(Icons.clear, size: 18),
            label: Text("Clear"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLogsAsText(BuildContext context) {
    final logsText = viewModel.getLogsAsText();
    Clipboard.setData(ClipboardData(text: logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logs copied to clipboard")),
    );
  }

  void _copyLogsAsJson(BuildContext context) {
    final logsJson = viewModel.getLogsAsJson();
    Clipboard.setData(ClipboardData(text: logsJson));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logs JSON copied to clipboard")),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Exchange Provider Logs"),
        content: Text(
            "Are you sure you want to clear all exchange provider logs? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              viewModel.clearLogs();
              Navigator.of(context).pop();
            },
            child: Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
