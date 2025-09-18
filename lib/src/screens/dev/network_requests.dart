import 'dart:convert';
import 'dart:typed_data';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dev/moneroc_cache_debug.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/dev/network_requests_view_model.dart';
import 'package:cw_core/utils/proxy_logger/abstract.dart';
import 'package:cw_core/utils/proxy_logger/memory_proxy_logger.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/abstract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:on_chain/solana/solana.dart';

class DevNetworkRequests extends BasePage {
  final NetworkRequestsViewModel viewModel = NetworkRequestsViewModel();

  DevNetworkRequests() {
    viewModel.loadLogs();
  }

  @override
  String? get title => "[dev] network requests";

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
        if (viewModel.logs.isEmpty) {
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
        } else {
          return ListView.builder(
            itemCount: viewModel.logs.length,
            itemBuilder: (BuildContext context, int i) {
              final item = viewModel.logs[i];
              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return DevRequestDetails(item);
                      },
                    ),
                  );
                },
                leading: switch (item.network) {
                  RequestNetwork.clearnet => Text("C"),
                  RequestNetwork.tor => Text("T"),
                },
                trailing: switch (item.method) {
                  RequestMethod.get => Text("GET"),
                  RequestMethod.post => Text("POST"),
                  RequestMethod.put => Text("PUT"),
                  RequestMethod.delete => Text("DELETE"),
                  RequestMethod.newHttpClient ||
                  RequestMethod.newHttpIOClient ||
                  RequestMethod.newProxySocket => null,
                },
                title: Text(item.time.toIso8601String()),
                subtitle: switch (item.method) {
                  RequestMethod.get ||
                  RequestMethod.post ||
                  RequestMethod.put ||
                  RequestMethod.delete => Text("${item.uri}"),
                  RequestMethod.newHttpClient => Text("newHttpClient"),
                  RequestMethod.newHttpIOClient => Text("newHttpIOClient"),
                  RequestMethod.newProxySocket => Text("newProxySocket"),
                },
                tileColor: item.error != null ? Colors.red : null,
              );
            },
          );
        }
      },
    );
  }
}

class DevRequestDetails extends BasePage {
  final MemoryProxyLoggerEntry req;
  DevRequestDetails(this.req);

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Time"),
        SelectableText(req.time.toString()),

        _sectionTitle("Method"),
        SelectableText(req.method.toString()),

        _sectionTitle("URI"),
        SelectableText(req.uri?.toString() ?? "null"),

        _sectionTitle("Network"),
        SelectableText(req.network.toString()),

        if (req.network == RequestNetwork.tor)
          ...[
            _sectionTitle("Tor socks server"),
            SelectableText(CakeTor.instance.runtimeType.toString()),
            _sectionTitle("Tor socks details"),
            SelectableText(CakeTor.instance.toString()),
          ],

        _sectionTitle("Body (as UTF-8)"),
        SelectableText(_tryDecodeBody(req.body)),
        _buildJsonExplorer(context, _tryDecodeBody(req.body)),

        _sectionTitle("Response"),
        SelectableText(req.response?.body ?? "null"),
        _buildJsonExplorer(context, req.response?.body ?? "{}"),

        _sectionTitle("Error"),
        SelectableText(req.error ?? "No error"),

        _sectionTitle("Stack Trace"),
        SelectableText(req.trace.toString()),
      ],
    );
  }

  Widget _buildJsonExplorer(BuildContext context, String body) {
    try {
    final jsonData = json.decode(body);
    return PrimaryButton(
      text: "View JSON",
      color: Colors.blue,
      textColor: Colors.white,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return JsonExplorerPage(data: jsonData, title: "body");
            },
          ),
        );
      },
    );

    } catch (e) {
      return SelectableText("Invalid JSON: $e");
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  String _tryDecodeBody(Uint8List body) {
    try {
      return utf8.decode(body);
    } catch (_) {
      return 'Binary data (${body.length} bytes)';
    }
  }
}
