import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/dev/file_explorer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:watcher/watcher.dart' as watcher;
import 'package:cw_core/root_dir.dart';

class FileExplorerPage extends BasePage {
  FileExplorerPage();

  @override
  String? get title => "[dev] file explorer";

  final viewModel = FileExplorerViewModel();

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        return Column(
          children: [
            _buildTabBar(context),
            Expanded(
              child: _buildContent(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => viewModel.switchToFileExplorer(),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: viewModel.viewMode == ViewMode.fileExplorer 
                        ? Colors.white 
                        : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Files',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: viewModel.viewMode == ViewMode.fileExplorer 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => viewModel.switchToSnapshots(),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: viewModel.viewMode == ViewMode.snapshots 
                        ? Colors.white 
                        : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Snapshots',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: viewModel.viewMode == ViewMode.snapshots 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => viewModel.switchToFileMonitor(),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: viewModel.viewMode == ViewMode.fileMonitor 
                        ? Colors.white 
                        : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Monitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: viewModel.viewMode == ViewMode.fileMonitor 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (viewModel.viewMode) {
      case ViewMode.fileExplorer:
        return _buildFileExplorer(context);
      case ViewMode.snapshots:
        return _buildSnapshotsList(context);
      case ViewMode.hexdump:
        return _buildHexDumpView(context);
      case ViewMode.comparison:
        return _buildSnapshotComparison(context);
      case ViewMode.detailedComparison:
        return _buildDetailedComparison(context);
      case ViewMode.fileMonitor:
        return _buildFileMonitor(context);
    }
  }

  Widget _buildFileExplorer(BuildContext context) {
    return Column(
      children: [
        _buildPathBar(context),
        Expanded(
          child: _buildFileList(context),
        ),
      ],
    );
  }

  Widget _buildPathBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_upward),
                onPressed: viewModel.path == null ? null : () {
                  viewModel.cd('..');
                },
                tooltip: 'Go up',
              ),
              Expanded(
                child: Text(
                  viewModel.path ?? 'Loading...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context) {
    if (viewModel.path == null) {
      return Center(child: CircularProgressIndicator());
    }

    final directories = viewModel.directories;
    final files = viewModel.files;

    return ListView.builder(
      itemCount: directories.length + files.length,
      itemBuilder: (context, index) {
        if (index < directories.length) {
          // Directory item
          final dirName = directories[index];
          return ListTile(
            leading: Icon(Icons.folder, color: Colors.amber),
            title: Text(dirName),
            onTap: () => viewModel.cd(dirName),
          );
        } else {
          // File item
          final fileIndex = index - directories.length;
          final file = files[fileIndex];
          final fileName = p.basename(file.path);
          final fileSize = _getFileSize(file);

          return ListTile(
            leading: Icon(Icons.insert_drive_file, color: Colors.blue),
            title: Text(fileName),
            subtitle: Text(fileSize),
            onTap: () {
              viewModel.selectFile(file as File);
            },
            onLongPress: () => _showFileOptions(context, file as File),
          );
        }
      },
    );
  }

  Future<void> _showFileOptions(BuildContext context, File file) async {
    final fileName = file.path;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Rename/Move'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, file);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                _showCopyDialog(context, file);
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ShareUtil.shareFile(
                  filePath: file.path,
                  fileName: fileName,
                  context: context,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, File file) async {
    final fileName = file.path;
    final controller = TextEditingController(text: fileName);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename/Move File'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'New name/path',
            hintText: 'Enter new name or path',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPath = controller.text.trim();
              if (newPath.isNotEmpty) {
                final success = await viewModel.renameFile(file.path, newPath);
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to rename/move file')),
                  );
                }
              }
            },
            child: Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCopyDialog(BuildContext context, File file) async {
    final fileName = file.path;
    final controller = TextEditingController(text: fileName);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Copy File'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Destination name/path',
            hintText: 'Enter destination name or path',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPath = controller.text.trim();
              if (newPath.isNotEmpty) {
                final success = await viewModel.copyFile(file.path, newPath);
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to copy file')),
                  );
                }
              }
            },
            child: Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, File file) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete File'),
        content: Text('Are you sure you want to delete "${p.basename(file.path)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await viewModel.deleteFile(file.path);
              Navigator.pop(context);
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete file')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotsList(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              _showCreateSnapshotDialog(context);
            },
            child: Text('Create New Snapshot'),
          ),
        ),
        Expanded(
          child: viewModel.snapshots.isEmpty
            ? Center(child: Text('No snapshots yet. Create one to start!'))
            : ListView.builder(
                itemCount: viewModel.snapshots.length,
                itemBuilder: (context, index) {
                  final snapshot = viewModel.snapshots[index];
                  final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(snapshot.timestamp);
                  
                  return ListTile(
                    leading: Icon(Icons.camera_alt, color: Colors.green),
                    title: Text(snapshot.name),
                    subtitle: Text('$formattedDate - ${snapshot.files.length} files'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.compare_arrows, color: Colors.orange),
                          onPressed: () => viewModel.switchToComparison(snapshot),
                          tooltip: 'Compare with current',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteSnapshot(context, snapshot),
                          tooltip: 'Delete snapshot',
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Future<void> _showCreateSnapshotDialog(BuildContext context) async {
    final nameController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Snapshot'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Snapshot Name',
            hintText: 'Enter a name for this snapshot',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                viewModel.createSnapshot(name);
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSnapshot(BuildContext context, Snapshot snapshot) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Snapshot'),
        content: Text('Are you sure you want to delete the snapshot "${snapshot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              viewModel.deleteSnapshot(snapshot);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHexDumpView(BuildContext context) {
    final file = viewModel.selectedFile;
    
    if (file == null) {
      return Center(child: Text('No file selected'));
    }
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => viewModel.switchToFileExplorer(),
                tooltip: 'Back to file list',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.basename(file.path),
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      file.path,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(),
        Expanded(
          child: FutureBuilder<String>(
            future: viewModel.getHexDump(file, maxBytes: 128*1024),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      snapshot.data ?? 'No data',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotComparison(BuildContext context) {
    final snapshot = viewModel.comparisonSnapshot;
    
    if (snapshot == null) {
      return Center(child: Text('No snapshot selected for comparison'));
    }
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => viewModel.switchToSnapshots(),
                tooltip: 'Back to snapshots',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comparing with: ${snapshot.name}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Created: ${DateFormat('yyyy-MM-dd HH:mm').format(snapshot.timestamp)}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _buildChangeBadge(
                Colors.green, 
                viewModel.fileChanges.where((change) => change.type == ChangeType.added).length
              ),
              SizedBox(width: 16),
              _buildChangeBadge(
                Colors.blue, 
                viewModel.fileChanges.where((change) => change.type == ChangeType.touched).length
              ),
              SizedBox(width: 16),
              _buildChangeBadge(
                Colors.orange, 
                viewModel.fileChanges.where((change) => change.type == ChangeType.modified).length
              ),
              SizedBox(width: 16),
              _buildChangeBadge(
                Colors.red, 
                viewModel.fileChanges.where((change) => change.type == ChangeType.removed).length
              ),
            ],
          ),
        ),
        Expanded(
          child: viewModel.fileChanges.isEmpty
            ? Center(child: Text('No changes detected'))
            : ListView.builder(
                itemCount: viewModel.fileChanges.length,
                itemBuilder: (context, index) {
                  final change = viewModel.fileChanges[index];
                  final icon = _getChangeIcon(change.type);
                  final color = _getChangeColor(change.type);
                  
                  String details = '';
                  switch (change.type) {
                    case ChangeType.modified:
                      final oldSize = _formatFileSize(change.oldFile!.size);
                      final newSize = _formatFileSize(change.newFile!.size);
                      details = 'Size: $oldSize → $newSize';
                      break;
                    case ChangeType.added:
                      details = 'Size: ${_formatFileSize(change.newFile!.size)}';
                      break;
                    case ChangeType.removed:
                      details = 'Size: ${_formatFileSize(change.oldFile!.size)}';
                      break;
                    case ChangeType.touched:
                      details = 'Modified timestamp changed';
                      break;
                  }
                  
                  return ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(change.path),
                    subtitle: Text(details),
                    trailing: Text(
                      change.type.toString().split('.').last,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => viewModel.switchToDetailedComparison(change),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildDetailedComparison(BuildContext context) {
    final fileChange = viewModel.selectedFileChange;
    
    if (fileChange == null) {
      return Center(child: Text('No file selected for detailed comparison'));
    }
    
    final color = _getChangeColor(fileChange.type);
    final icon = _getChangeIcon(fileChange.type);
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => viewModel.viewMode = ViewMode.comparison,
                tooltip: 'Back to changes list',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileChange.path,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Status: ${fileChange.type.toString().split('.').last}',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(),
        Expanded(
          child: FutureBuilder<String>(
            future: viewModel.getFileDiff(fileChange),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading file diff (may take time for large files)...'),
                    ],
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final diffText = snapshot.data ?? 'No data available';
              
              return Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(
                          diffText,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    mini: true,
                    child: Icon(Icons.copy),
                    onPressed: () {
                      final data = ClipboardData(text: diffText);
                      Clipboard.setData(data);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Diff copied to clipboard')),
                      );
                    },
                    tooltip: 'Copy diff to clipboard',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChangeBadge(Color color, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChangeIcon(ChangeType type) {
    switch (type) {
      case ChangeType.added:
        return Icons.add_circle;
      case ChangeType.removed:
        return Icons.remove_circle;
      case ChangeType.modified:
        return Icons.edit;
      case ChangeType.touched:
        return Icons.access_time;
    }
  }

  Color _getChangeColor(ChangeType type) {
    switch (type) {
      case ChangeType.added:
        return Colors.green;
      case ChangeType.removed:
        return Colors.red;
      case ChangeType.modified:
        return Colors.orange;
      case ChangeType.touched:
        return Colors.blue;
    }
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (sizeInBytes < 1024 * 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB... why?';
    }
  }

  String _getFileSize(FileSystemEntity entity) {
    try {
      final file = File(entity.path);
      final fileSizeInBytes = file.lengthSync();
      return _formatFileSize(fileSizeInBytes);
    } catch (e) {
      return 'Error getting size';
    }
  }

  Widget _buildFileMonitor(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Monitoring file system events',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: FileExplorerViewModelBase.isMonitoringActive,
                onChanged: (value) {
                  if (value) {
                    FileExplorerViewModelBase.startMonitoring();
                  } else {
                    FileExplorerViewModelBase.stopMonitoring();
                  }
                },
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_sweep),
                onPressed: () => viewModel.clearEvents(),
                tooltip: 'Clear events',
              ),
              IconButton(
                icon: Icon(Icons.restart_alt),
                onPressed: () => _toggleDevMonitorFile(context),
                tooltip: 'Toggle monitoring on app start',
              ),
            ],
          ),
        ),
        Divider(),
        FutureBuilder<bool>(
          future: FileExplorerViewModelBase.checkDevMonitorFileExists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox.shrink();
            }
            
            final devFileExists = snapshot.data ?? false;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    devFileExists ? Icons.check_circle : Icons.cancel,
                    color: devFileExists ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      devFileExists 
                        ? 'Monitor file exists - will start on app launch' 
                        : 'Monitor file does not exist - will not start on app launch',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Divider(),
        Expanded(
          child: Observer(
            builder: (_) {
              final events = FileExplorerViewModelBase.fileEvents;
              
              if (events.isEmpty) {
                return Center(
                  child: Text('No events recorded yet. Toggle monitoring to start.'),
                );
              }
              
              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[events.length - 1 - index]; // Show newest first
                  final icon = _getFileEventIcon(event.event.type);
                  final color = _getFileEventColor(event.event.type);
                  final formattedTime = DateFormat('HH:mm:ss.SSS').format(event.timestamp);
                  
                  return ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(
                      event.relativePath,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${event.event.type.toString().split('.').last} at $formattedTime',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      event.event.type.toString().split('.').last,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    dense: true,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  IconData _getFileEventIcon(watcher.ChangeType type) {
    switch (type) {
      case watcher.ChangeType.ADD:
        return Icons.add_circle;
      case watcher.ChangeType.REMOVE:
        return Icons.remove_circle;
      case watcher.ChangeType.MODIFY:
        return Icons.edit;
      default:
        return Icons.help_outline;
    }
  }
  
  Color _getFileEventColor(watcher.ChangeType type) {
    switch (type) {
      case watcher.ChangeType.ADD:
        return Colors.green;
      case watcher.ChangeType.REMOVE:
        return Colors.red;
      case watcher.ChangeType.MODIFY:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleDevMonitorFile(BuildContext context) async {
    final appDir = await getAppDir();
    final devMonitorFile = File('${appDir.path}/.dev-monitor-fs');
    
    if (await devMonitorFile.exists()) {
      await devMonitorFile.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File monitoring disabled. App restart required.')),
      );
    } else {
      await devMonitorFile.create();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File monitoring enabled. App restart required.')),
      );
    }
  }
}
