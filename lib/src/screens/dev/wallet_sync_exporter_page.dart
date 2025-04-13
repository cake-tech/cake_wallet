import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/dev/wallet_sync_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class WalletSyncExporterPage extends BasePage {
  final WalletSyncExporter viewModel;

  WalletSyncExporterPage(this.viewModel) {
    viewModel.initialize();
  }

  @override
  String? get title => "[dev] wallet sync exporter";

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusSection(context),
                SizedBox(height: 16),
                _buildSettingsSection(context),
                SizedBox(height: 16),
                _buildControlSection(context),
                SizedBox(height: 16),
                _buildExportInfoSection(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusRow(context, 'Sync in progress:', viewModel.isSyncing ? 'Yes' : 'No'),
              if (viewModel.totalWallets > 0) ...[
                _buildStatusRow(context, 'Progress:', 
                    '${viewModel.currentWalletIndex}/${viewModel.totalWallets} (${viewModel.progress}%)'),
              ],
              _buildStatusRow(context, 'Status:', viewModel.statusMessage),
              _buildStatusRow(context, 'Timer active:',
                  viewModel.syncTimer != null ? 'Yes (${viewModel.exportIntervalMinutes}m)' : 'No'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTextFieldRow(
                context,
                'Export path:',
                viewModel.exportPath,
                (value) => viewModel.setExportPath(value),
              ),
              SizedBox(height: 8),
              _buildTextFieldRow(
                context,
                'Interval (minutes):',
                viewModel.exportIntervalMinutes.toString(),
                (value) {
                  final interval = int.tryParse(value);
                  if (interval != null && interval > 0) {
                    viewModel.setExportInterval(interval);
                  }
                },
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlSection(BuildContext context) {
    final isButtonsEnabled = !viewModel.isSyncing;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            PrimaryButton(
              text: "Sync & Export Now",
              color: Colors.purple,
              textColor: Colors.white,
              onPressed: isButtonsEnabled ? () => viewModel.syncAndExport() : null,
              isDisabled: !isButtonsEnabled,
            ),
            PrimaryButton(
              text: viewModel.syncTimer == null ? "Start Periodic Sync" : "Stop Periodic Sync",
              color: Colors.purple,
              textColor: Colors.white,
              onPressed: isButtonsEnabled
                  ? () {
                      if (viewModel.syncTimer == null) {
                        viewModel.startPeriodicSync();
                      } else {
                        viewModel.stopPeriodicSync();
                      }
                    }
                  : null,
              isDisabled: !isButtonsEnabled,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusRow(
                context,
                'Last export time:',
                viewModel.lastExportTime.isEmpty ? 'Never' : viewModel.lastExportTime,
              ),
            ],
          ),
        ),
        if (viewModel.exportData.isNotEmpty) ...[
          SizedBox(height: 8),
          PrimaryButton(
            text: "View Export Data",
            color: Colors.purple,
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Export Data Summary'),
                    content: Text(_buildDataSummary()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStatusRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldRow(
    BuildContext context,
    String title,
    String value,
    Function(String) onChanged,
    {TextInputType keyboardType = TextInputType.text}
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: value),
            onChanged: onChanged,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildDataSummary() {
    final buffer = StringBuffer();
    final data = viewModel.exportData;
    
    buffer.writeln('Timestamp: ${data['timestamp'] ?? 'Unknown'}');
    buffer.writeln('Wallets: ${(data['wallets'] as List?)?.length ?? 0}');
    
    int totalTransactions = 0;
    for (final wallet in (data['wallets'] as List?) ?? []) {
      if (wallet is Map && wallet['transactions'] is List) {
        totalTransactions += (wallet['transactions'] as List).length;
      }
    }
    buffer.writeln('Total transactions: $totalTransactions');
    
    return buffer.toString();
  }
} 