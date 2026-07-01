import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dev/moneroc_cache_debug.dart';
import 'package:cake_wallet/view_model/dev/qr_tools_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DevQRToolsPage extends BasePage {
  @override
  String? get title => "[dev] *QR tools";

  final QRToolsViewModel viewModel = QRToolsViewModel();

  late final textCtrl = TextEditingController(text: viewModel.input);

  @override
  Widget body(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: textCtrl,
            maxLines: 8,
            onChanged: (value) {
              viewModel.input = value;
            }
          ),
          Observer(
            builder: (_) {
              return Expanded(
              child: JsonExplorer(data: viewModel.data, title: "result"),
            );
            },
          ),
        ],
      ),
    );
  }
}