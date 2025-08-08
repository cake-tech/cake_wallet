import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class DevMoneroWalletCacheDebugPage extends StatelessWidget {
  DevMoneroWalletCacheDebugPage();

  @override
  Widget build(BuildContext context) {
    return MoneroCacheDebug();
  }
}

class MoneroCacheDebug extends StatefulWidget {
  const MoneroCacheDebug({super.key});

  @override
  State<MoneroCacheDebug> createState() => _MoneroCacheDebugState();
}

enum DebuggableWallets {
  monero,
}

class _MoneroCacheDebugState extends State<MoneroCacheDebug> {
  final dashboardViewModel = getIt.get<DashboardViewModel>();

  late DebuggableWallets wallet = switch (dashboardViewModel.wallet.type) {
    WalletType.monero => DebuggableWallets.monero,
    _ => throw Exception("Unknown wallet type"),
  };

  late Map<String, dynamic> walletCache = switch (wallet) {
    DebuggableWallets.monero => monero!.getWalletCacheDebug(),
  };

  @override
  Widget build(BuildContext context) {
    return JsonExplorerPage(
      data: walletCache,
      title: 'Wallet Cache',
    );
  }
}

class JsonExplorerPage extends StatelessWidget {
  final dynamic data;
  final String title;

  const JsonExplorerPage({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => _copyToClipboard(context),
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all to clipboard',
          ),
        ],
      ),
      body: JsonExplorer(
        data: data,
        title: title,
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final jsonString = JsonEncoder.withIndent('  ').convert(data);
    try {
      await Clipboard.setData(ClipboardData(text: jsonString));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data copied to clipboard')),
      );
      return;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy to clipboard: $e')),
      );
    }
    try {
      final appDir = await getAppDir();
      final filePath = appDir.path + '/.json_dump_temp.json';
      await File(filePath).writeAsString(jsonString);
      await ShareUtil.shareFile(filePath: filePath, fileName: path.basename(filePath), context: context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share file: $e')),
      );
    }
  }
}

class JsonExplorer extends StatefulWidget {
  final dynamic data;
  final String title;

  const JsonExplorer({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  State<JsonExplorer> createState() => _JsonExplorerState();
}

class _JsonExplorerState extends State<JsonExplorer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<CacheItem> _filteredItems = [];
  final List<CacheItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _buildItemList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _buildItemList() {
    _allItems.clear();
    
    if (widget.data is Map) {
      final map = widget.data as Map<String, dynamic>;
      final sortedKeys = map.keys.toList()..sort();
      
      for (final key in sortedKeys) {
        _allItems.add(CacheItem(
          key: key,
          value: map[key],
          displayKey: key,
        ));
      }
    } else if (widget.data is List) {
      final list = widget.data as List;
      for (int i = 0; i < list.length; i++) {
        _allItems.add(CacheItem(
          key: i.toString(),
          value: list[i],
          displayKey: '[$i]',
        ));
      }
    }
    
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredItems = _allItems;
    } else {
      _filteredItems = _allItems.where((item) {
        return item.displayKey.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               _valueContainsSearch(item.value, _searchQuery.toLowerCase());
      }).toList();
    }
  }

  bool _valueContainsSearch(dynamic value, String search) {
    if (value == null) return false;
    return value.toString().toLowerCase().contains(search);
  }

  void _copyItemToClipboard(CacheItem item) {
    final jsonString = JsonEncoder.withIndent('  ').convert(item.value);
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.displayKey} copied to clipboard')),
    );
  }

  void _navigateToItem(CacheItem item) {
    if (item.value is Map || item.value is List) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JsonExplorerPage(
            data: item.value,
            title: item.displayKey,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = widget.data is Map 
        ? (widget.data as Map).length 
        : widget.data is List 
            ? (widget.data as List).length 
            : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search in ${totalItems} items...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixText: _searchQuery.isNotEmpty 
                        ? '${_filteredItems.length} found'
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilter();
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _filteredItems.isEmpty && _searchQuery.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No items found for "${_searchQuery}"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return CacheItemTile(
                      item: item,
                      onTap: () => _navigateToItem(item),
                      onCopy: () => _copyItemToClipboard(item),
                      searchQuery: _searchQuery,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class CacheItem {
  final String key;
  final dynamic value;
  final String displayKey;

  CacheItem({
    required this.key,
    required this.value,
    required this.displayKey,
  });
}

class CacheItemTile extends StatelessWidget {
  final CacheItem item;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final String searchQuery;

  const CacheItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onCopy,
    this.searchQuery = '',
  });

  Color _getTypeColor(BuildContext context, dynamic value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (value == null) {
      return Colors.grey;
    }
    
    switch (value.runtimeType) {
      case String:
        return Colors.green;
      case int:
      case double:
        return Colors.blue;
      case bool:
        return Colors.orange;
      // ignore: strict_raw_type
      case Map:
        return Colors.purple;
      // ignore: strict_raw_type
      case List:
        return Colors.cyan;
      default:
        return Colors.pink;
    }
  }

  String _getValuePreview(dynamic value) {
    if (value == null) return 'null';
    
    if (value is Map) {
      return '{${value.length} items}';
    }
    
    if (value is List) {
      return '[${value.length} items]';
    }
    
    if (value is String) {
      if (value.length > 100) {
        return '"${value.substring(0, 97)}..."';
      }
      return '"$value"';
    }
    
    final str = value.toString();
    if (str.length > 100) {
      return '${str.substring(0, 97)}...';
    }
    return str;
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          matches.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }

      if (index > start) {
        matches.add(TextSpan(text: text.substring(start, index), style: style));
      }

      matches.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style.copyWith(
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return RichText(text: TextSpan(children: matches));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canNavigate = item.value is Map || item.value is List;
    final valuePreview = _getValuePreview(item.value);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          canNavigate 
              ? (item.value is Map ? Icons.folder : Icons.list)
              : Icons.description,
          color: _getTypeColor(context, item.value),
        ),
        title: _buildHighlightedText(
          item.displayKey,
          searchQuery,
          theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: _buildHighlightedText(
          valuePreview,
          searchQuery,
          theme.textTheme.bodySmall!.copyWith(
            color: _getTypeColor(context, item.value),
            fontFamily: 'monospace',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy ${item.displayKey}',
            ),
            if (canNavigate)
              const Icon(Icons.chevron_right),
          ],
        ),
        onTap: canNavigate ? onTap : null,
        enabled: canNavigate,
      ),
    );
  }
}