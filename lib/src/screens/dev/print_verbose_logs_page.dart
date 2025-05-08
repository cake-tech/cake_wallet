import 'dart:io';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/view_model/dev/print_verbose_view_model.dart';

class PrintVerboseLogsPage extends BasePage {

  final PrintVerboseViewModel viewModel = PrintVerboseViewModel();

  PrintVerboseLogsPage();

  @override
  String? get title => "[dev] print verbose logs";

  @override
  Widget? trailing(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.download, size: 20),
      onPressed: () => _shareLog(context),
    );
  }

  Future<void> _shareLog(BuildContext context) async {
    if (viewModel.logFilePath == null) {
      return;
    }
    final file = File(viewModel.logFilePath!);
    if (await file.exists()) {
      await ShareUtil.shareFile(
        filePath: file.path,
        fileName: 'Print verbose log',
        context: context,
      );
    }
  }

  Future<String?> _loadLog() async {
    if (viewModel.logFilePath == null) {
      return null;
    }
    final file = File(viewModel.logFilePath!);
    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  List<String> _logFiles() {
    final dir = Directory(viewModel.logDirecoryPath);
    if (!dir.existsSync()) {
      return [];
    }
    return dir.listSync().map((e) => e.path).toList();
  }

  Widget logSelector() {
    return ListView.builder(
      itemCount: _logFiles().length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_logFiles()[index]),
          onTap: () {
            viewModel.logFilePath = _logFiles()[index];
          },
        );
      },
    );
  }

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (context) {
      return actualBody(context);
    });
  }

  Widget actualBody(BuildContext context) {
    if (viewModel.logFilePath == null) {
      return logSelector();
    }
    return Scaffold(
      body: FutureBuilder<String?>(
        future: _loadLog(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final text = snap.data;
          if (text == null || text.isEmpty) {
            return Center(child: Text('No log records found.'));
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SelectableText(
              text,
              style: TextStyle(fontFamily: 'monospace', fontSize: 8),
            ),
          );
        },
      ),
    );
  }
}
