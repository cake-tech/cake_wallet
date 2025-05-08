import 'dart:io';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class HashChangeLogsPage extends BasePage {
  @override
  String? get title => "[dev] hash change logs";

  @override
  Widget? trailing(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.download, size: 20),
      onPressed: () => _shareLog(context),
    );
  }

  Future<void> _shareLog(BuildContext context) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/hashed_identifier_changes.log');
    if (await file.exists()) {
      await ShareUtil.shareFile(
        filePath: file.path,
        fileName: 'Hash-change log',
        context: context,
      );
    }
  }

  Future<String?> _loadHashLog() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hashed_identifier_changes.log'));
    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  @override
  Widget body(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hash Change Log')),
      body: FutureBuilder<String?>(
        future: _loadHashLog(),
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
            child: Text(
              text,
              style: TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}
