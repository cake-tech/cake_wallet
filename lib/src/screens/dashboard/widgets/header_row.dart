import 'dart:io';

import 'package:cake_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class HeaderRow extends StatelessWidget {
  HeaderRow({required this.dashboardViewModel, super.key});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    final filterIcon = Image.asset('assets/images/filter_icon.png',
        color: Theme.of(context).colorScheme.onSurface);

    return Container(
      height: 52,
      color: Colors.transparent,
      padding: EdgeInsets.only(left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            S.of(context).history,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
          ),
          Spacer(),
          Semantics(
            container: true,
            child: GestureDetector(
              key: ValueKey('transactions_page_header_row_transaction_filter_button_key'),
              onTap: () {
                showPopUp<void>(
                  context: context,
                  builder: (context) => FilterWidget(filterItems: dashboardViewModel.filterItems),
                );
              },
              child: Semantics(
                label: 'Transaction Filter',
                button: true,
                enabled: true,
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: filterIcon,
                ),
              ),
            ),
          ),
          Observer(
            builder: (_) {
              final isExporting = dashboardViewModel.isExporting;
              return Semantics(
                container: true,
                child: GestureDetector(
                  key: ValueKey('exports_transactions_button_key'),
                  onTap: isExporting
                      ? null
                      : () {
                          showPopUp<void>(
                            context: context,
                            builder: (context) => AlertWithTwoActions(
                              // TODO: replace alertTitle and alertContent text with localization strings
                              alertTitle: "Export History",
                              alertContent: 'Export your transaction and swap history',
                              leftButtonText: S.of(context).share,
                              rightButtonText: S.of(context).save,
                              actionLeftButton: () async {
                                Navigator.of(context).pop();
                                final swapData = await dashboardViewModel.exportSwaps() as String;
                                final transactionData =
                                    await dashboardViewModel.exportTransactionsAsCSV();
                                // We need to combine the two CSV data strings into one unified CSV string for sharing

                                final combinedData = transactionData + swapData;

                                ShareUtil.share(
                                  text: combinedData,
                                  context: context,
                                );
                              },
                              actionRightButton: () async {
                                Navigator.of(context).pop();
                                final swapData = await dashboardViewModel.exportSwaps() as String;
                                final transactionData =
                                    await dashboardViewModel.exportTransactionsAsCSV();
                                // We need to combine the two CSV data strings into one unified CSV string for sharing

                                final combinedData = transactionData + swapData;

                                final now = DateTime.now();
                                final formatter = DateFormat('yyyy-MM-dd_HHmm');
                                final fileName = 'cakewallet_history_${formatter.format(now)}.csv';

                                if (Platform.isAndroid) {
                                  try {
                                    const downloadDirPath = '/storage/emulated/0/Download';
                                    final filePath = '$downloadDirPath/$fileName';
                                    final file = File(filePath);
                                    
                                    if (file.existsSync()) {
                                      file.deleteSync();
                                    }
                                    await file.writeAsString(combinedData);
                                    Fluttertoast.showToast(
                                      msg: 'File saved to Downloads folder',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  } catch (e) {
                                    printV('Error saving file on Android: $e');
                                    Fluttertoast.showToast(
                                      msg: 'Failed to save file: ${e.toString()}',
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  }
                                } else if (Platform.isIOS) {
                                  try {
                                    final tempDir = Directory.systemTemp;
                                    final tempFile = File('${tempDir.path}/$fileName');
                                    await tempFile.writeAsString(combinedData);
                                    
                                    await ShareUtil.shareFile(
                                      filePath: tempFile.path,
                                      fileName: fileName,
                                      context: context,
                                    );
                                    // Clean up temp file
                                    if (tempFile.existsSync()) {
                                      tempFile.deleteSync();
                                    }
                                  } catch (e) {
                                    printV('Error on iOS: $e');
                                    Fluttertoast.showToast(
                                      msg: 'Failed to share file: ${e.toString()}',
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  }
                                } else { // Desktop
                                  try {
                                    String? outputFile = await FilePicker.platform.saveFile(
                                      dialogTitle: 'Save Your File to desired location',
                                      fileName: fileName,
                                      type: FileType.custom,
                                      allowedExtensions: ['csv'],
                                    );
                                    
                                    if (outputFile != null) {
                                      final file = File(outputFile);
                                      await file.writeAsString(combinedData);
                                      
                                      printV("File saved to $outputFile");
                                      
                                      // Show success toast
                                      Fluttertoast.showToast(
                                        msg: 'File saved successfully',
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                      );
                                    }
                                  } catch (e) {
                                    printV('Error saving file on Desktop: $e');
                                    Fluttertoast.showToast(
                                      msg: 'Failed to save file: ${e.toString()}',
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                  child: Semantics(
                    label: 'Export Transactions',
                    button: true,
                    enabled: !isExporting,
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      child: isExporting
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            )
                          : Icon(
                              Icons.upload_file,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}