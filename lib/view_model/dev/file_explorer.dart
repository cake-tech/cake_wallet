import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

part 'file_explorer.g.dart';

class FileExplorerViewModel = FileExplorerViewModelBase with _$FileExplorerViewModel;

class Snapshot {
  final String name;
  final DateTime timestamp;
  final Map<String, FileInfo> files;

  Snapshot({required this.name, required this.timestamp, required this.files});
}

class FileInfo {
  final String path;
  final int size;
  final DateTime modified;
  final Uint8List? content;

  FileInfo({
    required this.path, 
    required this.size, 
    required this.modified, 
    this.content
  });
}

class FileChange {
  final String path;
  final ChangeType type;
  final FileInfo? oldFile;
  final FileInfo? newFile;

  FileChange({required this.path, required this.type, this.oldFile, this.newFile});
}

enum ChangeType { added, removed, modified, touched }

enum ViewMode { fileExplorer, snapshots, hexdump, comparison, detailedComparison, fileMonitor }

class FileEvent {
  final DateTime timestamp;
  final WatchEvent event;
  final String relativePath;

  FileEvent({required this.timestamp, required this.event, required this.relativePath});
}

abstract class FileExplorerViewModelBase with Store {
  FileExplorerViewModelBase() {
    unawaited(_initialize());
  }

  static ObservableList<FileEvent> fileEvents = ObservableList<FileEvent>();
  
  static DirectoryWatcher? _watcher;
  
  static bool isMonitoringActive = false;

  @observable
  String? path;

  @observable
  String? rootPath;

  @observable
  String? snapshotsPath;

  @observable
  File? selectedFile;

  @observable
  ObservableList<Snapshot> snapshots = ObservableList<Snapshot>();

  @observable
  ViewMode viewMode = ViewMode.fileExplorer;

  @observable
  Snapshot? comparisonSnapshot;

  @observable
  ObservableList<FileChange> fileChanges = ObservableList<FileChange>();
  
  @observable
  FileChange? selectedFileChange;

  static const int MAX_FILE_SIZE = 1 * 1024 * 1024;

  static const int CHUNK_SIZE = 16 * 1024;

  @action
  Future<void> _initialize() async {
    rootPath = (await getAppDir()).path;
    path = rootPath;
    snapshotsPath = p.join(rootPath!, 'snapshots');
    
    final dir = Directory(snapshotsPath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    await loadSnapshots();
  }

  @computed
  List<FileSystemEntity> get files {
    if (path == null) {
      return [];
    }
    
    final dir = Directory(path!);
    final entities = dir.listSync();
    return entities.where((entity) => entity is File).toList();
  }

  @computed
  List<String> get directories {
    if (path == null) {
      return [];
    }
    
    final dir = Directory(path!);
    final entities = dir.listSync();
    return entities.where((entity) => entity is Directory).map((entity) => p.basename(entity.path)).toList();
  }

  @action
  void cd(String newPath) {
    try {
      if (path == null) {
        return;
      }
      final Directory directory = Directory(p.join(path!, newPath));
      final String path2 = directory.absolute.path;
      
      final String normalizedPath = p.normalize(path2);
      final String normalizedRootPath = p.normalize(rootPath!);
      
      final bool isWithinRoot = normalizedPath.startsWith(normalizedRootPath);
      if (!isWithinRoot) {
        path = rootPath;
      } else {
        path = path2;
      }
    } catch (e) {
      path = rootPath;
    }
  }

  @action
  void selectFile(File file) {
    selectedFile = file;
    viewMode = ViewMode.hexdump;
  }

  @action
  void switchToFileExplorer() {
    viewMode = ViewMode.fileExplorer;
  }

  @action
  void switchToSnapshots() {
    viewMode = ViewMode.snapshots;
  }

  @action
  void switchToComparison(Snapshot snapshot) {
    comparisonSnapshot = snapshot;
    viewMode = ViewMode.comparison;
    compareSnapshot();
  }

  @action
  void switchToDetailedComparison(FileChange fileChange) {
    selectedFileChange = fileChange;
    viewMode = ViewMode.detailedComparison;
  }

  @action
  void switchToFileMonitor() {
    viewMode = ViewMode.fileMonitor;
  }

  Future<String> getHexDump(File file, {int? maxBytes}) async {
    try {
      final bytes = await file.readAsBytes();
      final bytesToRead = maxBytes != null && bytes.length > maxBytes ? maxBytes : bytes.length;
      final buffer = StringBuffer();
      
      for (var i = 0; i < bytesToRead; i += 16) {
        // Address
        buffer.write('${i.toRadixString(16).padLeft(8, '0')}: ');
        
        // Hex values
        for (var j = 0; j < 16; j++) {
          if (i + j < bytesToRead) {
            buffer.write('${bytes[i + j].toRadixString(16).padLeft(2, '0')} ');
          } else {
            buffer.write('   ');
          }
          if (j == 7) buffer.write(' ');
        }
        
        // ASCII representation
        buffer.write(' |');
        for (var j = 0; j < 16; j++) {
          if (i + j < bytesToRead) {
            final char = bytes[i + j];
            // Show printable ASCII characters
            if (char >= 32 && char <= 126) {
              buffer.write(String.fromCharCode(char));
            } else {
              buffer.write('.');
            }
          } else {
            buffer.write(' ');
          }
        }
        buffer.write('|\n');
      }
      
      if (maxBytes != null && bytes.length > maxBytes) {
        buffer.write('\n... (${bytes.length - maxBytes} more bytes) ...');
      }
      
      return buffer.toString();
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  Future<Uint8List> getFileBytes(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsBytes();
    } catch (e) {
      printV('Error reading file bytes: $e');
      return Uint8List(0);
    }
  }

  Future<String> getHexDiffDump(Uint8List oldBytes, Uint8List newBytes) async {
    final buffer = StringBuffer();
    final maxLength = oldBytes.length > newBytes.length ? oldBytes.length : newBytes.length;
    final minLength = oldBytes.length < newBytes.length ? oldBytes.length : newBytes.length;
    
    // Standard for hexdump displays
    final chunkSize = 16; 

    int totalBlocks = (maxLength / chunkSize).ceil();
    int diffBlocks = 0;
    int sameBlocks = 0;
    
    buffer.writeln('=== Binary Diff Summary ===');
    buffer.writeln('Old size: ${_formatSize(oldBytes.length)}');
    buffer.writeln('New size: ${_formatSize(newBytes.length)}');
    buffer.writeln('Size difference: ${_formatSizeDifference(newBytes.length - oldBytes.length)}');
    buffer.writeln('');
    buffer.writeln('=== Changed Blocks Only ===');
    
    for (var i = 0; i < maxLength; i += chunkSize) {
      bool hasBlockDiff = false;
      final blockEnd = i + chunkSize < maxLength ? i + chunkSize : maxLength;
      
      for (var j = i; j < blockEnd && j < minLength; j++) {
        if (j < oldBytes.length && j < newBytes.length && oldBytes[j] != newBytes[j]) {
          hasBlockDiff = true;
          break;
        }
      }
      
      if (i >= oldBytes.length || i >= newBytes.length) {
        hasBlockDiff = true;
      }
      
      if (hasBlockDiff) {
        diffBlocks++;
        
        if (i < oldBytes.length) {
          buffer.write('- ');
          buffer.write('${i.toRadixString(16).padLeft(8, '0')}: ');
          
          for (var j = 0; j < chunkSize; j++) {
            if (i + j < oldBytes.length) {
              final byteValue = oldBytes[i + j].toRadixString(16).padLeft(2, '0');
              if (i + j < newBytes.length && oldBytes[i + j] != newBytes[i + j]) {
                buffer.write('[$byteValue] ');
              } else {
                buffer.write(' $byteValue  ');
              }
            } else {
              buffer.write('     ');
            }
            if (j == 7) buffer.write(' ');
          }
          
          buffer.write(' |');
          for (var j = 0; j < chunkSize; j++) {
            if (i + j < oldBytes.length) {
              final char = oldBytes[i + j];
              if (char >= 32 && char <= 126) {
                if (i + j < newBytes.length && oldBytes[i + j] != newBytes[i + j]) {
                  buffer.write('[${String.fromCharCode(char)}]');
                } else {
                  buffer.write(' ${String.fromCharCode(char)} ');
                }
              } else {
                buffer.write(' . ');
              }
            } else {
              buffer.write('   ');
            }
          }
          buffer.write('|\n');
        }
        
        if (i < newBytes.length) {
          buffer.write('+ ');
          buffer.write('${i.toRadixString(16).padLeft(8, '0')}: ');
          
          for (var j = 0; j < chunkSize; j++) {
            if (i + j < newBytes.length) {
              final byteValue = newBytes[i + j].toRadixString(16).padLeft(2, '0');
              if (i + j < oldBytes.length && oldBytes[i + j] != newBytes[i + j]) {
                buffer.write('[$byteValue] ');
              } else if (i + j >= oldBytes.length) {
                buffer.write('*$byteValue* ');
              } else {
                buffer.write(' $byteValue  ');
              }
            } else {
              buffer.write('     ');
            }
            if (j == 7) buffer.write(' ');
          }
          
          buffer.write(' |');
          for (var j = 0; j < chunkSize; j++) {
            if (i + j < newBytes.length) {
              final char = newBytes[i + j];
              if (char >= 32 && char <= 126) {
                if (i + j < oldBytes.length && oldBytes[i + j] != newBytes[i + j]) {
                  buffer.write('[${String.fromCharCode(char)}]');
                } else if (i + j >= oldBytes.length) {
                  buffer.write('*${String.fromCharCode(char)}*');
                } else {
                  buffer.write(' ${String.fromCharCode(char)} ');
                }
              } else {
                buffer.write(' . ');
              }
            } else {
              buffer.write('   ');
            }
          }
          buffer.write('|\n');
        }

        buffer.write('\n');
      } else {
        sameBlocks++;
      }
    }
    
    buffer.writeln('=== Diff Summary ===');
    buffer.writeln('Total blocks: $totalBlocks');
    buffer.writeln('Different blocks: $diffBlocks');
    buffer.writeln('Identical blocks: $sameBlocks');
    buffer.writeln('Difference percentage: ${(diffBlocks / totalBlocks * 100).toStringAsFixed(2)}%');
    
    return buffer.toString();
  }

  Future<String> compareFilesStreamBased(File currentFile, FileInfo oldInfo) async {
    final buffer = StringBuffer();
    final filePath = currentFile.path;
    final fileSize = await currentFile.length();
    
    if (fileSize > MAX_FILE_SIZE) {
      return 'File too large to diff (${_formatSize(fileSize)}). Maximum size: ${_formatSize(MAX_FILE_SIZE)}.';
    }
    
    buffer.writeln('=== Binary Diff of ${p.basename(filePath)} ===');
    buffer.writeln('Path: ${p.relative(filePath, from: rootPath!)}');
    buffer.writeln('Old size: ${_formatSize(oldInfo.size)}');
    buffer.writeln('New size: ${_formatSize(fileSize)}');
    buffer.writeln('Size difference: ${_formatSizeDifference(fileSize - oldInfo.size)}');
    buffer.writeln('');
    
    if (oldInfo.content == null) {
      buffer.writeln('No content information available for old file. Cannot generate diff.');
      return buffer.toString();
    }
    
    final oldBytes = oldInfo.content!;
    
    final file = File(filePath);
    final fileStream = file.openRead(0, oldBytes.length < fileSize ? oldBytes.length : fileSize);
    
    List<int> newBytes = [];
    await for (var chunk in fileStream) {
      newBytes.addAll(chunk);
    }
    
    if (newBytes.isNotEmpty) {
      final newData = Uint8List.fromList(newBytes);
      
      buffer.writeln('=== Detailed Binary Diff (${_formatSize(newData.length < oldBytes.length ? newData.length : oldBytes.length)}) ===');
      buffer.write(await getHexDiffDump(oldBytes, newData));
    } else {
      buffer.writeln('Failed to read file for comparison.');
    }
    
    return buffer.toString();
  }
  
  Future<Map<String, FileInfo>> _scanDirectory(String directoryPath) async {
    final result = <String, FileInfo>{};
    final dir = Directory(directoryPath);
    final entities = await dir.list(recursive: true).toList();
    
    final normalizedSnapshotsPath = p.normalize(snapshotsPath!);
    final normalizedFlutterAssetsPath = p.normalize(p.join(rootPath!, 'flutter_assets'));
    
    for (final entity in entities) {
      if (entity is File) {
        final normalizedPath = p.normalize(entity.path);
        if (normalizedPath.startsWith(normalizedSnapshotsPath) || 
            normalizedPath.startsWith(normalizedFlutterAssetsPath)) {
          continue;
        }
        
        try {
          final relativePath = p.relative(entity.path, from: rootPath!);
          final stat = await entity.stat();
          
          if (stat.size > MAX_FILE_SIZE) {
            printV('Skipping large file: $relativePath (${_formatSize(stat.size)})');
            continue;
          }
          
          Uint8List? fileContent;
          try {
            fileContent = await entity.readAsBytes();
          } catch (e) {
            printV('Error reading file content: $e');
          }
          
          result[relativePath] = FileInfo(
            path: relativePath,
            size: stat.size,
            modified: stat.modified,
            content: fileContent,
          );
        } catch (e) {
          printV('Error processing file ${entity.path}: $e');
        }
      }
    }
    
    return result;
  }

  @action
  Future<void> loadSnapshots() async {
    try {
      final dir = Directory(snapshotsPath!);
      if (!await dir.exists()) return;
      
      final snapshotFiles = dir.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.snapshot')
      ).toList();
      
      snapshots.clear();
      List<String> corruptedFiles = [];
      
      for (final file in snapshotFiles) {
        try {
          final content = await file.readAsString();
          
          Map<String, dynamic>? jsonData;
          try {
            jsonData = jsonDecode(content) as Map<String, dynamic>;
          } catch (jsonError) {
            corruptedFiles.add(file.path);
            printV('Error parsing snapshot ${file.path}: $jsonError');
            continue;
          }
          
          if (!jsonData.containsKey('files') || 
              !jsonData.containsKey('name') || 
              !jsonData.containsKey('timestamp')) {
            corruptedFiles.add(file.path);
            printV('Invalid snapshot format in ${file.path}');
            continue;
          }
          
          try {
            final fileInfos = Map<String, FileInfo>.from(
              (jsonData['files'] as Map).map((key, value) => MapEntry(
                key as String,
                FileInfo(
                  path: value['path'] as String,
                  size: value['size'] as int,
                  modified: DateTime.parse(value['modified'] as String),
                  content: value['content'] != null ? base64Decode(value['content'] as String) : null,
                ),
              )),
            );
            
            snapshots.add(Snapshot(
              name: jsonData['name'] as String,
              timestamp: DateTime.parse(jsonData['timestamp'] as String),
              files: fileInfos,
            ));
          } catch (e) {
            corruptedFiles.add(file.path);
            printV('Error processing snapshot data ${file.path}: $e');
          }
        } catch (e) {
          corruptedFiles.add(file.path);
          printV('Error loading snapshot ${file.path}: $e');
        }
      }
      
      if (corruptedFiles.isNotEmpty) {
        await _handleCorruptedSnapshots(corruptedFiles);
      }
      
      snapshots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      printV('Error loading snapshots: $e');
    }
  }

  Future<void> _handleCorruptedSnapshots(List<String> corruptedFilePaths) async {
    printV('Found ${corruptedFilePaths.length} corrupted snapshot files:');
    for (final path in corruptedFilePaths) {
      printV('  - ${p.basename(path)}');
      
      try {
        final file = File(path);
        if (await file.exists()) {
          final newPath = '$path.corrupted';
          await file.rename(newPath);
          printV('    Renamed to ${p.basename(newPath)}');
        }
      } catch (e) {
        printV('    Failed to rename corrupted file: $e');
      }
    }
  }

  @action
  Future<void> createSnapshot(String name) async {
    try {
      if (rootPath == null) return;
      
      final timestamp = DateTime.now();
      final files = await _scanDirectory(rootPath!);
      
      final snapshot = Snapshot(
        name: name,
        timestamp: timestamp,
        files: files,
      );
      
      final jsonData = {
        'name': snapshot.name,
        'timestamp': snapshot.timestamp.toIso8601String(),
        'files': snapshot.files.map((path, fileInfo) => MapEntry(
          path,
          {
            'path': fileInfo.path,
            'size': fileInfo.size,
            'modified': fileInfo.modified.toIso8601String(),
            'content': fileInfo.content != null ? base64Encode(fileInfo.content!) : null,
          },
        )),
      };
      
      final snapshotFilePath = p.join(
        snapshotsPath!,
        '${name.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${timestamp.millisecondsSinceEpoch}.snapshot',
      );
      
      final file = File(snapshotFilePath);
      await file.writeAsString(jsonEncode(jsonData));
      
      await loadSnapshots();
    } catch (e) {
      printV('Error creating snapshot: $e');
    }
  }

  @action
  Future<void> compareSnapshot() async {
    if (comparisonSnapshot == null || rootPath == null) return;
    
    try {
      fileChanges.clear();
      
      final currentFiles = await _scanDirectory(rootPath!);
      
      final snapshot = comparisonSnapshot!;
      
      for (final entry in currentFiles.entries) {
        final path = entry.key;
        final current = entry.value;
        
        if (!snapshot.files.containsKey(path)) {
          fileChanges.add(FileChange(
            path: path,
            type: ChangeType.added,
            newFile: current,
          ));
        } else {
          final old = snapshot.files[path]!;
          
          if (old.modified != current.modified) {
            fileChanges.add(FileChange(
              path: path,
              type: ChangeType.touched,
              oldFile: old,
              newFile: current,
            ));
          } else if (old.size != current.size ||
            !_areContentsEqual(old.content, current.content)) {
            fileChanges.add(FileChange(
              path: path,
              type: ChangeType.modified,
              oldFile: old,
              newFile: current,
            ));
          }
        }
      }
      
      for (final path in snapshot.files.keys) {
        if (!currentFiles.containsKey(path)) {
          fileChanges.add(FileChange(
            path: path,
            type: ChangeType.removed,
            oldFile: snapshot.files[path],
          ));
        }
      }
      
      fileChanges.sort((a, b) => a.path.compareTo(b.path));
    } catch (e) {
      printV('Error comparing snapshot: $e');
    }
  }

  @action
  Future<void> deleteSnapshot(Snapshot snapshot) async {
    try {
      final snapshotFile = File(p.join(
        snapshotsPath!,
        '${snapshot.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${snapshot.timestamp.millisecondsSinceEpoch}.snapshot',
      ));
      
      if (await snapshotFile.exists()) {
        await snapshotFile.delete();
      }
      
      await loadSnapshots();
    } catch (e) {
      printV('Error deleting snapshot: $e');
    }
  }

  Future<String> getFileDiff(FileChange fileChange) async {
    if (fileChange.type == ChangeType.added) {
      final filePath = p.join(rootPath!, fileChange.path);
      final file = File(filePath);
      final fileSize = await file.length();
      
      if (fileSize > MAX_FILE_SIZE) {
        return 'File too large to display (${_formatSize(fileSize)}). Maximum size: ${_formatSize(MAX_FILE_SIZE)}.';
      }
       
      final buffer = StringBuffer();
      buffer.writeln('=== File Added ===');
      buffer.writeln('Path: ${fileChange.path}');
      buffer.writeln('Size: ${_formatSize(fileChange.newFile!.size)}');
      buffer.writeln('Modified: ${fileChange.newFile!.modified}');
      buffer.writeln('');
       
      if (fileChange.newFile!.content != null) {
        buffer.writeln('=== Hex Dump (Added File) ===');
        final bytes = fileChange.newFile!.content!;
        final hexDump = _formatHexDump(bytes, false);
        
        final hexDumpLines = hexDump.split('\n');
        for (final line in hexDumpLines) {
          if (line.isNotEmpty) {
            buffer.writeln('+ $line');
          }
        }
      }
      
      return buffer.toString();
    } else if (fileChange.type == ChangeType.removed) {
      final buffer = StringBuffer();
      buffer.writeln('=== File Removed ===');
      buffer.writeln('Path: ${fileChange.path}');
      buffer.writeln('Size: ${_formatSize(fileChange.oldFile!.size)}');
      buffer.writeln('Modified: ${fileChange.oldFile!.modified}');
      buffer.writeln('');
       
      if (fileChange.oldFile!.content != null) {
        buffer.writeln('=== Hex Dump (Removed File) ===');
        final bytes = fileChange.oldFile!.content!;
        final hexDump = _formatHexDump(bytes, false);
        
        final hexDumpLines = hexDump.split('\n');
        for (final line in hexDumpLines) {
          if (line.isNotEmpty) {
            buffer.writeln('- $line');
          }
        }
      }
      
      return buffer.toString();
    } else if (fileChange.type == ChangeType.modified) {
      final filePath = p.join(rootPath!, fileChange.path);
      final currentFile = File(filePath);
      final fileSize = await currentFile.length();
        
      if (fileSize > MAX_FILE_SIZE) {
        return 'File too large to diff (${_formatSize(fileSize)}). Maximum size: ${_formatSize(MAX_FILE_SIZE)}.';
      }
        
      final buffer = StringBuffer();
      buffer.writeln('=== File Modified ===');
      buffer.writeln('Path: ${fileChange.path}');
      buffer.writeln('');
        
      buffer.writeln('=== Size ===');
      buffer.writeln('Old: ${_formatSize(fileChange.oldFile!.size)}');
      buffer.writeln('New: ${_formatSize(fileChange.newFile!.size)}');
      buffer.writeln('Difference: ${_formatSizeDifference(fileChange.newFile!.size - fileChange.oldFile!.size)}');
      buffer.writeln('');
        
      buffer.writeln('=== Timestamps ===');
      buffer.writeln('Old modified: ${fileChange.oldFile!.modified}');
      buffer.writeln('New modified: ${fileChange.newFile!.modified}');
      buffer.writeln('');
       
      if (fileChange.oldFile!.content != null && fileChange.newFile!.content != null) {
        buffer.writeln('=== Binary Diff ===');
        final diff = await getHexDiffDump(fileChange.oldFile!.content!, fileChange.newFile!.content!);
        buffer.write(diff);
      } else {
        buffer.writeln('Cannot create binary diff: missing content data.');
      }
        
      return buffer.toString();
    }
      
    return 'No detailed information available.';
  }

  String _formatHexDump(Uint8List bytes, bool truncated) {
    final buffer = StringBuffer();
    
    for (var i = 0; i < bytes.length; i += 16) {
      // Address
      buffer.write('${i.toRadixString(16).padLeft(8, '0')}: ');
      
      // Hex values
      for (var j = 0; j < 16; j++) {
        if (i + j < bytes.length) {
          buffer.write('${bytes[i + j].toRadixString(16).padLeft(2, '0')} ');
        } else {
          buffer.write('   ');
        }
        if (j == 7) buffer.write(' ');
      }
      
      // ASCII representation
      buffer.write(' |');
      for (var j = 0; j < 16; j++) {
        if (i + j < bytes.length) {
          final char = bytes[i + j];
          if (char >= 32 && char <= 126) {
            buffer.write(String.fromCharCode(char));
          } else {
            buffer.write('.');
          }
        } else {
          buffer.write(' ');
        }
      }
      buffer.write('|\n');
    }
    
    if (truncated) {
      buffer.write('\n... (file continues) ...');
    }
    
    return buffer.toString();
  }
  
  Future<String> getTextDiff(String oldText, String newText) async {
    final oldLines = oldText.split('\n');
    final newLines = newText.split('\n');
    
    final buffer = StringBuffer();
    
    // Very simple diff algorithm - can be improved with a proper diff algorithm
    final maxLines = oldLines.length > newLines.length ? oldLines.length : newLines.length;
    
    for (var i = 0; i < maxLines; i++) {
      if (i < oldLines.length && i < newLines.length) {
        if (oldLines[i] == newLines[i]) {
          buffer.writeln('  ${newLines[i]}');
        } else {
          buffer.writeln('- ${oldLines[i]}');
          buffer.writeln('+ ${newLines[i]}');
        }
      } else if (i < oldLines.length) {
        buffer.writeln('- ${oldLines[i]}');
      } else if (i < newLines.length) {
        buffer.writeln('+ ${newLines[i]}');
      }
    }
    
    return buffer.toString();
  }
  
  String _formatSize(int sizeInBytes) {
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
  
  String _formatSizeDifference(int diffInBytes) {
    final prefix = diffInBytes >= 0 ? '+' : '';
    return '$prefix${_formatSize(diffInBytes.abs())}';
  }

  bool _areContentsEqual(Uint8List? a, Uint8List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }

  @action
  Future<bool> renameFile(String oldPath, String newPath) async {
    try {
      final oldFile = File(oldPath);
      final newFile = File(newPath);
      printV('Renaming file: $oldPath to $newPath');
      if (await newFile.exists()) {
        return false;
      }
      
      await oldFile.rename(newFile.path);
      printV('Renamed file: $oldPath to $newPath');
      return true;
    } catch (e) {
      printV('Error renaming file: $e');
      return false;
    }
  }

  @action
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      await file.delete();
      return true;
    } catch (e) {
      printV('Error deleting file: $e');
      return false;
    }
  }

  @action
  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = File(destinationPath);
      
      if (await destinationFile.exists()) {
        return false;
      }
      
      await sourceFile.copy(destinationFile.path);
      return true;
    } catch (e) {
      printV('Error copying file: $e');
      return false;
    }
  }

  static Future<void> startMonitoring() async {
    if (_watcher != null) {
      return;
    }
    
    isMonitoringActive = true;
    final appDir = await getAppDir();
    if (Platform.isAndroid) {
      _watcher = DirectoryWatcher(appDir.parent.path); // get rid of weird app_flutter directory
    } else {
      _watcher = DirectoryWatcher(appDir.path);
    }
    
    _watcher!.events.listen((event) {
      if (event.path.contains('flutter_engine')) {
        return;
      }
      final relativePath = event.path.replaceFirst(appDir.path, '~');
      fileEvents.add(FileEvent(
        timestamp: DateTime.now(),
        event: event,
        relativePath: relativePath,
      ));
    });
  }

  static void stopMonitoring() {
    if (_watcher != null) {
      _watcher!.events.drain();
      _watcher = null;
      isMonitoringActive = false;
    }
  }

  @action
  void clearEvents() {
    fileEvents.clear();
  }

  static Future<bool> checkDevMonitorFileExists() async {
    final appDir = await getAppDir();
    final devMonitorFile = File('${appDir.path}/.dev-monitor-fs');
    return devMonitorFile.exists();
  }
}