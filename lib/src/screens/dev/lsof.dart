import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/dev/lsof_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DevLsof extends BasePage {
  final LsofViewModel viewModel = LsofViewModel();

  DevLsof() {
    viewModel.refresh();
  }

  @override
  String? get title => "[dev] lsof";

  @override
  Widget? trailing(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.refresh),
      onPressed: () => viewModel.refresh(),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        if (viewModel.logs == null) {
          return Center(child: CircularProgressIndicator());
        }

        if (viewModel.logs == "") {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No logs loaded"),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.refresh(),
                  child: Text("Load Logs"),
                ),
              ],
            ),
          );
        }
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectableText(
                  viewModel.logs??'',
                  style: TextStyle(fontSize: 6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 