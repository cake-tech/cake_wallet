import "dart:async";
import "dart:convert";

import "package:flutter_driver/flutter_driver.dart";
import "package:integration_test/integration_test_driver_extended.dart";
import "package:path/path.dart" as path;

Future<void> main() async {
  await runZoned(
    _drive,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (!line.startsWith("result {")) {
          parent.print(zone, line);
        }
      },
    ),
  );
}

Future<void> _drive() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await fs.directory(_screenshotDirectory).create(recursive: true);
      await fs.file(path.join(_screenshotDirectory, "$name.png")).writeAsBytes(bytes);

      return true;
    },
    responseDataCallback: (data) async {
      data?.remove("screenshots");

      await fs.directory(_destinationDirectory).create(recursive: true);

      final file = fs.file(
        path.join(
          _destinationDirectory,
          "$_testOutputFilename.json",
        ),
      );

      final resultString = _encodeJson(data);
      await file.writeAsString(resultString);
    },
    writeResponseOnFailure: true,
  );
}

String _encodeJson(Map<String, dynamic>? jsonObject) {
  return _prettyEncoder.convert(jsonObject);
}

const _prettyEncoder = JsonEncoder.withIndent("  ");
const _testOutputFilename = "integration_response_data";
const _destinationDirectory = "build/integration_test";
const _screenshotDirectory = "build/integration_test_screenshots";
