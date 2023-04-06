import 'package:hive/hive.dart';

part 'release_notes_info.g.dart';

@HiveType(typeId: ReleaseNotesInfo.typeId)
class ReleaseNotesInfo extends HiveObject {
  ReleaseNotesInfo({
    required this.lastSeenAppVersion});

  static const typeId = 11;
  static const boxName = 'ReleaseNotes';
  static const boxKey = 'ReleaseNotesBoxKey';

  @HiveField(0)
  String lastSeenAppVersion;

}