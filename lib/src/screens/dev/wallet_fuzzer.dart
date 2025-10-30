import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/dev/wallet_fuzzer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';

class WalletFuzzerPage extends BasePage {
  WalletFuzzerPage();

  @override
  String? get title => "[dev] wallet fuzzer";

  final viewModel = WalletFuzzerViewModel();

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        return Column(
          children: [
            _buildStatusBar(context),
            Expanded(
              child: _buildLogsList(context),
            ),
            _buildControls(context),
          ],
        );
      },
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      color: Theme.of(context).primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                viewModel.isRunning ? Icons.warning_amber : Icons.info_outline,
                color: viewModel.isRunning ? Colors.amber : Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Status: ${viewModel.isRunning ? "RUNNING" : "Stopped"}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: viewModel.isRunning ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: viewModel.isRunning ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  'Ops: ${viewModel.operationsCompleted}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  'Errors: ${viewModel.errorsEncountered}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Current Operation: ${viewModel.currentOperation}',
            style: TextStyle(color: Colors.white),
          ),
          Text(
            'Current Wallet: ${viewModel.currentWallet.isEmpty ? "none" : viewModel.currentWallet}',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Logs:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep),
                onPressed: () => viewModel.clearLogs(),
                tooltip: 'Clear logs',
              ),
            ],
          ),
          Divider(),
          Expanded(
            child: viewModel.logs.isEmpty
                ? Center(child: Text('No logs yet. Start fuzzing to see logs.'))
                : ListView.builder(
                    itemCount: viewModel.logs.length,
                    itemBuilder: (context, index) {
                      final log = viewModel.logs[index];
                      final formattedTime = DateFormat('HH:mm:ss').format(log.timestamp);
                      
                      Color logColor = Colors.black;
                      if (log.action.contains('Error') || log.result?.contains('Error') == true || log.result?.contains('error') == true) {
                        logColor = Colors.red;
                      } else if (log.action.contains('Success') || log.action.contains('successfully')) {
                        logColor = Colors.green;
                      }
                      
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: log.result != null
                                  ? RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: '${log.action} - ',
                                            style: TextStyle(color: logColor),
                                          ),
                                          TextSpan(
                                            text: log.result,
                                            style: TextStyle(
                                              color: logColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      log.action,
                                      style: TextStyle(color: logColor),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: viewModel.isRunning ? Colors.red : Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (viewModel.isRunning) {
                      viewModel.stopFuzzing();
                    } else {
                      viewModel.startFuzzing();
                    }
                  },
                  child: Text(
                    viewModel.isRunning ? 'STOP FUZZING' : 'START FUZZING',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
} 