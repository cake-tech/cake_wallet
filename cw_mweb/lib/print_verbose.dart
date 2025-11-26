import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum LogLevel { info, debug, warn, error }

/// Pass an optional [file] to also write the log to a file.
void printV(
  dynamic content, {
  String? file,
  LogLevel level = LogLevel.info,
}) {
  final programInfo = CustomTrace(StackTrace.current);
  final logLine =
      "[${level.name.toUpperCase()}] ${programInfo.fileName}#${programInfo.lineNumber}:${programInfo.columnNumber} ${programInfo.callerFunctionName}: $content";

  print(logLine);

  if (file != null) {
    final logFile = File(file);
    if (!logFile.existsSync()) {
      logFile.createSync(recursive: true);
    }
    logFile.writeAsStringSync("$logLine\n", mode: FileMode.append, flush: true);
  }
}

// https://stackoverflow.com/a/59386101

class CustomTrace {
  final StackTrace _trace;

  String? fileName;
  String? functionName;
  String? callerFunctionName;
  int? lineNumber;
  int? columnNumber;

  CustomTrace(this._trace) {
    try {
      _parseTrace();
    } catch (e) {
      if (kDebugMode) print("Unable to parse trace (printV): $e");
    }
  }

  String _getFunctionNameFromFrame(String frame) {
    /* Just giving another nickname to the frame */
    var currentTrace = frame;
    /* To get rid off the #number thing, get the index of the first whitespace */
    var indexOfWhiteSpace = currentTrace.indexOf(' ');

    /* Create a substring from the first whitespace index till the end of the string */
    var subStr = currentTrace.substring(max(0, indexOfWhiteSpace));

    /* Grab the function name using reg expr */
    var indexOfFunction = subStr.indexOf(RegExp(r'[A-Za-z0-9_]'));

    /* Create a new substring from the function name index till the end of string */
    subStr = subStr.substring(indexOfFunction);

    indexOfWhiteSpace = subStr.indexOf(RegExp(r'[ .]'));

    /* Create a new substring from start to the first index of a whitespace. This substring gives us the function name */
    subStr = subStr.substring(0, max(0, indexOfWhiteSpace));

    return subStr;
  }

  void _parseTrace() {
    /* The trace comes with multiple lines of strings, (each line is also known as a frame), so split the trace's string by lines to get all the frames */
    var frames = this._trace.toString().split("\n");

    /* The first frame is the current function */
    this.functionName = _getFunctionNameFromFrame(frames[0]);

    /* The second frame is the caller function */
    this.callerFunctionName = _getFunctionNameFromFrame(frames[1]);

    /* The first frame has all the information we need */
    var traceString = frames[1];

    /* Search through the string and find the index of the file name by looking for the '.dart' regex */
    var indexOfFileName = traceString.indexOf(
        RegExp(r'[/A-Za-z_]+.dart'), 1); // 1 to offest and not print the printV function name

    var fileInfo = traceString.substring(max(0, indexOfFileName));

    var listOfInfos = fileInfo.split(":");

    /* Splitting fileInfo by the character ":" separates the file name, the line number and the column counter nicely.
      Example: main.dart:5:12
      To get the file name, we split with ":" and get the first index
      To get the line number, we would have to get the second index
      To get the column number, we would have to get the third index
    */
    try {
      this.fileName = listOfInfos[0];
      this.lineNumber = int.tryParse(listOfInfos[1]);
      var columnStr = listOfInfos[2];
      columnStr = columnStr.replaceFirst(")", "");
      this.columnNumber = int.tryParse(columnStr);
    } catch (e) {
      if (kDebugMode) print("Unable to parse trace (printV): $e");
    }
  }
}
